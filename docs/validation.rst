.. _validation:

Validation
==================

A validation test runs a particular model, representing some physical system to
simulate, against one or more sets of parameters, and compares the output to a
reference solution. If the output deviates from the reference by more than a
given threshold, the respective test is marked as a FAIL for that simulator.
Simulator output for each model and parameter set is stored in NetCDF format,
where it can be analysed with generic tools.


