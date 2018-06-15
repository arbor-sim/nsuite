import sys
import os
from timeit import default_timer as timer
from neuron import h

# This is super annoying: without neuron.gui, need
# to explicit load 'standard' hoc routines like 'run',
# but this is chatty on stdout, which means we get
# junk in our data if capturing output.

def hoc_setup():
    with open(os.devnull, 'wb') as null:
        fd = sys.stdout.fileno()
        keep = os.dup(fd)
        sys.stdout.flush()
        os.dup2(null.fileno(), fd)

        h('load_file("stdrun.hoc")')
        sys.stdout.flush()
        os.dup2(keep, fd)

hoc_setup()

ncells = 2
cells=[]
for i in range(ncells):
    print('making cell ', i)
    cell = h.Section(name='soma')
    bench = h.bench(cell(0.5))
    bench.rate = 1
    cells.append(cell)

dt = 10; # 1 ms step time

h.dt = dt
h.steps_per_ms = 1/dt # or else NEURON might noisily fudge dt

h.tstop = 20 # 1 second of simulation per cell

start = timer()

h.run()

end = timer()
time_taken = end - start
expected_time = h.tstop/bench.rate * 1e-3
print()
print('took ', time_taken, ' seconds: ', time_taken-expected_time, ' overhead')

