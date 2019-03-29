.. _running:

Running NSuite
============================

The second stage of the NSuite workflow is running benchmark and validation tests on simulation engines that were installed in the first stage when :ref:`install`.

Benchmarks and validation tests are launched with the respective scripts ``run-bench.sh`` and ``run-validation.sh``.

In the example workflow below, NEURON and CoreNEURON are first installed in a path called ``nrn`` using a user-specified environment configuration ``neuron-config.sh``, then benchmark and validation tests are run on the installed engines.

.. container:: example-code

    .. code-block:: bash

        # download and install NEURON and CoreNEURON in a directory called nrn
        ./install-local.sh neuron coreneuron --prefix=nrn --env=neuron-config.sh

        # run default benchmarks for NEURON and CoreNEURON 
        ./run-bench.sh neuron coreneuron --prefix=nrn

        # run validation tests for NEURON
        ./run-validation.sh neuron --prefix=nrn

The benchmark and validation runners take as arguments the simulators to test,
and the *prefix* where the simulation engines were installed.

.. Note::
    The environment does not have to be specified by the user using the
    ``--env`` flag, because the environment used to configure and
    build each simulation engine is saved during the installation with
    ``install-local.sh``, and automatically loaded for each simulation
    engine by the runners.

Flags and options for benchmark and validation runners are described in detail below.

Benchmarks
----------------------------

The full set of command line arguments for the benchmark runner ``run-bench.sh`` are:

====================  =================     ======================================================
Flag                  Default value         Explanation
====================  =================     ======================================================
``--help``                                  Display help message.
simulator             none                  Which simulation engines to benchmark.
                                            Any number of the following: {``arbor``, ``neuron``, ``coreneuron``}.
``--prefix``          current path          Path where simulation engines to benchmark were installed by ``install-local.sh``.
                                            All benchmark inputs and outputs will be saved here.
                                            Can be either a relative or absolute path.
``--model``           ``ring``              A list of benchmark models to run. At least one of {``ring``, ``kway``}.
``--config``          ``small``             A list of configurations to run for each benchmark model.
                                            At least one of  {``small``, ``medium``, ``large``}.
``--output``          ``'%m/%p/%s'``        Override default path to benchmark outputs.
                                            The provided path name will be appended to ``prefix``.
                                            Use ``--help`` for all format string options.
====================  =================     ======================================================

The ``--model`` and ``--config`` flags specify which benchmarks to run
and how they should be configured.  Currently there are two benchmark models,
*ring* and *kway*; detailed descriptions are in :ref:`benchmarks`.

.. container:: example-code

    .. code-block:: bash

        # run default benchmarks with Arbor
        ./run-bench.sh arbor

        # run ring and kway benchmarks with Arbor
        ./run-bench.sh arbor --model='ring kway'

        # run kway benchmark in medium and large configuration with Arbor
        ./run-bench.sh arbor --model=kway --config='medium large'

Each benchmark model has three configurations to choose from: ``small``, ``medium`` and ``large``.
The configurations can be used to test simulation engine performance at different scales.
For example, the *small* configuration has fewer cells with with simpler
morphologies than the *medium* and *large* configurations.
The *small* configuration requires little time to run, and is useful for modelling performance
characteristics of simpler models.
Likewise, models in *large* configuration take much longer to run, with considerably more parallel
work for benchmarking performance of large models on powerful HPC nodes.

.. Note::
    NEURON is used to generate input models for CoreNEURON. Before running a benchmark in
    CoreNEURON, the benchmark must first be run in NEURON.

.. _bench-outputs:

Benchmark output
"""""""""""""""""""""""""""

Two forms of output are generated when a benchmark case is run.
The first is a summary table printed to standard output, and the second is a CSV
file that can be saved for use by tools later analysis of benchmark output.
In the example below the *kway* model is run in the *small* configuration for Arbor and NEURON.

.. container:: example-code

    .. code-block:: bash

        ./run-bench.sh arbor neuron --model=kway --config=small --prefix=install
        ==  platform:          linux
        ==  cores per socket:  4
        ==  threads per core:  1
        ==  threads:           4
        ==  sockets:           1
        ==  mpi:               ON

        ==  benchmark: arbor kway-small
          cells compartments    wall(s)  throughput  mem-tot(MB) mem-percell(MB)
              2          90       0.041        48.8       0.318       0.159
              4         184       0.038       105.3       0.529       0.132
              8         368       0.039       205.1       0.822       0.103
             16         736       0.058       275.9       1.449       0.091
             32        1462       0.106       301.9       2.642       0.083
             64        2882       0.206       310.7       5.010       0.078
            128        5778       0.406       315.3       9.517       0.074
            256       11516       0.802       319.2      18.705       0.073

        ==  benchmark: neuron kway-small
          cells compartments    wall(s)  throughput  mem-tot(MB) mem-percell(MB)
              2          84       0.174        11.5           -           -
              4         172       0.179        22.4           -           -
              8         348       0.342        23.4           -           -
             16         688       0.711        22.5           -           -
             32        1384       1.380        23.2           -           -
             64        2792       3.600        17.8           -           -
            128        5596      14.049         9.1           -           -
            256       11188      33.246         7.7           -           -


Benchmark output for each {simulator, model, config} tuple is stored in the output
path ``prefix/output/benchmarks/${output}``. By default ``${output}`` is,
``model/config/simulator``, which can be overriden by the ``--output`` flag.
For the example above, two output files are generated, one for each simulator:

``install/output/benchmark/kway/small/arbor/results.csv``

.. code-block:: none


    cells,    walltime,      memory,  ranks,threads,    gpu
        2,       0.041,       0.318,      1,      4,     no
        4,       0.038,       0.529,      1,      4,     no
        8,       0.039,       0.822,      1,      4,     no
       16,       0.058,       1.449,      1,      4,     no
       32,       0.106,       2.642,      1,      4,     no
       64,       0.206,       5.010,      1,      4,     no
      128,       0.406,       9.517,      1,      4,     no
      256,       0.802,      18.705,      1,      4,     no

``install/output/benchmark/kway/small/neuron/results.csv``

.. code-block:: none

    cells,    walltime,      memory,  ranks,threads,    gpu
        2,       0.174,            ,      1,      4,     no
        4,       0.179,            ,      1,      4,     no
        8,       0.342,            ,      1,      4,     no
       16,       0.711,            ,      1,      4,     no
       32,       1.380,            ,      1,      4,     no
       64,       3.600,            ,      1,      4,     no
      128,      14.049,            ,      1,      4,     no
      256,      33.246,            ,      1,      4,     no

Descriptions and units for each column are tabulated below.

====================  =================     ======================================================
Column                Units                 Explanation
====================  =================     ======================================================
cells                 -                     Total number of cells in the model.
walltime              seconds               Time taken to run the simulation.
                                            Does not include model building or teardown times.
memory                megabytes             Total memory allocated during model building and simulation.
                                            Measured as the difference in total memory allocated between
                                            just after MPI is initialized and the simulation finishing.
ranks                 -                     The number of MPI ranks.
threads               -                     Number of threads per MPI rank.
gpu                   -                     If a GPU was used. One of yes/no.
====================  =================     ======================================================

Validation Tests
----------------------------

Validation tests are composed of a model, corresponding to a physical system to
be simulated, and a parameter set, which specifies parameters within that system.

The `run-validation.sh` script runs all or a subset of the models for one or more
installed simulators, saving test artefacts in a configurable output directory
and a presenting pass/fail status for each test on standard output.

Requirements
""""""""""""

The existing validation scripts use functionality from the ``scipy`` and
``xarray`` Python modules. These modules need to be available in the
Python module search path.

Invocation
""""""""""

.. code-block:: bash

   run-validation.sh [OPTIONS] SIMULATOR [SIMULATOR...]

``SIMULATOR`` can be any of the simulators installed with `install-local.sh`.
By default, `run-validation.sh` will use the current directory as the
installation and output base directory. If no models are explicitly selected
with the ``--model`` option (see below), all models and parameter sets will
be run against each specified simulator.

Options are as follows:

=================================  ======================================================
Option                             Explanation
=================================  ======================================================
``-h``, ``--help``                 Display help message and exit.
``-l``, ``--list-models``          List all available model/parameter sets.
``--prefix=PREFIX``                Base directory for local installation and output directories.
                                   Validation tests may also create reference datasets in
                                   ``PREFIX/cache``.
``-m``, ``--model=MODEL[/PARAM]``  A model or model/parameter set to run. ``MODEL`` alone
                                   is equivalent to ``MODEL/default``.
``-r``, ``--refresh``              Regenerate any required cached reference data sets.
``-o``, ``--output=FORMAT``        Substitute fields in ``FORMAT`` and use the resulting
                                   absolute or relative path for the validation test output
                                   directory. Relative paths are with respect to
                                   ``PREFIX/output/validation``.
=================================  ======================================================

By default, the outputs for a validation test run are stored in
``PREFIX/output/validation/SIMULATOR/MODEL/PARAM``, corresponding to an output format
of ``%s/%m/%p``. Fields in the ``FORMAT`` string are substituted as follows:

+--------+---------------------------------------------------------------------+
| ``%T`` | Timestamp of invocation of ``install-local.sh`` (ISO 8601/RFC 3339) |
+--------+---------------------------------------------------------------------+
| ``%H`` | NSuite git commit hash (with ``+`` suffix if modified)              |
+--------+---------------------------------------------------------------------+
| ``%h`` | NSuite git commit short hash (with ``+`` suffix if modified)        |
+--------+---------------------------------------------------------------------+
| ``%S`` | System name (if defined in system environment script) or host name  |
+--------+---------------------------------------------------------------------+
| ``%s`` | Simulator name                                                      |
+--------+---------------------------------------------------------------------+
| ``%m`` | Model name                                                          |
+--------+---------------------------------------------------------------------+
| ``%p`` | Parameter set name                                                  |
+--------+---------------------------------------------------------------------+
| ``%%`` | Literal '%'                                                         |
+--------+---------------------------------------------------------------------+

Output
""""""

``run-validation.sh`` will print pass/fail information to stdout, but will also
record information in the per-test output directories:

+-------------+-------------------------------------------+
| File        | Content                                   |
+=============+===========================================+
| ``run.out`` | Captured standard output from test script |
+-------------+-------------------------------------------+
| ``run.err`` | Captured standard error from test script  |
+-------------+-------------------------------------------+
| ``status``  | Pass/fail status (see below)              |
+-------------+-------------------------------------------+

The status is one of:

1.  ``pass`` — validation test succeeded.
2.  ``fail`` — validation test failed.
3.  ``missing`` — no implementation for the validation test found for requested simulator.
4.  ``error`` — an error occurred during validation test execution.

The output directory may contain other test artefacts. By convention only, these
may include:

+--------------+---------------------------------------------------------+
| File         | Content                                                 |
+==============+=========================================================+
| ``run.nc``   | Numerical results from simulator run in NetCDF4 format. |
+--------------+---------------------------------------------------------+
| ``delta.nc`` | Computed differences from reference data.               |
+--------------+---------------------------------------------------------+

