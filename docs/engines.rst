.. _engines:

Simulation Engines
==================

A simulation engine is a library or application for simulating multi-compartment
neural network models. NSuite supports three simulation engines: Arbor, NEURON and CoreNEURON.

.. table:: Default versions of each supported simulation engine

   =========== ======== ============== ====================================
   Engine       Version  Kind          Source
   =========== ======== ============== ====================================
   Arbor        0.2      git tag       GitHub `arbor-sim/arbor <https://github.com/arbor-sim/arbor>`_
   NEURON       7.6.5    tar ball      FTP `neuron.yale.edu <https://neuron.yale.edu/ftp/neuron/versions/>`_
   CoreNEURON   0.14     git tag       GitHub `BlueBrain/CoreNeuron <https://github.com/BlueBrain/CoreNeuron>`_
   =========== ======== ============== ====================================

Each benchmark and validation test is implemented for each engine that has
the features required to run the test.

Required features
------------------------------------------

For a simulation engine to run at least one of the benchmark and validation tests,
it must support the following features:

* **[required]** Support for compilation and running on Linux or OS X.
* **[required]** Support for arbitrary cell morphologies
* **[required]** Common ion channel types, specifically passive and Hodgkin-Huxely.
* **[required]** Support for user defined network connectivity.
* **[required]** Synapses with exponential decay, i.e. the expsyn and exp2syn synapse dynamics as defined in NEURON.
* Output of voltage traces at user-defined locations and time points.
* Output of gid and times for spikes.

.. Note::
    If a simulation engine doesn't support a feature required to run a test,
    the test will be skipped. For example, the only simulation output
    provided by CoreNEURON is spike times, so validation tests that require
    other information such as voltage traces are skipped when testing CoreNEURON.

NSuite does not describe models using universal model descriptions such as
`SONATA <https://github.com/AllenInstitute/sonata>`_ or `NeuroML <https://www.neuroml.org>`_.
Instead, benchmark and validation models are described using simulation engine-specific descriptions.

Arbor models
""""""""""""""""""""""""""""""""""""""""""

Models for Arbor are described using Arbor's C++ API, and as such,
they need to be compiled before they can be run.
Compilation of each model is performed during the installation phase, see :ref:`install`.

NEURON models
""""""""""""""""""""""""""""""""""""""""""

Models to run in NEURON are described using NEURON's Python interface.
The benchmarking and validation runners launch the models using with the Python 3
interpreter specified by the ``ns_python`` variable (see :ref:`vars_general`).

CoreNEURON models
""""""""""""""""""""""""""""""""""""""""""

NEURON is required to build models used as input for CoreNEURON.
There are two possible workflows for this:

1. Build a model in NEURON, write it to file, then load and run
   the model using the stand-alone CoreNEURON executable.
2. Build a model in NEURON, then run the model using CoreNEURON inside NEURON.

Benchmark models are run using the first approach, to minimise memory overheads and best
reflect what we believe will be the most efficient way to use CoreNEURON for HPC.

The second approach is used for validation tests, which run small models with low overheads,
to simplify the validation workflow by not requiring execution of separate NEURON and CoreNEURON
scripts and applications for a single model.

For more information about the different ways to run CoreNEURON, see the
`CoreNEURON documentation <https://github.com/BlueBrain/CoreNeuron>`_.

Adding a simulation engine
------------------------------------------

Support for a new simulation engine can be added using the steps described below.
All of the steps are implemented in bash scripts, and can be done by using the
scripts for Arbor, NEURON and CoreNEURON as templates.

Write installation script
""""""""""""""""""""""""""""""""""""""""""""""

Write an installation script that is responsible for:

* Downloading/checking out the code;
* Compiling and installing the library/application;
* Compiling benchmark and validation code if required.

The following scripts can be used as templates.

* Arbor: ``scripts/build_arbor.sh``
* NEURON: ``scripts/build_neuron.sh``
* CoreNEURON: ``scripts/build_coreneuron.sh``

Add simulator-specific variables
""""""""""""""""""""""""""""""""""""""""""""""

Each simulation engine has unique options specific to that engine,
for example:

* Arbor can specify which CPU architecture to target.
* Arbor can optionally be built with GPU support.
* NEURON requires parameters that describe how to download official release tar balls.

These options are configured using variables with prefixes of the form
``ns_{sim}_{feature}``, for example ``ns_arb_arch`` and ``ns_nrn_tarball``.
You can define variables as needed, and configure their default value,
in ``scripts/environment.sh``, in the ``default_environment``
`function <https://github.com/arbor-sim/nsuite/blob/master/scripts/environment.sh#L22>`_.

Add engine to ``install-local.sh`` 
""""""""""""""""""""""""""""""""""""""""""""""

The ``install-local.sh`` script has to be extended to support optional
installation of the new simulation engine. Follow the steps used by the existing
simulation engines.

.. Note::
    If the simulation engine requires separate compilation of individual
    benchmark and validation models, follow the example of how Arbor performs this
    step in ``scripts/build_arbor.sh``.

Implement benchmarks and validation tests
""""""""""""""""""""""""""""""""""""""""""""""

See :ref:`benchmarks` and :ref:`validation` pages for details on how to add benchmark
and validation tests.
