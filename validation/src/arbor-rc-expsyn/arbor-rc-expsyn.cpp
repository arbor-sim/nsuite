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
#include <arbor/version.hpp>

#include "common_args.h"
#include "common_attr.h"
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

    static mlocation soma_centre() {
        return mlocation{0u, 0.5};
    }

    explicit rc_expsyn_recipe(const paramset& ps): g0(ps.at("g0")) {}

    cell_size_type num_cells() const override { return 1; }
    cell_size_type num_targets(cell_gid_type) const override { return 1; }
    cell_kind get_cell_kind(cell_gid_type) const override { return cell_kind::cable; }
    cell_size_type num_probes(cell_gid_type) const { return 1; }

    std::any get_global_properties(cell_kind kind) const override {
        arb::cable_cell_global_properties prop;
        prop.default_parameters.init_membrane_potential = erev;
        prop.ion_species.clear();

        // Relevant parameters will be set on the cell itself.
        prop.default_parameters.axial_resistivity = 0;
        prop.default_parameters.membrane_capacitance = 0;
        prop.default_parameters.temperature_K = 0;
        return prop;
    }

    std::vector<arb::probe_info> get_probes(cell_gid_type gid) const override {
        return {cable_probe_membrane_voltage{soma_centre()}};
    }

    std::vector<event_generator> event_generators(cell_gid_type) const override {
        spike_event ev;
        ev.target = {0u, 0u};
        ev.time = 0;
        ev.weight = g0;

        return {explicit_generator(pse_vector{{ev}})};
    }

    util::unique_any get_cell_description(cell_gid_type) const override {
        segment_tree tree;
        tree.append(arb::mnpos, {0., 0., 0., r*1e6}, {0., 0., 2*r*1e6,  r*1e6}, 1);

        mechanism_desc pas("pas");
        pas["g"] = 1e-10/(rm*area);    // [S/cm^2]
        pas["e"] = erev;

        mechanism_desc expsyn("expsyn");
        expsyn["tau"] = syntau;
        expsyn["e"] = 0;

        label_dict labels;
        labels.set("soma", reg::tagged(1));
        labels.set("centre", soma_centre());

        cable_cell c(morphology(tree), labels);
        c.default_parameters.membrane_capacitance = cm*1e-9/area; // [F/m^2]

        c.paint("\"soma\"", pas);
        c.place("\"centre\"", expsyn);

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

    trace_vector<double> vtrace;
    sim.add_sampler(all_probes, regular_schedule(sample_dt), make_simple_sampler(vtrace), sampling_policy::exact);

    if (A.tags.count("binevents")) {
        sim.set_binning_policy(arb::binning_kind::regular, dt);
    }
    sim.run(t_end, dt);

    // Write to netcdf:

    std::size_t vlen = vtrace.at(0).size();

    int ncid;
    nc_check(nc_create, A.output.c_str(), 0, &ncid);

    int time_dimid, timeid, varid;
    nc_check(nc_def_dim, ncid, "time", vlen, &time_dimid);
    nc_check(nc_def_var, ncid, "time", NC_DOUBLE, 1, &time_dimid, &timeid);
    nc_check(nc_def_var, ncid, "voltage", NC_DOUBLE, 1, &time_dimid, &varid);

    auto nc_put_att_cstr = [](int ncid, int varid, const char* name, const char* value) {
        nc_check(nc_put_att_text, ncid, varid, name, std::strlen(value), value);
    };

    nc_put_att_cstr(ncid, timeid, "units", "ms");
    nc_put_att_cstr(ncid, varid, "units", "mV");

    common_attr attrs;
    attrs.model = "rc-expsyn";
    attrs.simulator = "arbor";
    attrs.simulator_build = arb::version;
    attrs.simulator_build += ' ';
    attrs.simulator_build += arb::source_id;

    set_common_attr(ncid, attrs, A.tags, A.params);

    nc_check(nc_enddef, ncid);

    std::vector<double> times, values;
    times.reserve(vlen);
    values.reserve(vlen);
    for (auto e: vtrace.at(0)) {
        times.push_back(e.t);
        values.push_back(e.v);
    }

    nc_check(nc_put_var_double, ncid, timeid, times.data())
    nc_check(nc_put_var_double, ncid, varid, values.data())
    nc_check(nc_close, ncid);
}
