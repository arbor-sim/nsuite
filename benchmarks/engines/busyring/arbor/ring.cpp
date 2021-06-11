#include <fstream>
#include <iomanip>
#include <iostream>

#include <nlohmann/json.hpp>

#include <arbor/assert_macro.hpp>
#include <arbor/common_types.hpp>
#include <arbor/context.hpp>
#include <arbor/load_balance.hpp>
#include <arbor/cable_cell.hpp>
#include <arbor/profile/meter_manager.hpp>
#include <arbor/profile/profiler.hpp>
#include <arbor/simple_sampler.hpp>
#include <arbor/simulation.hpp>
#include <arbor/symmetric_recipe.hpp>
#include <arbor/recipe.hpp>
#include <arbor/version.hpp>

#include <arborenv/concurrency.hpp>
#include <arborenv/gpu_env.hpp>

#include "parameters.hpp"

#ifdef ARB_MPI_ENABLED
#include <mpi.h>
#include <arborenv/with_mpi.hpp>
#endif

using arb::cell_gid_type;
using arb::cell_lid_type;
using arb::cell_size_type;
using arb::cell_member_type;
using arb::cell_kind;
using arb::time_type;
using arb::cable_probe_membrane_voltage;

// Writes voltage trace as a json file.
void write_trace_json(std::string fname, const arb::trace_data<double>& trace);

// Generate a cell.
arb::cable_cell branch_cell(arb::cell_gid_type gid, const cell_parameters& params);
arb::cable_cell complex_cell(arb::cell_gid_type gid, const cell_parameters& params);

class ring_tile: public arb::tile {
public:
    ring_tile(ring_params params):
        num_cells_per_tile_(params.num_cells / params.num_ranks),
        num_tiles_(params.num_ranks),
        min_delay_(params.min_delay),
        params_(params),
        cat(arb::global_allen_catalogue())
    {
        cat.import(arb::global_default_catalogue(), "");
        gprop.default_parameters = arb::neuron_parameter_defaults;
        gprop.catalogue = &cat;

        if (params.cell.complex_cell) {
            gprop.default_parameters.reversal_potential_method["ca"] = "nernst/ca";
            gprop.default_parameters.axial_resistivity = 100;
            gprop.default_parameters.temperature_K = 34 + 273.15;
            gprop.default_parameters.init_membrane_potential = -90;
            event_weight_*=5;
        }
    }

    cell_size_type num_tiles() const override {
        return num_tiles_;
    }
    cell_size_type num_cells() const override {
        return num_cells_per_tile_;
    }

    arb::util::unique_any get_cell_description(cell_gid_type gid) const override {
        if (params_.cell.complex_cell) {
            return complex_cell(gid, params_.cell);
        }
        return branch_cell(gid, params_.cell);
    }

    cell_kind get_cell_kind(cell_gid_type gid) const override {
        return cell_kind::cable;
    }

    // Each cell has one spike detector (at the soma).
    cell_size_type num_sources(cell_gid_type gid) const override {
        return 1;
    }

    // The cell has one target synapse, which will be connected to cell gid-1.
    cell_size_type num_targets(cell_gid_type gid) const override {
        return params_.cell.synapses;
    }

    std::any get_global_properties(cell_kind kind) const override {
        return gprop;
    }

    // Each cell has one incoming connection, from cell with gid-1,
    // and fan_in-1 random connections with very low weight.
    std::vector<arb::cell_connection> connections_on(cell_gid_type gid) const override {
        std::vector<arb::cell_connection> cons;
        const auto ncons = params_.cell.synapses;
        cons.reserve(ncons);

        const auto s = params_.ring_size;
        const auto group = gid/s;
        const auto group_start = s*group;
        const auto group_end = std::min(group_start+s, num_cells_per_tile_);
        cell_gid_type src = gid==group_start? group_end-1: gid-1;
        cons.push_back(arb::cell_connection({src, 0}, 0, event_weight_, min_delay_));

        // Used to pick source cell for a connection.
        // source can be from any cell, not just the cells on this tile
        std::uniform_int_distribution<cell_gid_type> dist(0, params_.num_cells -2);
        // Used to pick delay for a connection.
        std::uniform_real_distribution<float> delay_dist(0, 2*min_delay_);
        auto src_gen = std::mt19937(gid);
        for (unsigned i=1; i<ncons; ++i) {
            // Make a connection with weight 0.
            // The source is randomly picked, with no self connections.
            src = dist(src_gen);
            if (src==gid) ++src;
            const float delay = min_delay_+delay_dist(src_gen);
            //const float delay = min_delay_;
            cons.push_back(
                arb::cell_connection({src, 0}, i, 0.f, delay));
        }

        return cons;
    }

    // Return one event generator on the first cell of each ring.
    // This generates a single event that will kick start the spiking on the sub-ring.
    std::vector<arb::event_generator> event_generators(cell_gid_type gid) const override {
        std::vector<arb::event_generator> gens;
        if ((gid%num_cells_per_tile_)%params_.ring_size == 0) {
            gens.push_back(
                arb::explicit_generator(
                    arb::pse_vector{{0, 1.0, event_weight_}}));
        }
        return gens;
    }

    std::vector<arb::probe_info> get_probes(cell_gid_type gid) const override {
        // Measure at the soma.
        arb::mlocation loc{0, 0.0};
        return {cable_probe_membrane_voltage{loc}};
    }

private:
    cell_size_type num_cells_per_tile_;
    cell_size_type num_tiles_;
    double min_delay_;
    ring_params params_;
    float event_weight_ = 0.1;

    arb::cable_cell_global_properties gprop;
    arb::mechanism_catalogue cat;
};

struct cell_stats {
    using size_type = unsigned;
    size_type ncells = 0;
    size_type nbranch = 0;
    size_type ncomp = 0;

    cell_stats(arb::recipe& r) {
#ifdef ARB_MPI_ENABLED
        int nranks, rank;
        MPI_Comm_rank(MPI_COMM_WORLD, &rank);
        MPI_Comm_size(MPI_COMM_WORLD, &nranks);
        ncells = r.num_cells();
        size_type cells_per_rank = ncells/nranks;
        size_type b = rank*cells_per_rank;
        size_type e = (rank==nranks-1)? ncells: (rank+1)*cells_per_rank;
        size_type nbranch_tmp = 0, ncomp_tmp = 0;
        for (size_type i=b; i<e; ++i) {
            auto c = arb::util::any_cast<arb::cable_cell>(r.get_cell_description(i));
            nbranch_tmp += c.morphology().num_branches();
            for (unsigned i = 0; i < c.morphology().num_branches(); ++i) {
                ncomp_tmp += c.morphology().branch_segments(i).size();
            }
        }
        MPI_Allreduce(&nbranch_tmp, &nbranch, 1, MPI_UNSIGNED, MPI_SUM, MPI_COMM_WORLD);
        MPI_Allreduce(&ncomp_tmp, &ncomp, 1, MPI_UNSIGNED, MPI_SUM, MPI_COMM_WORLD);
#else
        ncells = r.num_cells();
        for (size_type i=0; i<ncells; ++i) {
            auto c = arb::util::any_cast<arb::cable_cell>(r.get_cell_description(i));
            nbranch += c.morphology().num_branches();
            for (unsigned i = 0; i < c.morphology().num_branches(); ++i) {
                ncomp += c.morphology().branch_segments(i).size();
            }
        }
#endif
    }

    friend std::ostream& operator<<(std::ostream& o, const cell_stats& s) {
        return o << "cell stats: "
                 << s.ncells << " cells; "
                 << s.nbranch << " branches; "
                 << s.ncomp << " compartments.";
    }
};

int main(int argc, char** argv) {
    try {
        bool root = true;

        arb::proc_allocation resources;
        if (auto nt = arbenv::get_env_num_threads()) {
            resources.num_threads = nt;
        }
        else {
            resources.num_threads = arbenv::thread_concurrency();
        }

        auto params = read_options(argc, argv);

#ifdef ARB_MPI_ENABLED
        arbenv::with_mpi guard(argc, argv, false);
        resources.gpu_id = arbenv::find_private_gpu(MPI_COMM_WORLD);
#else
        resources.gpu_id = arbenv::default_gpu();
#endif

        arb::context context;
        if(params.dryrun) {
            context = arb::make_context(resources, arb::dry_run_info(params.num_ranks, params.num_cells / params.num_ranks));
        }
        else {
#ifdef ARB_MPI_ENABLED
            context = arb::make_context(resources, MPI_COMM_WORLD);
            root = arb::rank(context) == 0;
#else
            context = arb::make_context(resources);
#endif
        }
        arb_assert(arb::num_ranks(context)==params.num_ranks);

#ifdef ARB_PROFILE_ENABLED
        arb::profile::profiler_initialize(context);
        if (root) std::cout << "Profiling enabled" << std::endl;
#endif

        // Print a banner with information about hardware configuration
        if (root) {
            std::cout << "gpu:      " << (has_gpu(context)? "yes": "no") << "\n";
            std::cout << "threads:  " << num_threads(context) << "\n";
            std::cout << "mpi:      " << (has_mpi(context)? "yes": "no") << "\n";
            std::cout << "ranks:    " << num_ranks(context) << "\n";
            std::cout << "dryrun:   " << (params.dryrun ? "yes": "no") << "\n" << std::endl;
        }

        arb::profile::meter_manager meters;
        meters.start(context);

        // Create an instance of our recipe.
        auto tile = std::make_unique<ring_tile>(params);
        arb::symmetric_recipe recipe(std::move(tile));
        cell_stats stats(recipe);
        if (root) std::cout << stats << "\n";

        //arb::partition_hint_map hints;
        //hints[cell_kind::cable1d_neuron].cpu_group_size = 4;
        //auto decomp = arb::partition_load_balance(recipe, context, hints);
        auto decomp = arb::partition_load_balance(recipe, context);

        // Construct the model.
        arb::simulation sim(recipe, decomp, context);

        // Set up the probe that will measure voltage in the cell.

        // This is where the voltage samples will be stored as (time, value) pairs
        arb::trace_vector<double> voltage;
        if (params.record_voltage) {
            // The id of the only probe on the cell:
            // the cell_member type points to (cell 0, probe 0)
            auto probe_id = cell_member_type{0, 0};
            // The schedule for sampling is 10 samples every 1 ms.
            auto sched = arb::regular_schedule(0.1);
            // Now attach the sampler at probe_id, with sampling schedule sched, writing to voltage
            sim.add_sampler(arb::one_probe(probe_id), sched, arb::make_simple_sampler(voltage));
        }

        // Set up recording of spikes to a vector on the root process.
        std::vector<arb::spike> recorded_spikes;
        if (root) {
            sim.set_global_spike_callback(
                [&recorded_spikes](const std::vector<arb::spike>& spikes) {
                    recorded_spikes.insert(recorded_spikes.end(), spikes.begin(), spikes.end());
                });
        }

        meters.checkpoint("model-init", context);

        // Run the simulation.
        if (root) std::cout << "running simulation" << std::endl;
        sim.set_binning_policy(arb::binning_kind::regular, params.dt);
        sim.run(params.duration, params.dt);

        meters.checkpoint("model-run", context);

        auto ns = sim.num_spikes();

        // Write spikes to file
        if (root) {
            std::cout << "\n" << ns << " spikes generated at rate of "
                      << params.duration/ns << " ms between spikes\n";
            std::ofstream fid(params.odir + "/" + params.name + "_spikes.gdf");
            if (!fid.good()) {
                std::cerr << "Warning: unable to open file spikes.gdf for spike output\n";
            }
            else {
                char linebuf[45];
                for (auto spike: recorded_spikes) {
                    auto n = std::snprintf(
                        linebuf, sizeof(linebuf), "%u %.4f\n",
                        unsigned{spike.source.gid}, float(spike.time));
                    fid.write(linebuf, n);
                }
            }
        }

        // Write the samples to a json file samples were stored on this rank.
        if (voltage.size()>0u) {
            std::string fname = params.odir + "/" + params.name + "_voltages.json";
            write_trace_json(fname, voltage.at(0));
        }

        auto profile = arb::profile::profiler_summary();
        if (root) std::cout << profile << "\n";

        auto report = arb::profile::make_meter_report(meters, context);
        if (root) std::cout << report;
    }
    catch (std::exception& e) {
        std::cerr << "exception caught in ring miniapp: " << e.what() << "\n";
        return 1;
    }

    return 0;
}

void write_trace_json(std::string fname, const arb::trace_data<double>& trace) {
    nlohmann::json json;
    json["name"] = "ring demo";
    json["units"] = "mV";
    json["cell"] = "0.0";
    json["probe"] = "0";

    auto& jt = json["data"]["time"];
    auto& jy = json["data"]["voltage"];

    for (const auto& sample: trace) {
        jt.push_back(sample.t);
        jy.push_back(sample.v);
    }

    std::ofstream file(fname);
    file << std::setw(1) << json << "\n";
}

// Helper used to interpolate in branch_cell.
template <typename T>
double interp(const std::array<T,2>& r, unsigned i, unsigned n) {
    double p = i * 1./(n-1);
    double r0 = r[0];
    double r1 = r[1];
    return r[0] + p*(r1-r0);
}

arb::cable_cell complex_cell (arb::cell_gid_type gid, const cell_parameters& params) {
    using arb::reg::tagged;
    using arb::reg::all;
    using arb::ls::location;
    using arb::ls::uniform;
    using mech = arb::mechanism_desc;

    arb::segment_tree tree;

    double soma_radius = 12.6157/2.0;
    int soma_tag = 1;
    tree.append(arb::mnpos, {0, 0,-soma_radius, soma_radius}, {0, 0, soma_radius, soma_radius}, soma_tag); // For area of 500 μm².

    std::vector<std::vector<unsigned>> levels;
    levels.push_back({0});

    // Standard mersenne_twister_engine seeded with gid.
    std::mt19937 gen(gid);
    std::uniform_real_distribution<double> dis(0, 1);

    double dend_radius = 0.5; // Diameter of 1 μm for each cable.
    int dend_tag = 3;

    double dist_from_soma = soma_radius;
    for (unsigned i=0; i<params.max_depth; ++i) {
        // Branch prob at this level.
        double bp = interp(params.branch_probs, i, params.max_depth);
        // Length at this level.
        double l = interp(params.lengths, i, params.max_depth);
        // Number of compartments at this level.
        unsigned nc = std::round(interp(params.compartments, i, params.max_depth));

        std::vector<unsigned> sec_ids;
        for (unsigned sec: levels[i]) {
            for (unsigned j=0; j<2; ++j) {
                if (dis(gen)<bp) {
                    auto z = dist_from_soma;
                    auto dz = l/nc;
                    auto p = sec;
                    for (unsigned k=1; k<nc; ++k) {
                        p = tree.append(p, {0,0,z+(k+1)*dz, dend_radius}, dend_tag);
                    }
                    sec_ids.push_back(p);
                }
            }
        }
        if (sec_ids.empty()) {
            break;
        }
        levels.push_back(sec_ids);

        dist_from_soma += l;
    }

    arb::label_dict dict;

    dict.set("soma", tagged(1));
    dict.set("axon", tagged(2));
    dict.set("dend", tagged(3));
    dict.set("apic", tagged(4));
    dict.set("center", location(0, 0.5));
    if (params.synapses>1) {
       dict.set("synapses",  arb::ls::uniform(arb::reg::all(), 0, params.synapses-2, gid));
    }

    arb::decor decor;

    decor.paint(all(), arb::init_reversal_potential{"k",  -107.0});
    decor.paint(all(), arb::init_reversal_potential{"na", 53.0});

    decor.paint("\"soma\"", arb::axial_resistivity{133.577});
    decor.paint("\"soma\"", arb::membrane_capacitance{4.21567e-2});

    decor.paint("\"dend\"", arb::axial_resistivity{68.355});
    decor.paint("\"dend\"", arb::membrane_capacitance{2.11248e-2});

    decor.paint("\"soma\"", mech("pas").set("g", 0.000119174).set("e", -76.4024));
    decor.paint("\"soma\"", mech("NaV").set("gbar", 0.0499779));
    decor.paint("\"soma\"", mech("SK").set("gbar", 0.000733676));
    decor.paint("\"soma\"", mech("Kv3_1").set("gbar", 0.186718));
    decor.paint("\"soma\"", mech("Ca_HVA").set("gbar", 9.96973e-05));
    decor.paint("\"soma\"", mech("Ca_LVA").set("gbar", 0.00344495));
    decor.paint("\"soma\"", mech("CaDynamics").set("gamma", 0.0177038).set("decay", 42.2507));
    decor.paint("\"soma\"", mech("Ih").set("gbar", 1.07608e-07));

    decor.paint("\"dend\"", mech("pas").set("g", 9.57001e-05).set("e", -88.2554));
    decor.paint("\"dend\"", mech("NaV").set("gbar", 0.0472215));
    decor.paint("\"dend\"", mech("Kv3_1").set("gbar", 0.186859));
    decor.paint("\"dend\"", mech("Im_v2").set("gbar", 0.00132163));
    decor.paint("\"dend\"", mech("Ih").set("gbar", 9.18815e-06));

    decor.place("\"center\"", mech("expsyn"));
    if (params.synapses>1) {
       decor.place("\"synapses\"", "expsyn");
    }

    decor.place("\"center\"", arb::threshold_detector{-20.0});

    decor.set_default(arb::cv_policy_every_segment());

    return {arb::morphology(tree), dict, decor};
}

arb::cable_cell branch_cell(arb::cell_gid_type gid, const cell_parameters& params) {
    arb::segment_tree tree;

    // Add soma.
    double soma_radius = 12.6157/2.0;
    int soma_tag = 1;
    tree.append(arb::mnpos, {0, 0,-soma_radius, soma_radius}, {0, 0, soma_radius, soma_radius}, soma_tag); // For area of 500 μm².

    std::vector<std::vector<unsigned>> levels;
    levels.push_back({0});

    // Standard mersenne_twister_engine seeded with gid.
    std::mt19937 gen(gid);
    std::uniform_real_distribution<double> dis(0, 1);

    double dend_radius = 0.5; // Diameter of 1 μm for each cable.
    int dend_tag = 3;

    double dist_from_soma = soma_radius;
    for (unsigned i=0; i<params.max_depth; ++i) {
        // Branch prob at this level.
        double bp = interp(params.branch_probs, i, params.max_depth);
        // Length at this level.
        double l = interp(params.lengths, i, params.max_depth);
        // Number of compartments at this level.
        unsigned nc = std::round(interp(params.compartments, i, params.max_depth));

        std::vector<unsigned> sec_ids;
        for (unsigned sec: levels[i]) {
            for (unsigned j=0; j<2; ++j) {
                if (dis(gen)<bp) {
                    auto z = dist_from_soma;
                    auto dz = l/nc;
                    auto p = sec;
                    for (unsigned k=1; k<nc; ++k) {
                        p = tree.append(p, {0,0,z+(k+1)*dz, dend_radius}, dend_tag);
                    }
                    sec_ids.push_back(p);
                }
            }
        }
        if (sec_ids.empty()) {
            break;
        }
        levels.push_back(sec_ids);

        dist_from_soma += l;
    }

    arb::label_dict labels;

    using arb::reg::tagged;
    labels.set("soma",      tagged(1));
    labels.set("dendrites", join(tagged(3), tagged(4)));
    if (params.synapses>1) {
       labels.set("synapses",  arb::ls::uniform(arb::reg::all(), 0, params.synapses-2, gid));
    }

    arb::decor decor;

    decor.paint("\"soma\"", "hh");
    decor.paint("\"dendrites\"", "pas");
    decor.set_default(arb::axial_resistivity{100}); // [Ω·cm]

    // Add spike threshold detector at the soma.
    decor.place(arb::mlocation{0,0}, arb::threshold_detector{10});

    // Add a synapse to proximal end of first dendrite.
    decor.place(arb::mlocation{1, 0}, "expsyn");

    // Add additional synapses that will not be connected to anything.
    if (params.synapses>1) {
        decor.place("\"synapses\"", "expsyn");
    }

    // Make a CV between every sample in the sample tree.
    decor.set_default(arb::cv_policy_every_segment());

    return {arb::morphology(tree), labels, decor};
}
