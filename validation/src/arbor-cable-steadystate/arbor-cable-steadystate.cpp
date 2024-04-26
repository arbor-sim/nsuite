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
#include <arbor/util/any_cast.hpp>
#include <arbor/util/any_ptr.hpp>

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
    cell_kind get_cell_kind(cell_gid_type) const override { return cell_kind::cable; }
    cell_size_type num_cvs_per_branch(cell_gid_type) const { return n; }
    std::vector<arb::probe_info> get_probes(cell_gid_type gid) const override {
        std::vector<arb::probe_info> probes;

        // n probes, centred over CVs.
        for (unsigned i = 0; i < num_probes(gid); ++i) {
          arb::mlocation loc{0, probe_x(i)/length};
          probes.push_back(cable_probe_membrane_voltage{loc});
        }
        return probes;
    }

    std::any get_global_properties(cell_kind kind) const override {
        cable_cell_global_properties prop;

        prop.default_parameters.init_membrane_potential = 0;
        prop.default_parameters.axial_resistivity = 100*rl; // [Ω·cm]
        prop.default_parameters.membrane_capacitance = (double)cm;  // [F/m²]
        prop.default_parameters.temperature_K = 300;
        prop.ion_species.clear();
        return prop;
    }


    util::unique_any get_cell_description(cell_gid_type) const override {
        segment_tree tree;
        tree.append(arb::mnpos, {0., 0., 0., d0/2}, {0., 0., length, d1/2}, 0);

        mechanism_desc pas("pas/e=0");
        pas["g"] = 1e-4/rm; // [S/cm^2]
        // pas["e"] = 0; // erev=0

        decor D;
        D.paint(reg::all(), arb::density{pas});
        D.place(mlocation{0, 1.}, i_clamp{iinj}, "ic");
        D.set_default(cv_policy_fixed_per_branch(n));

        return cable_cell(tree, D);
    }

    // time constant in [ms]
    static double tau() { return rm*cm*1000; }

    // probe position in [µm]
    double probe_x(unsigned i) const { return length*((2.0*i+1.0)/(2.0*n)); }
    cell_size_type num_probes(cell_gid_type) const { return n; }
};

int main(int argc, char** argv) {
    common_args A;
    A.params = default_parameters;
    parse_common_args(A, argc, argv, {"binevents"});

    rc_cable_recipe rec(A.params);
    simulation sim(rec);

    time_type dt = A.params["dt"];
    time_type t_end = 20*rec.tau(); // transient amplitudes are proportional to exp(-t/tau).

    auto n_entities = rec.num_cvs_per_branch(0);
    std::vector<double> voltage(n_entities);
    std::vector<double> x(n_entities);
    for (unsigned i = 0; i<x.size(); ++i) x[i] = rec.probe_x(i);

    double t_sample = 0;
    auto sampler = [&voltage,&t_sample] (probe_metadata pm, std::size_t n, const sample_record* rec) {
        voltage.at(pm.id.index) = *rec[0].data.as<const double*>();
        t_sample = rec[0].time;
    };
    sim.add_sampler(all_probes, explicit_schedule({t_end-dt}), sampler);

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
