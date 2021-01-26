#include <cstdio>
#include <cstring>
#include <map>
#include <string>
#include <vector>

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
    {"dt", 0.0025},
    {"tend", 250.0},
    {"x0", 0.0},
    {"x1", 1.0},
    {"n",  1000}
};

struct rc_rallpack1_recipe: public arb::recipe {
    // Fixed parameters:

    static constexpr double d = 1.0;         // cable diameter [µm]
    static constexpr double length = 1000.0; // cable length [µm]
    static constexpr double rl = 1.0;        // bulk resistivity [Ωm]
    static constexpr double rm = 4.0;        // membrane resistivity [Ωm²]
    static constexpr double cm = 0.01;       // membrane specific capacitance [F/m²]
    static constexpr double erev = -65;      // reversal potential [mV]
    static constexpr double iinj = 0.1;      // current injection [nA]

    // Customizable parameters:
    unsigned n = 0;                          // number of CV
    double x0 = 0, x1 = 0;                   // (proportional) sample locations

    explicit rc_rallpack1_recipe(const paramset& ps):
        x0(ps.at("x0")),
        x1(ps.at("x1")),
        n(static_cast<unsigned>(ps.at("n")))
    {}

    cell_size_type num_cells() const override { return 1; }
    cell_size_type num_targets(cell_gid_type) const override { return 0; }
    cell_kind get_cell_kind(cell_gid_type) const override { return cell_kind::cable; }
    cell_size_type num_probes(cell_gid_type) const { return 2; }

    std::any get_global_properties(cell_kind kind) const override {
        cable_cell_global_properties prop;

        prop.default_parameters.init_membrane_potential = (double)erev;
        prop.default_parameters.axial_resistivity = 100*rl; // [Ω·cm]
        prop.default_parameters.membrane_capacitance = (double)cm;  // [F/m²]
        prop.default_parameters.temperature_K = 0;
        prop.ion_species.clear();
        return prop;
    }

    std::vector<arb::probe_info> get_probes(cell_gid_type gid) const override {
        std::vector<arb::probe_info> probes; 

        // n probes, centred over CVs.
        for (unsigned i = 0; i < num_probes(gid); ++i) {
          arb::mlocation loc{0, i==0? x0: x1};
          probes.push_back(cable_probe_membrane_voltage{loc});
        }
        return probes; 
    }

    util::unique_any get_cell_description(cell_gid_type) const override {
        segment_tree tree;
        tree.append(arb::mnpos, {0., 0., 0., d/2}, {0., 0., length, d/2}, 0);

        mechanism_desc pas("pas");
        pas["g"] = 1e-4/rm; // [S/cm^2]
        pas["e"] = (double)erev;

        decor D;
        D.paint(reg::all(), pas);
        D.place(mlocation{0, 0}, i_clamp{0, INFINITY, iinj});
        D.set_default(cv_policy_fixed_per_branch(n));

        return cable_cell(tree, {}, D);
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
    rc_rallpack1_recipe rec(A.params);
    simulation sim(rec, trivial_dd(rec), ctx);

    time_type dt = A.params["dt"];
    time_type t_end = A.params["tend"];
    time_type sample_dt = dt>0.01? dt: 0.01; // [ms]

    trace_vector<double> vtrace0, vtrace1;
    sim.add_sampler(one_probe({0, 0}), regular_schedule(sample_dt), make_simple_sampler(vtrace0), sampling_policy::exact);
    sim.add_sampler(one_probe({0, 1}), regular_schedule(sample_dt), make_simple_sampler(vtrace1), sampling_policy::exact);

    sim.run(t_end, dt);

    // Split sample times from voltages; assert times align for both traces.

    std::vector<double> times, v0, v1;

    if (vtrace0.at(0).size()!=vtrace1.at(0).size()) {
        fputs("sample time mismatch", stderr);
        return 1;
    }

    for (std::size_t i = 0; i<vtrace0.size(); ++i) {
        if (vtrace0.at(0)[i].t!=vtrace1.at(0)[i].t) {
            fputs("sample time mismatch", stderr);
            return 1;
        }

        if (i>0 && vtrace0.at(0)[i].t==vtrace0.at(0)[i-1].t) {
            // Multiple sample in same integration timestep; discard.
            continue;
        }

        times.push_back(vtrace0[i].at(0).t);
        v0.push_back(vtrace0[i].at(0).v);
        v1.push_back(vtrace1[i].at(0).v);
    }

    // Write to netcdf:

    std::size_t vlen = times.size();

    int ncid;
    nc_check(nc_create, A.output.c_str(), 0, &ncid);

    int time_dimid, timeid, v0id, v1id;
    nc_check(nc_def_dim, ncid, "time", vlen, &time_dimid);
    nc_check(nc_def_var, ncid, "time", NC_DOUBLE, 1, &time_dimid, &timeid);
    nc_check(nc_def_var, ncid, "v0", NC_DOUBLE, 1, &time_dimid, &v0id);
    nc_check(nc_def_var, ncid, "v1", NC_DOUBLE, 1, &time_dimid, &v1id);

    auto nc_put_att_cstr = [](int ncid, int varid, const char* name, const char* value) {
        nc_check(nc_put_att_text, ncid, varid, name, std::strlen(value), value);
    };

    nc_put_att_cstr(ncid, timeid, "units", "ms");
    nc_put_att_cstr(ncid, v0id, "units", "mV");
    nc_put_att_cstr(ncid, v1id, "units", "mV");

    common_attr attrs;
    attrs.model = "rallpack1";
    attrs.simulator = "arbor";
    attrs.simulator_build = arb::version;
    attrs.simulator_build += ' ';
    attrs.simulator_build += arb::source_id;

    set_common_attr(ncid, attrs, A.tags, A.params);
    nc_check(nc_enddef, ncid);

    nc_check(nc_put_var_double, ncid, timeid, times.data())
    nc_check(nc_put_var_double, ncid, v0id, v0.data())
    nc_check(nc_put_var_double, ncid, v1id, v1.data())
    nc_check(nc_close, ncid);
}
