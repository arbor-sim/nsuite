Model rallpack-1
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
| `x`       | measurement point [µm] |
| `n`       | number of compartments/control volumes |


Acceptance critera
------------------

The simulated membrane voltage at x is compared
against the analytic solution from t = 0 to t = 0.25 ms.

The result is accepted if the maximum deviation is less
than 0.1% of the maximum absolute value of the voltage
over the time interval (which will be achieved at the
maximum time of the interval).

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
