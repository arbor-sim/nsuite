#pragma once

// Exception and macro for wrapping netcdf calls, throwing on error.

#include <stdexcept>
#include <string>

#include <netcdf.h>

struct nc_error: std::runtime_error {
    nc_error(const char* fn, int st):
        std::runtime_error(std::string(fn)+": "+std::string(nc_strerror(st))),
        call(fn),
        status(st) {}

    int status;
    std::string call;
};

#define nc_check(fn, ...)\
if (auto r = fn(__VA_ARGS__)) { throw nc_error(#fn, r); } else {}

