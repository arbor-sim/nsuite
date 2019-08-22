#pragma once

// Common handling of command line arguments in validation test implementations.
//
// Argument convention is:
//     test-impl -o <output> [-t <tag> [-t <tag>] ... ] [key=value ...]
//     test-impl --list-tags
//
// Unrecognized options are left in argv for parsing by the implementation.

#include <cstdlib>
#include <cstring>
#include <string>
#include <unordered_map>
#include <unordered_set>

using paramset = std::unordered_map<std::string, double>;
using tagset = std::unordered_set<std::string>;

struct common_args {
    std::string output;
    tagset tags;
    paramset params;
};

constexpr int unrecognized_tag_exit_code = 98;

inline void parse_common_args(common_args& A, int argc, char** argv, const tagset& valid_tags) {
    const char* prog = strrchr(argv[0], '/');
    prog = prog? prog+1: argv[0];

    auto shift = [](char** a, int n=1) {
        char** b = a;
        for (int i = 0; *b && i<n; ++i) ++b;

        while (*a) {
            *a++ = *b;
            if (*b) ++b;
        }
    };

    auto usage = [prog](int exit_code = 0) {
        (exit_code? std::cerr: std::cout) <<
            "usage: " << prog << " -o <output> [-t <tag>]... [key=value ...]\n"
            "       " << prog << " --list-tags\n"
            "       " << prog << " --help\n";
        std::exit(exit_code);
    };

    for (char** arg = argv+1; *arg;) {
        if (!strcmp(*arg, "--list-tags")) {
            for (auto& tag: valid_tags) std::cout << tag << "\n";
            std::exit(0);
        }

        if (!strcmp(*arg, "--help")) {
            usage();
        }

        if (!strcmp(*arg, "-o")) {
            shift(arg);
            if (!*arg) usage(1);
            A.output = *arg;
            shift(arg);
            continue;
        }

        if (!strcmp(*arg, "--tag")) {
            shift(arg);
            if (!*arg) usage(1);
            if (!valid_tags.count(*arg)) usage(unrecognized_tag_exit_code);
            A.tags.insert(*arg);
            shift(arg);
            continue;
        }

        if (auto eq = strchr(*arg, '=')) {
            try {
                A.params[std::string(*arg, eq)] = std::stod(eq+1);
                shift(arg);
                continue;
            }
            catch (std::logic_error&) {
                usage(true);
            }
        }

        ++arg;
    }

    if (A.output.empty()) usage(1);
}
