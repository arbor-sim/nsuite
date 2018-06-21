import itertools
import random
from timeit import default_timer as timer
from neuron import h
import util

class BenchCell:
    _ids = itertools.count(0)

    def __repr__(self):
        return 'cell_%d' % self.id

    def __init__(self, rate, first, frequency):
        self.id = next(self._ids)

        self.soma = h.Section(name='soma', cell=self)
        self.rate = rate
        self.first = first
        self.frequency = frequency

        self.source = h.bench(self.soma(0.5))
        self.source.rate = self.rate
        self.source.first = self.first
        self.source.frequency = self.frequency


class Network:
    def __init__(self, num_cells, min_delay, fan_in, realtime_ratio, frequency):
        self.num_cells = num_cells
        self.mindelay = min_delay
        self.fan_in = fan_in
        self.realtime_ratio = realtime_ratio
        self.frequency = frequency
        self.cells = []

        # expected interval betwen two spikes from a cell (ms)
        interval = 1000/frequency
        # the first spike from each cell is offset ms after that
        # of the preceding cell, to give a uniform distribution of
        # spikes.
        offset = interval/num_cells

        # generate the cells
        for i in range(self.num_cells):
            self.cells.append(BenchCell(self.realtime_ratio, i*offset, self.frequency))

        self.connections = []
        for i in range(self.num_cells):
            tgt = i

            random.seed(i)
            for j in range(0,self.fan_in):
               src = random.randint(0,self.num_cells-2)
               if src >= i:
                   src = src+1

               con = h.NetCon(self.cells[src].source, self.cells[tgt].source, 1, min_delay, 1)
               self.connections.append(con)


###########################################################
# Main Program
###########################################################

util.hoc_setup()

params = util.Params('input.json')
print(""""params)

start_setup = timer()

print('building network...')
network = Network(params.num_cells, params.min_delay, params.fan_in, params.realtime_ratio, params.spike_frequency)
print('  network built\n')

dt = params.min_delay/2; # 1 ms step time
h.dt = dt
h.steps_per_ms = 1/dt # or else NEURON might noisily fudge dt
h.tstop = params.duration

end_setup = timer()

print('initialize model...')
start_init = timer()
h.init()
end_init = timer()
print('  model initialized\n')

# run the simulation with a timer
print('running model...')
start_sim = timer()
h.run()
end_sim = timer()
print('  model run\n')

time_sim = end_sim - start_sim
time_setup = end_setup - start_setup
time_init = end_init - start_init

expected_time = params.duration*params.realtime_ratio * 1e-3 * params.num_cells
overhead = abs(time_sim-expected_time)
percent = overhead/expected_time*100

s = "         == Timings ==\n\n" \
    "  model-setup  : {0:12.4f} s\n" \
    "  model-init   : {1:12.4f} s\n" \
    "  model-run    : {2:12.4f} s\n" \
    "  overheads    : {3:12.2f} %\n" \
    .format(time_setup, time_init, time_sim, percent)
print(s)

