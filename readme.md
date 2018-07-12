# nsuite

A suite for benchmarking and validating NEURON, Nest and Arbor neuron network simulators/libraries.

This is in very early prototype stage. It currently can check out and build the 3 software on generic linux and Daint-mc, and has benchmarks for NEURON that match those implemented as examples in Arbor.

* `systems`: scripts that detect and set environment and modules for target systems.
* `scripts`: contains scripts for building and installing the simulation codes/libraries for benchmarking.
* `install`: path where the software is installed.
* `benchmarks`: benchmarks for comparing.
