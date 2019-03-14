Placeholder doc: expand and move to nsuite docs.

* Model comprises two cells, each with a single compartment
soma and passive channels together with a double-exponential
synapse.
* The synpase on the first cell is triggered at t = 0.
* The synapse on the second cell is triggered by a spike generated
on the first cell via a connection with configurable delay.
* Times to first threshold crossing (spike) on each cell is recorded.

Pass criterion: checks difference in spike times against
a supplied `max_error` parameter, which hand-wavingly is
set to three times dt. (Realistically, the pass criterion
should be more relaxed.)

