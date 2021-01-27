Model cable-steadystate
=======================

Simulates a passive cable with the same electrical characteristics (excluding
reversal potential) as the Rallpack1 model (see [@bhalla1992]). The simulation
is run for 20·τ where τ is the electrical time constant, in order to reach
steady state.

The electrical parameters are as follows:

| Parameter                      | Value     |
|--------------------------------|-----------|
| Cable diameter                 | 1.0 µm    |
| Cable length                   | 1.0 mm    |
| Membrane resistivity           | 4.0 Ω m²  |
| Membrane specific capacitiance | 0.01 F/m² |
| Membrane reversal potential    | 0.0 mV  |
| Injected current               | 0.1 nA    |

The initial membrane voltage is the reversal potential.

Test parameters
---------------


| Parameter | Interpretation |
|-----------|----------------|
| `dt`      | maximum simulation integration timestep [ms] |
| `d0`      | diameter at left end of cable [µm] |
| `d1`      | diameter at right end of cable [µm] |
| `n`       | number of compartments/control volumes |


Acceptance critera
------------------

The computed membrane voltages at the end of the simulation period
are compared against the steady state analytic solution at
the centre of each control volume/compartment.

The result is accepted if the maximum relative error is less than 0.1%.

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
