.. _engines:

Simulation Engines
==================

A simulation engine is a library or application for simulating multi-compartment
neural network models.

Supported simulation engines
----------------------------

NSuite supports three simulation engines: Arbor, NEURON and CoreNeuron. Each benchmark and validation
test is implemented for each supported engine where possible

.. table:: Default versions of each supported simulation engine

   =========== ======== ============== ====================================
   Engine       Version  Kind          Source
   =========== ======== ============== ====================================
   Arbor        0.2      git tag       GitHub `arbor-sim/arbor <https://github.com/arbor-sim/arbor>`_
   NEURON       7.6      tar ball      FTP `neuron.yale.edu <https://neuron.yale.edu/ftp/neuron/versions/>`_
   CoreNeuron   0.13     git tag       GitHub `BlueBrain/CoreNeuron <https://github.com/BlueBrain/CoreNeuron>`_
   =========== ======== ============== ====================================

Arbor
"""""

Brief description of Arbor.

NEURON
"""""""

Brief description of NEURON.

CoreNeuron
"""""""""""

Brief description of CoreNeuron.

Adding support for a new simulation engine
------------------------------------------

List of features required for inclusion

.. Note::
   If a simulation engine doesn't suport a feature required to run a test,
   the test will be skipped. For example, the only simulation output
   provided by CoreNeuron is spike times, so validation tests that require
   other information such as voltage traces are not supported.

because bash is supported everywhere, because bash is
used by continuous integration systems like (Travis) and (Jenkins), and because
NSuite does not require anything more sophisticated.
