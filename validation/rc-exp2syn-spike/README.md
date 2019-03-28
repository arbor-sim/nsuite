Model rc-exp2syn-spike
======================

This model comprises a single source cell connected to a number of
target cells via a range of delays.

Each cell has a single compartment with passive dynamics and a
single double exponential synapse. The source cell, with label
zero, has the synapse triggered at time _t_ = 0.

When a cell membrane potential crosses the threshold value, it
will generate a spike; the spike from the source cell is
delivered to the target cell _k_ with quasirandom delay
_d_ = _d₀_ + { _k_ φ }, where φ = (√ 5 − 1)/2.

Each cell is equivalent to an RC circuit with two exponentially
decaying current sources of opposite sign and different time
constants.

The fixed electrical parameters are as follows:

| Parameter                  | Value   |
|----------------------------|---------|
| Total membrane resistance  | 100 MΩ  |
| Total membrane capacitance | 0.01 nF |
| Reversal potential         | -65 mV  |
| Initial membrane voltage   | -65 mV  |
| Synaptic time constants    | 0.5 ms  |
|                            | 4.0 ms  |

Test parameters
---------------


| Parameter   | Interpretation                                      |
|-------------|-----------------------------------------------------|
| `dt`        | maximum simulation integration timestep [ms]        |
| `g0`        | initial current of exponential current sources [µS] |
| `mindelay`  | minimum connection delay _d₀_ [ms]                  |
| `threshold` | spiking threshold [mV]                              |
| `ncell`     | total number of cells (including source)            |
| `max_error` | acceptance threshold for spike time differences     |

Acceptance critera
------------------

The recorded spike times from each cell should differ from the
reference times by at most 3·_dt_. (This is set explicitly as
the `max_error` test parameter.)
