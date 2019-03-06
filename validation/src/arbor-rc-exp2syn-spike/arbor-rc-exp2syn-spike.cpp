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

using namespace arb;

using paramset = std::map<std::string, double>;
paramset default_parameters = {
    {"dt", 0.01},
    {"g0", 0.1},
    {"delay", 3.3},
    {"threshold", -10}
};

struct rc_exp2syn_spike_recipe: public arb::recipe {
    static constexpr double pi = 3.141592653589793238462643383279502884;

    // Fixed parameters:

    static constexpr double r = 9e-6;        // soma radius [m]
    static constexpr double area = 4*pi*r*r; // soma surface area [m²]
    static constexpr double rm = 100;        // total membrane resistance [MΩ]
    static constexpr double cm = 0.01;       // total membrane capacitance [nF]
    static constexpr double erev = -65;      // reversal potential [mV]
    static constexpr double tau1 = 0.5;      // synapse exponential time constants [ms]
    static constexpr double tau2 = 4.0;

    // Customizable parameters:
    double g0;                               // synaptic conductance at time 0 [µS]
    double delay;                            // connection delay
    double threshold;                        // spike voltage threshold

    static segment_location soma_centre() {
        return segment_location(0u, 0.5);
    }

    explicit rc_exp2syn_spike_recipe(const paramset& ps):
        g0(ps.at("g0")), delay(ps.at("delay")), threshold(ps.at("threshold"))
    {}

    cell_size_type num_cells() const override { return 2; }
    cell_size_type num_sources(cell_gid_type) const override { return 1; }
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

    std::vector<event_generator> event_generators(cell_gid_type gid) const override {
        if (gid!=0) return {};

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

        mechanism_desc expsyn("exp2syn");
        expsyn["tau1"] = tau1;
        expsyn["tau2"] = tau2;
        expsyn["e"] = 0;
        c.add_synapse(soma_centre(), expsyn);

        c.add_detector(soma_centre(), threshold);
        return c;
    }

    std::vector<arb::cell_connection> connections_on(cell_gid_type gid) const override {
        if (gid!=1) return {};

        return {arb::cell_connection({0u, 0}, {1u, 0}, g0, delay)};
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

struct nc_error: std::runtime_error {
    nc_error(const char* fn, int st):
        std::runtime_error(std::string(fn)+": "+std::string(nc_strerror(st))),
        call(fn),
        status(st) {}

    int status;
    std::string call;
};

struct arg_data {
    std::string output;
    paramset params = default_parameters;
};

struct named_trace {
    std::string v_name, t_name;
    arb::trace_data<double> trace;
};

void common_parse_arguments(char** argv, arg_data& args);
void write_netcdf_traces(const char* path, const std::vector<named_trace>& traces, const paramset& scalars = paramset{});

int usage(char* argv0) {
    char* basename = std::strrchr(argv0, '/');
    basename = basename? basename+1: argv0;

    std::cerr << "Usage: " << basename << " OUTFILE [ PARAM=VALUE ... ]\n";
    return 1;
}

int main(int argc, char** argv) {
    paramset params{default_parameters};
    const char* output = argv[1];

    if (!output) return usage(argv[0]);
    try {
        for (auto a = argv+2; *a; ++a) {
            if (char* eq = std::strrchr(*a, '=')) {
                params[std::string{*a, eq}] = std::stod(eq+1);
            }
            else return usage(argv[0]);
        }
    }
    catch (...) {
        return usage(argv[0]);
    }

    auto ctx = make_context();
    rc_exp2syn_spike_recipe rec(params);
    simulation sim(rec, trivial_dd(rec), ctx);

    time_type t_end = 10., sample_dt = 0.05; // [ms]
    time_type dt = params["dt"];

    std::vector<named_trace> traces = {
        {"v0", "t0", {}},
        {"v1", "t1", {}}
    };
    sim.add_sampler(one_probe({0u, 0u}), regular_schedule(sample_dt), make_simple_sampler(traces[0].trace));
    sim.add_sampler(one_probe({1u, 0u}), regular_schedule(sample_dt), make_simple_sampler(traces[1].trace));

    time_type first_spike[2] = { NAN, NAN };
    sim.set_global_spike_callback(
        [&](const std::vector<arb::spike>& spikes) {
            for (auto s: spikes) {
                auto gid = s.source.gid;
                auto t = s.time;

                if (gid<2 && (std::isnan(first_spike[gid]) || first_spike[gid]>t)) {
                    first_spike[gid] = t;
                }
            }
        });

    sim.run(t_end, dt);

    auto scalars = params;
    scalars["spike0"] = first_spike[0];
    scalars["spike1"] = first_spike[1];

    write_netcdf_traces(output, traces, scalars);
}

#define nc_check(fn, ...)\
if (auto r = fn(__VA_ARGS__)) { throw nc_error(#fn, r); } else {}

void write_netcdf_traces(const char* path, const std::vector<named_trace>& traces, const paramset& scalars) {
    int ncid;
    nc_check(nc_create, path, 0, &ncid);

    unsigned n_trace = traces.size();
    std::vector<int> timeids(n_trace), varids(n_trace);

    for (unsigned i = 0; i<n_trace; ++i) {
        std::size_t len = traces[i].trace.size();
        int time_dimid;
        nc_check(nc_def_dim, ncid, traces[i].t_name.c_str(), len, &time_dimid);
        nc_check(nc_def_var, ncid, traces[i].t_name.c_str(), NC_DOUBLE, 1, &time_dimid, &timeids[i]);
        nc_check(nc_def_var, ncid, traces[i].v_name.c_str(), NC_DOUBLE, 1, &time_dimid, &varids[i]);
    }

    std::vector<int> scalar_ids;
    for (const auto& kv: scalars) {
        int id;
        nc_check(nc_def_var, ncid, kv.first.c_str(), NC_DOUBLE, 0, nullptr, &id);
        scalar_ids.push_back(id);
    }

    nc_check(nc_enddef, ncid);

    unsigned pidx = 0;
    for (const auto& kv: scalars) {
        int id;
        nc_check(nc_put_var_double, ncid, scalar_ids[pidx++], &kv.second);
    }

    for (unsigned i = 0; i<n_trace; ++i) {
        std::size_t len = traces[i].trace.size();
        std::vector<double> times, values;

        times.reserve(len);
        values.reserve(len);
        for (auto e: traces[i].trace) {
            times.push_back(e.t);
            values.push_back(e.v);
        }

        nc_check(nc_put_var_double, ncid, timeids[i], times.data())
        nc_check(nc_put_var_double, ncid, varids[i], values.data())
    }

    nc_check(nc_close, ncid);
}
