#include <cstdio>
#include <cstring>
#include <map>
#include <string>
#include <vector>

#include <iostream>

#include <netcdf.h>

#include <arbor/cable_cell.hpp>
#include <arbor/recipe.hpp>
#include <arbor/sampling.hpp>
#include <arbor/simple_sampler.hpp>
#include <arbor/simulation.hpp>
#include <arbor/version.hpp>

#include "common_args.h"
#include "common_attr.h"
#include "netcdf_wrap.h"

using namespace arb;

paramset default_parameters = {
    {"dt", 0.0025},    // timestep [ms]
    {"d0", 1.0},       // diameter at left end [µm]
    {"d1", 1.5},       // diameter at right end [µm]
    {"n",  1000}       // number of CVs
};

struct rc_cable_recipe: public arb::recipe {
    // Fixed parameters:

    static constexpr double length = 1000.0; // cable length [µm]
    static constexpr double rl = 1.0;        // bulk resistivity [Ωm]
    static constexpr double rm = 4.0;        // membrane resistivity [Ωm²]
    static constexpr double cm = 0.01;       // membrane specific capacitance [F/m²]
    static constexpr double iinj = 0.1;      // current injection at right end [nA]

    // Customizable parameters:
    unsigned n = 0;                          // number of CV
    double d0 = 0, d1 = 0;                   // diameters

    explicit rc_cable_recipe(const paramset& ps):
        d0(ps.at("d0")),
        d1(ps.at("d1")),
        n(static_cast<unsigned>(ps.at("n")))
    {}

    cell_size_type num_cells() const override { return 1; }
    cell_size_type num_targets(cell_gid_type) const override { return 0; }
    cell_size_type num_probes(cell_gid_type) const override { return n; }
    cell_kind get_cell_kind(cell_gid_type) const override { return cell_kind::cable; }

    util::any get_global_properties(cell_kind kind) const override {
        cable_cell_global_properties prop;

        prop.default_parameters.init_membrane_potential = 0;
        prop.default_parameters.axial_resistivity = 100*rl; // [Ω·cm]
        prop.default_parameters.membrane_capacitance = (double)cm;  // [F/m²]
        prop.default_parameters.temperature_K = 0;
        prop.ion_species.clear();
        return prop;
    }

    probe_info get_probe(cell_member_type id) const override {
        // n probes, centred over CVs.
        double pos = probe_x(id.index)/length;
        return probe_info{id, 0, cell_probe_address{{0, pos}, cell_probe_address::membrane_voltage}};
    }

    util::unique_any get_cell_description(cell_gid_type) const override {
        sample_tree samples({msample{{0., 0., 0., d0/2}, 0}, msample{{0., 0., length, d1/2}, 0}}, {mnpos, 0u});

        cable_cell c(samples);
        c.default_parameters.discretization = cv_policy_fixed_per_branch(n);

        mechanism_desc pas("pas");
        pas["g"] = 1e-4/rm; // [S/cm^2]
        pas["e"] = 0; // erev=0

        c.paint(reg::all(), pas);
        c.place(mlocation{0, 1.}, i_clamp{0, INFINITY, iinj});
        return c;
    }

    // time constant in [ms]
    static double tau() { return rm*cm*1000; }

    // probe position in [µm]
    double probe_x(unsigned i) const {
        return length*((2.0*i+1.0)/(2.0*n));
    }
};

domain_decomposition trivial_dd(const recipe& r) {
    cell_size_type ncell = r.num_cells();

    std::vector<cell_gid_type> all_gids(ncell);
    std::iota(all_gids.begin(), all_gids.end(), cell_gid_type(0));

    return domain_decomposition{
        [](cell_gid_type) { return 0; },   // gid_domain map
        1,                                 // num_domains
        0,                                 // domain_id
        ncell,                             // num_local_cells
        ncell,                             // num_global_cells
        {{r.get_cell_kind(0), all_gids, backend_kind::multicore}}  // groups
    };
}

int main(int argc, char** argv) {
    common_args A;
    A.params = default_parameters;
    parse_common_args(A, argc, argv, {"binevents"});

    auto ctx = make_context();
    rc_cable_recipe rec(A.params);
    simulation sim(rec, trivial_dd(rec), ctx);

    time_type dt = A.params["dt"];
    time_type t_end = 20*rec.tau(); // transient amplitudes are proportional to exp(-t/tau).

    std::vector<double> voltage(rec.num_probes(0));
    std::vector<double> x(rec.num_probes(0));
    for (unsigned i = 0; i<x.size(); ++i) x[i] = rec.probe_x(i);

    double t_sample = 0;
    sim.add_sampler(all_probes, explicit_schedule({t_end-dt}),
        [&voltage,&t_sample](cell_member_type probe_id, probe_tag, std::size_t n, const sample_record* rec) {
            std::cout << "probe_id: " << probe_id.gid << ", " << probe_id.index << std::endl;
            voltage.at(probe_id.index) = *rec[0].data.as<const double*>();
            t_sample = rec[0].time;
        });

    sim.run(t_end, dt);

    // Write to netcdf:

    std::size_t vlen = voltage.size();

    int ncid;
    nc_check(nc_create, A.output.c_str(), 0, &ncid);

    int x_dimid, xid, vid, tid;
    nc_check(nc_def_dim, ncid, "x", vlen, &x_dimid);
    nc_check(nc_def_var, ncid, "x", NC_DOUBLE, 1, &x_dimid, &xid);
    nc_check(nc_def_var, ncid, "v", NC_DOUBLE, 1, &x_dimid, &vid);
    nc_check(nc_def_var, ncid, "t_sample", NC_DOUBLE, 0, nullptr, &tid);

    auto nc_put_att_cstr = [](int ncid, int varid, const char* name, const char* value) {
        nc_check(nc_put_att_text, ncid, varid, name, std::strlen(value), value);
    };

    nc_put_att_cstr(ncid, xid, "units", "µm");
    nc_put_att_cstr(ncid, vid, "units", "mV");
    nc_put_att_cstr(ncid, tid, "units", "ms");

    common_attr attrs;
    attrs.model = "cable-steadystate";
    attrs.simulator = "arbor";
    attrs.simulator_build = arb::version;
    attrs.simulator_build += ' ';
    attrs.simulator_build += arb::source_id;

    set_common_attr(ncid, attrs, A.tags, A.params);
    nc_check(nc_enddef, ncid);

    nc_check(nc_put_var_double, ncid, tid, &t_sample)
    nc_check(nc_put_var_double, ncid, vid, voltage.data())
    nc_check(nc_put_var_double, ncid, xid, x.data())
    nc_check(nc_close, ncid);
}
