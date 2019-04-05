#include <cstring>
#include <iostream>
#include <map>
#include <string>
#include <vector>

#include <netcdf.h>

#include <arbor/cable_cell.hpp>
#include <arbor/recipe.hpp>
#include <arbor/sampling.hpp>
#include <arbor/simple_sampler.hpp>
#include <arbor/simulation.hpp>

#include "common_args.h"
#include "netcdf_wrap.h"

using namespace arb;

paramset default_parameters = {
    {"dt", 0.01},
    {"g0", 0.1}
};

struct rc_expsyn_recipe: public arb::recipe {
    static constexpr double pi = 3.141592653589793238462643383279502884;

    // Fixed parameters:

    static constexpr double r = 9e-6;        // soma radius [m]
    static constexpr double area = 4*pi*r*r; // soma surface area [m²]
    static constexpr double rm = 100;        // total membrane resistance [MΩ]
    static constexpr double cm = 0.01;       // total membrane capacitance [nF]
    static constexpr double erev = -65;      // reversal potential [mV]
    static constexpr double syntau = 1.0;    // synapse exponential time constant [ms]

    // Customizable parameters:
    double g0;                               // synaptic conductance at time 0 [µS]

    static segment_location soma_centre() {
        return segment_location(0u, 0.5);
    }

    explicit rc_expsyn_recipe(const paramset& ps): g0(ps.at("g0")) {}

    cell_size_type num_cells() const override { return 1; }
    cell_size_type num_targets(cell_gid_type) const override { return 1; }
    cell_size_type num_probes(cell_gid_type) const override { return 1; }
    cell_kind get_cell_kind(cell_gid_type) const override { return cell_kind::cable; }

    util::any get_global_properties(cell_kind kind) const override {
        if (kind!=cell_kind::cable) return util::any{};

        cable_cell_global_properties props;
        props.init_membrane_potential_mV = erev;
        return props;
    }

    probe_info get_probe(cell_member_type id) const override {
        return probe_info{id, 0, cell_probe_address{soma_centre(), cell_probe_address::membrane_voltage}};
    }

    std::vector<event_generator> event_generators(cell_gid_type) const override {
        spike_event ev;
        ev.target = {0u, 0u};
        ev.time = 0;
        ev.weight = g0;

        return {explicit_generator(pse_vector{{ev}})};
    }

    util::unique_any get_cell_description(cell_gid_type) const override {
        cable_cell c;

        mechanism_desc pas("pas");
        pas["g"] = 1e-10/(rm*area);    // [S/cm^2]
        pas["e"] = erev;

        auto soma = c.add_soma(r*1e6);
        soma->cm = cm*1e-9/area;       // [F/m^2]
        soma->add_mechanism(pas);

        mechanism_desc expsyn("expsyn");
        expsyn["tau"] = syntau;
        expsyn["e"] = 0;
        c.add_synapse(soma_centre(), expsyn);

        return c;
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
    rc_expsyn_recipe rec(A.params);
    simulation sim(rec, trivial_dd(rec), ctx);

    time_type t_end = 10., sample_dt = 0.05; // [ms]
    time_type dt = A.params["dt"];

    trace_data<double> vtrace;
    sim.add_sampler(all_probes, regular_schedule(sample_dt), make_simple_sampler(vtrace));

    if (A.tags.count("binevents")) {
        sim.set_binning_policy(arb::binning_kind::regular, dt);
    }
    sim.run(t_end, dt);

    // Write to netcdf:

    std::size_t vlen = vtrace.size();

    int ncid;
    nc_check(nc_create, A.output.c_str(), 0, &ncid);

    int time_dimid, timeid, varid;
    nc_check(nc_def_dim, ncid, "time", vlen, &time_dimid);
    nc_check(nc_def_var, ncid, "time", NC_DOUBLE, 1, &time_dimid, &timeid);
    nc_check(nc_def_var, ncid, "voltage", NC_DOUBLE, 1, &time_dimid, &varid);

    std::vector<int> param_ids;
    for (const auto& kv: A.params) {
        int id;
        nc_check(nc_def_var, ncid, kv.first.c_str(), NC_DOUBLE, 0, nullptr, &id);
        param_ids.push_back(id);
    }

    nc_check(nc_enddef, ncid);

    std::vector<double> times, values;
    times.reserve(vlen);
    values.reserve(vlen);
    for (auto e: vtrace) {
        times.push_back(e.t);
        values.push_back(e.v);
    }

    unsigned pidx = 0;
    for (const auto& kv: A.params) {
        int id;
        nc_check(nc_put_var_double, ncid, param_ids[pidx++], &kv.second);
    }

    nc_check(nc_put_var_double, ncid, timeid, times.data())
    nc_check(nc_put_var_double, ncid, varid, values.data())
    nc_check(nc_close, ncid);
}
