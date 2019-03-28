Model rc-expsyn
===============

The model describes a single compartment cell with passive dynamics and
a single exponential synapse, that is triggered at time t = 0.

This is equivalent to an RC circuit with an exponentially decaying
current source.

The fixed electrical parameters are as follows:

| Parameter                  | Value   |
|----------------------------|---------|
| Total membrane resistance  | 100 MΩ  |
| Total membrane capacitance | 0.01 nF |
| Reversal potential         | -65 mV  |
| Initial membrane voltage   | -65 mV  |
| Synaptic time constant     | 1 ms    |

Test parameters
---------------


| Parameter | Interpretation |
|-----------|----------------|
| `dt`      | maximum simulation integration timestep [ms] |
| `g0`      | synaptic current at time _t_ = 0 [µS] |


Acceptance critera
------------------

The relative error in membrane voltage should be within 1% of
the reference value at time _t_ = 10 ms.

