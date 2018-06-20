# Notes

## Stages

### Build

Build and install in `base/install`.

What are we building?
    1 nest and neuron libraries
    2 nest and neuron python wrappers
        - set PATH and PYTHONPATH (A)
    3 nest and neuron plugins
        - set paths for location of plugins (B)

1 and 2 are done sequentially with the same environment.
3 requires that the environment has been extended to include the
PYTHONPATH, PATH etc to reflect the installed software.

Have a build script that takes an argument describing the system that
it is to build for. If no argument is passed it should attempt to automatically
determine the system.

### Execute

Load the modules used to build.
Load the paths that were set during build.
    - prepend to start of PATH and PYTHONPATH

## setting up the environment

Set up the build environment
    - modules
    - build specific environment variables `CRAYPE_LINK_TYPE=dynamic`

Set up the execution environment
    - modules
    - PATH and PYTHONPATH


## Paths

`systems` system specific configurations
`build` build scripts for each package
`plugins` path with plugins for each simulator
`benchmarks` path with benchmarks, each sub-directory contains:
    - each path contains the benchmark
    - and post processing scripts for packaging up results

Things to consider:
    - maybe the plugins ought to be in the benchmark path in which they are used?

benchmarks
    |
    |----timing cell
    |       |--------Arbor
    |       |
    |       |--------Nest
    |       |
    |       |--------Neuron
    |
    |----ring
    |       |--------Arbor
    |       |
    |       |--------Neuron
    |
    .
    .

