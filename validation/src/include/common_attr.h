#pragma once

#include <netcdf.h>

#include "common_args.h"
#include "netcdf_wrap.h"

struct common_attr {
    std::string model, simulator, simulator_build;
};

void set_common_attr(int ncid, const common_attr& attrs, const tagset& tags, const paramset& params) {
    if (!attrs.model.empty()) {
        nc_check(nc_put_att_text, ncid, NC_GLOBAL, "validation_model", attrs.model.size(), attrs.model.c_str());
    }
    if (!attrs.simulator_build.empty()) {
        nc_check(nc_put_att_text, ncid, NC_GLOBAL, "simulator_build", attrs.simulator_build.size(), attrs.simulator_build.c_str());
    }

    if (!attrs.simulator.empty()) {
        std::string simtagged = attrs.simulator;

        std::vector<std::string> taglist(tags.begin(), tags.end());
        std::sort(taglist.begin(), taglist.end());
        for (auto& t: taglist) {
            simtagged += ':';
            simtagged += t;
        }

        nc_check(nc_put_att_text, ncid, NC_GLOBAL, "simulator", simtagged.size(), simtagged.c_str());
    }

    for (auto& kv: params) {
        nc_check(nc_put_att_double, ncid, NC_GLOBAL, kv.first.c_str(), NC_DOUBLE, 1u, &kv.second);
    }
}

