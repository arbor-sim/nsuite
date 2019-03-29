.. _benchmarks:

Benchmarks
==================

Architecture
------------

Benchmarks are set up in the NSuite source tree according to a specific layout.
Different benchmarks models can share an underlying benchmark. For example,
the *ring* and *kway* benchmarks are different configurations of
what we call a *busy-ring* model. In this case, the *busy-ring* is called
a benchmark *ENGINE* and *kway* is a benchmark *MODEL*. All scripts
and inputs for *ENGINE* are in the path ``benchmarks/engines/ENGINE``, and
inputs for a *MODEL* are in ``benchmarks/models/MODEL``.

Every model *MODEL* must provide a configuration
script ``benchmarks/models/MODEL/config.sh`` that takes the following arguments:

.. code-block:: bash

   config.sh $model                \ # model name
             $config               \ # configuration name
             $ns_base_path         \ # the base path of nsuite
             $ns_config_path       \ # path to config directory
             $ns_bench_input_path  \ # path to benchmark input base directory
             $ns_bench_output      \ # path to benchmark output base directory
             $output_format          # format string for simulator+model+config

The script will in turn generate a benchmark runner for each simulation engine:

1. ``$ns_bench_input_path/$model/$config/run_arb.sh``
2. ``$ns_bench_input_path/$model/$config/run_nrn.sh``
3. ``$ns_bench_input_path/$model/$config/run_corenrn.sh``

These scripts should generate benchmark output in the per-simulator path
``$ns_bench_output/$output_format`` where the ``$output_format`` defaults to ``$model/$config/$engine``.

.. Note::
    NSuite does not specify how the contents of ``benchmarks/engines/ENGINE``
    have to be laid out.

Performance reporting
"""""""""""""""""""""

Each benchmark run has to report metrics such as simulation time, memory consumption, the number of cells in model, and so on.
These are output in the formats described in :ref:`bench-outputs`.

Arbor has a standardised way of measuring and reporting metrics using what it calls *meters*.
NSuite provides a Python module in ``common/python/metering.py`` that offers the
same functionality in Python, which can be used for the NEURON benchmarks.

With this standard output format, the ``scrpts/csv_bench.sh`` script can be used to automatically generate the CSV output.

