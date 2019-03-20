.. _benchmarks:

Benchmarks
==================

For a given model and simulation engine, and benchmark is run with a "parameter sweep", for
example it is run multiple times with increasing number of cells, to understand scaling.

Benchmark output
----------------

Results form a benchmark sweep are stored in a simple file format

CSV example:

.. code-block::

    cells, compartments, time, memory, energy, name
    2,     128,          2.3,   10.7,  2.05,   ring_2
    3,     270,          4.7,   20.1,  4.1,    ring_4

JSON:

.. code-block::

