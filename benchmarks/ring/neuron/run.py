from matplotlib import pyplot
import random
from mpi4py import MPI
from neuron import h
import util
from meters import Meter
import cell
import parameters

# Helper that records and outputs spikes from a simulation
class spike_record:
    def __init__(self):
        self.times = h.Vector()
        self.ids = h.Vector()
        self.pc = h.ParallelContext()
        self.pc.spike_record(-1, self.times, self.ids)

    def size(self):
        return len(self.times)

    def print(self, fname):
        rank = int(self.pc.id())
        nhost = int(self.pc.nhost())

        self.pc.barrier()

        if rank == 0:
            f = open(fname, 'w')
            f.close()

        num_spikes = int(self.pc.allreduce(self.size(), 1))
        if rank==0:
            print('There were % spikes.'%num_spikes)

        for r in range(nhost):
            if r == rank:
                f = open(fname, 'a')
                for i in range(self.size()):
                    f.write('%d %f\n' % (self.ids[i], self.times[i]))
                f.close()
            pc.barrier()

# A Ring network
class ring_network:
    def __init__(self, num_cells, min_delay, cell_params):
        self.pc = h.ParallelContext()
        self.d_rank = int(pc.id())
        self.d_size = int(pc.nhost())

        self.num_cells = num_cells
        self.min_delay = min_delay
        self.cell_params = cell_params
        self.cells = []

        # distribute gid in round robin
        self.gids = range(self.d_rank, self.num_cells, self.d_size)

        # generate the cells
        for gid in self.gids:
            c = cell.branchy_cell(gid, self.cell_params)

            self.cells.append(c)

            # register this gid
            self.pc.set_gid2node(gid, self.d_rank)

            # This is the neuronic way to register a cell in a distributed
            # context. The netcon isn't meant to be used, so we hope that the
            # garbage collection does its job.
            nc = h.NetCon(c.soma(0.5)._ref_v, None, sec=c.soma)
            nc.threshold = 10
            self.pc.cell(gid, nc) # Associate the cell with this host and gid

        total_comp = 0
        total_seg = 0
        for c in self.cells:
            total_comp += c.ncomp
            total_seg += c.nseg

        print('cell stats: {} cells; {} segments; {} compartments.'.format(num_cells, total_seg, total_comp))

        # Generate the connections.
        # For each local gid, make an incoming connection with source at gid-1.
        self.connections = []
        for i in range(len(self.gids)):
            gid = self.gids[i]

            src = (gid-1) % self.num_cells

            con = self.pc.gid_connect(src, self.cells[i].synapse)
            con.delay = self.min_delay
            con.weight[0] = 0.01
            self.connections.append(con)

        # attach a stimulus to gid 0
        if self.gids[0]==0:
            self.stim = h.NetStim()
            self.stim.number = 1
            self.stim.start = 0
            self.stim_connection = h.NetCon(self.stim, self.cells[0].synapse)
            self.stim_connection.delay = 1
            self.stim_connection.weight[0] = 0.01

# hoc setup
util.hoc_setup()

# set up the MPI infrastructure
comm = MPI.COMM_WORLD
pc = h.ParallelContext()
pc.nthread(4)
rankd = int(pc.id())
sized = int(pc.nhost())
is_root = rankd==0
if is_root: print("=== Running benchmark with {} MPI ranks".format(sized))

#
# set up model parameters
#

do_plot = False

params = parameters.model_parameters('ring.json')
print(params)

# start meters
meters = Meter()
comm.Barrier(); meters.start()

# build the model
model = ring_network(params.num_cells, params.min_delay, params.cell)

# it is a mystery to me what this actually does, but it has gotta get done.
local_minimum_delay = pc.set_maxstep(params.min_delay)

if do_plot and is_root:
    soma_voltage, dend_voltage, time_points = model.cells[0].set_recorder()

####################################################################
# initialize the model
####################################################################

# set up spike output
spikes = spike_record()

h.stdinit()

comm.Barrier(); meters.checkpoint('model-init')

# run the simulation
if is_root: print('running model...')
h.dt = 0.025
pc.psolve(params.duration)
comm.Barrier(); meters.checkpoint('model-run')

if is_root: print(meters)

spikes.print('spikes.gdf')

if do_plot and is_root:
    soma_plot = pyplot.plot(time_points, soma_voltage, color='black')
    dend_plot = pyplot.plot(time_points, dend_voltage, color='red')
    pyplot.legend(soma_plot + dend_plot, ['soma', 'dend(0.5)'])
    pyplot.xlabel('time (ms)')
    pyplot.show()
