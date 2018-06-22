import itertools
import random
from timeit import default_timer as timer

from mpi4py import MPI
from neuron import h
import util
from parameters import Params
from meters import Meter

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
        self.pc = h.ParallelContext()
        self.d_rank = int(pc.id())
        self.d_size = int(pc.nhost())

        self.num_cells = num_cells
        self.min_delay = min_delay
        self.fan_in = fan_in
        self.realtime_ratio = realtime_ratio
        self.frequency = frequency
        self.cells = []

        # distribute gid in round robin
        self.gids = range(self.d_rank, self.num_cells, self.d_size)

        # expected interval betwen two spikes from a cell (ms)
        interval = 1000/frequency

        # the first spike from each cell is offset ms after that
        # of the preceding cell, to give a uniform distribution of
        # spikes.
        offset = interval/num_cells

        # generate the cells
        for gid in self.gids:
            cell = BenchCell(self.realtime_ratio, gid*offset, self.frequency)

            self.cells.append(cell)

            # register this gid
            self.pc.set_gid2node(gid, self.d_rank)

            # This is the neuronic way to register a cell in a distributed context.
            # The netcon isn't meant to be used, such is the neuronic way, so we
            # hope that the gc does its job.
            nc = h.NetCon(cell.source, None)
            self.pc.cell(gid, nc) # Associate the cell with this host and gid

        self.connections = []
        for i in range(len(self.gids)):
            gid = self.gids[i]

            random.seed(gid)
            for j in range(0,self.fan_in):
                src = random.randint(0,self.num_cells-2)
                if src >= gid:
                    src = src+1

                con = self.pc.gid_connect(src, self.cells[i].source)
                con.delay = self.min_delay
                self.connections.append(con)


###########################################################
# Main Program
###########################################################

comm = MPI.COMM_WORLD

util.hoc_setup()

pc = h.ParallelContext()
pc.nthread(1)
rankd = int(pc.id())
sized = int(pc.nhost())
is_root = rankd==0
if is_root: print("=== Running benchmark with {} MPI ranks".format(sized))

params = Params('input.json')

if is_root: print("\n{}".format(params))

meters = Meter()
comm.Barrier(); meters.start()

if is_root: print('building network...')
network = Network(params.num_cells, params.min_delay, params.fan_in,
                  params.realtime_ratio, params.spike_frequency)

comm.Barrier(); meters.checkpoint('model-setup')

if is_root: print('initialize model...')
dt = params.min_delay/2; # 1 ms step time
h.dt = dt
h.steps_per_ms = 1/dt # or else NEURON might noisily fudge dt
h.tstop = params.duration
h.init()
comm.Barrier(); meters.checkpoint('model-init')

# run the simulation
if is_root: print('running model...')
h.run()
comm.Barrier(); meters.checkpoint('model-run')

if is_root: print(meters)

