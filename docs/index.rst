NSuite
======

NSuite is a framework for maintaining and running benchmarks and validation tests
for multi-compartment neural network simulations on HPC systems.
NSuite automates the process of building simulation engines, and running benchmarks
and validation tests.
NSuite is specifically designed to allow easy deployment on HPC systems in
testing workflows, such as benchmark-driven development or continuous integration.

There are three motivations for the development of NSuite:

1. The need for a definitive resource for comparing performance and correctness of
   simulation engines on HPC systems.
2. The need to verify the performance and correctness of individual simulation engines
   as they change over time.
3. The need to test that changes to an HPC system do not cause performance or
   correctness regressions in simulation engines.

The framework currently supports the simulation engines Arbor, NEURON, and CoreNeuron,
while allowing other simulation engines to be added.

Getting Started
---------------

NSuite implements a simple workflow with two stages using bash scripts:

1. Compile and install simulation engines.
2. Run and record results from benchmarks and validation tests.

Below is the simplest example of a workflow that compiles all simulation engines
and runs benchmarks and validation tests:

.. container:: example-code

    .. code-block:: bash

        # clone the NSuite framework from GitHub
        git clone https://github.com/arbor-sim/nsuite.git
        cd nsuite/

        # install Arbor, NEURON and CoreNeuron
        ./install-local.sh arbor neuron coreneuron

        # run the ring and kway benchmarks in small configuration for Arbor, NEURON and CoreNeuron
        ./run-bench.sh arbor neuron coreneuron --model="ring kway" --config=small

        # run all validation tests for Arbor and NEURON
        ./run-validation.sh arbor neuron

HPC systems come in many different configurations, and often require a little bit
of "creativity" to install and run software.
Users of NSuite can customise the environment and how simulation engines are built
and run by providing configuration scripts, which is covered along with details
about the simulation engines in the :ref:`simulation engine documentation <engines>`.

More information about running and writing new tests can be found in the
:ref:`benchmark <benchmarks>` and :ref:`validation <validation>` documentation respectively.

Funding
-------

NSuite is developed as a joint collaboration between the Swiss National Supercomputing
Center (CSCS), and Forschungszentrum Jülich, as part of the Human Brain Project (HBP).

Development was fully funded by the European Union's Horizon 2020
Framework Programme for Research and Innovation under the Specific Grant
Agreement No. 785907 (Human Brain Project SGA2).

Contents
--------

.. toctree::

.. toctree::
   :caption: Workflow

   install
   running

.. toctree::
   :caption: Features

   benchmarks
   validation
   engines
