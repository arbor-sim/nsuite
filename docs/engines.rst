.. _engines:

Simulation Engines
==================

A simulation engine is a library or application for simulating multi-compartment
neural network models.

Supported simulation engines
----------------------------

NSuite supports three simulation engines: Arbor, NEURON and CoreNeuron.

.. table:: Default versions of each supported simulation engine

   =========== ======== ============== ====================================
   Engine       Version  Kind          Source
   =========== ======== ============== ====================================
   Arbor        0.2      git tag       GitHub `arbor-sim/arbor <https://github.com/arbor-sim/arbor>`_
   NEURON       7.6      tar ball      FTP `neuron.yale.edu <https://neuron.yale.edu/ftp/neuron/versions/>`_
   CoreNeuron   0.14     git tag       GitHub `BlueBrain/CoreNeuron <https://github.com/BlueBrain/CoreNeuron>`_
   =========== ======== ============== ====================================

Each benchmark and validation test is implemented for each supported engine that has
the features required to run the test.

Adding support for a new simulation engine
""""""""""""""""""""""""""""""""""""""""""

Simulator features required

* Linux support
* Arbitrary cell morphologies
* Common mechanism/ion channel including passive and Hodgkin-Huxely.

.. Note::
    If a simulation engine doesn't suport a feature required to run a test,
    the test will be skipped. For example, the only simulation output
    provided by CoreNeuron is spike times, so validation tests that require
    other information such as voltage traces are not supported.

    For example, spike times are the only simulation state output by CoreNeuron.
    Hence validation tests that test voltage traces can't be implemented in
    CoreNeuron.


Steps required to add:

- Write an installation script that is responsible for:

    - downloading/checking out the code;
    - compiling and installing the library/application;
    - compiling benchmark and validation code if required.

- Add ``ns_newsim_X`` variables to the environment
- Implement benchmark ``drivers`` for that simulator

    - ``benchmarks/engines/S/newsim``

- Add benchmark configuration for that simulator

    - Update ``benchmarks/models/M/config.sh``


because bash is supported everywhere, because bash is
used by continuous integration systems like (Travis) and (Jenkins), and because
NSuite does not require anything more sophisticated.
