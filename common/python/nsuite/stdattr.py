#!/usr/bin/env python

# Common attribute conventions for NetCDF/xarray output from python
# validation scripts.

from functools import reduce

def set_stdattr(outx, model=None, simulator=None, simulator_build=None, tags=[], params={}):
    for (k, v) in params.items():
        outx.attrs[str(k)] = float(v)

    tags.sort()
    if simulator is not None:
        outx.attrs['simulator'] = reduce(lambda s, tag: s+':'+tag, tags, str(simulator))
        if simulator_build is not None:
            outx.attrs['simulator_build'] = str(simulator_build)

    if model is not None:
        outx.attrs['validation_model'] = str(model)

