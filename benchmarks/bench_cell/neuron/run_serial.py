import itertools
import random
from timeit import default_timer as timer
from neuron import h
from parameters import Params
from meters import Meter
import util

#
#   Simple benchmark cell.
#   A single compartment with one bench point process attached.
#
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


#
#   A network of benchmark cells.
#   Random all to all network with no self-connections
#
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

               con = h.NetCon(self.cells[src].source, self.cells[tgt].source,
                              1, min_delay, 1)
               self.connections.append(con)


###########################################################
# Main Program
###########################################################

util.hoc_setup()

params = Params('input.json')
print(params)

meters = Meter()

print('building network...')
network = Network(params.num_cells, params.min_delay, params.fan_in,
                  params.realtime_ratio, params.spike_frequency)
meters.checkpoint('model-setup')

print('initializing model...')
dt = params.min_delay/2; # 1 ms step time
h.dt = dt
h.steps_per_ms = 1/dt # or else NEURON might noisily fudge dt
h.tstop = params.duration
h.init()
meters.checkpoint('model-init')

# run the simulation with a timer
print('running model...')
h.run()
meters.checkpoint('model-run')

print(meters)
