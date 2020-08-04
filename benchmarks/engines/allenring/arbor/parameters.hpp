#include <iostream>

#include <array>
#include <cmath>
#include <fstream>
#include <random>

#include <sup/json_params.hpp>

// Parameters used to generate the random cell morphologies.
struct cell_parameters {
    cell_parameters() = default;

    std::string swc_file;

    // The number of synapses per cell.
    unsigned synapses = 1;
};

struct ring_params {
    ring_params() = default;

    std::string name = "default";
    unsigned num_cells = 10;
    unsigned ring_size = 10;
    double min_delay = 10;
    double duration = 400;
    double dt = 0.025;
    bool record_voltage = false;
    std::string odir = ".";
    cell_parameters cell;
};

ring_params read_options(int argc, char** argv) {
    const char* usage = "Usage:  arbor-busyring [params [opath]]\n\n"
                        "Driver for the Arbor busyring benchmark\n\n"
                        "Options:\n"
                        "   params: JSON file with model parameters.\n"
                        "   opath: output path.\n";
    using sup::param_from_json;

    ring_params params;
    if (argc<2) {
        return params;
    }
    if (argc>3) {
        std::cout << usage << std::endl;
        throw std::runtime_error("More than two command line options is not permitted.");
    }

    // Assume that the first argument is a json parameter file
    std::string fname = argv[1];
    std::ifstream f(fname);

    if (!f.good()) {
        throw std::runtime_error("Unable to open input parameter file: "+fname);
    }

    nlohmann::json json;
    json << f;

    param_from_json(params.name, "name", json);
    param_from_json(params.num_cells, "num-cells", json);
    param_from_json(params.ring_size, "ring-size", json);
    param_from_json(params.duration, "duration", json);
    param_from_json(params.dt, "dt", json);
    param_from_json(params.min_delay, "min-delay", json);
    param_from_json(params.record_voltage, "record", json);
    param_from_json(params.cell.swc_file, "swc_file", json);
    param_from_json(params.cell.synapses, "synapses", json);

    if (!json.empty()) {
        for (auto it=json.begin(); it!=json.end(); ++it) {
            std::cout << "  Warning: unused input parameter: \"" << it.key() << "\"\n";
        }
        std::cout << "\n";
    }

    // Set optional output path if a second argument was passed
    if (argc==3) {
        params.odir = argv[2];
    }

    return params;
}
