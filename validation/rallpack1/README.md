Model rallpack1
================

The model comprises the Rallpack 1 test from [@bhalla1992], viz.
a constant-radius cable with passive dynamics and a constant
current injection at one end.

The electrical parameters are as follows:

| Parameter                      | Value     |
|--------------------------------|-----------|
| Cable diameter                 | 1.0 µm    |
| Cable length                   | 1.0 mm    |
| Membrane resistivity           | 4.0 Ω m²  |
| Membrane specific capacitiance | 0.01 F/m² |
| Membrane reversal potential    | -65.0 mV  |
| Injected current               | 0.1 nA    |

The initial membrane voltage is the reversal potential.

Rallpack 1 specifies that the discretization has 1000 compartments,
which is interpreted as 1000 CVs for Arbor.


Test parameters
---------------


| Parameter | Interpretation |
|-----------|----------------|
| `dt`      | maximum simulation integration timestep [ms] |
| `x0`      | first measurement point (proportional distance) |
| `x1`      | second measurement point (proportional distance) |
| `n`       | number of compartments/control volumes |


Acceptance critera
------------------

The simulated membrane voltages at x0 and x1 are compared against the analytic
solution from t = 0 to t = 250 ms. The relative error is computed as
the RMS error over time, divided by the maximum absolute value of
the voltage at that point over the simulation time interval.

The result is accepted if both relative RMS errors are less than 0.1%.

Implementation notes
--------------------

### NEURON

Supported tags:
* `firstorder`

  Use first order integrator instead of default second order.

---
references:
- id: bhalla1992
  type: article-journal
  author:
  - { family: Bhalla, given: Upinder S. }
  - { family: Bilitch, given: David H. }
  - { family: Bower, given: James M. }
  issued: { raw: "1992-11" }
  title: 'Rallpacks: A set of benchmarks for neuronal simulators'
  container-title: Trends in Neurosciences
  page: 453–458
  volume: 15
  issue: 11
  DOI: 10.1016/0166-2236(92)90009-W
...
