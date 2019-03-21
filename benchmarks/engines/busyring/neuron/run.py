import config
import random
env = config.load_env()

if env.mpi:
    from mpi4py import MPI
    if MPI.COMM_WORLD.rank==0:
        print(env)
else:
    print(env)

from neuron import h

import metering
import cell
import parameters
import neuron_tools as nrn

# A Ring network
class ring_network:
    def __init__(self, params):
        self.pc = h.ParallelContext()
        self.d_rank = int(self.pc.id())
        self.d_size = int(self.pc.nhost())

        self.num_cells = params.num_cells
        self.min_delay = params.min_delay
        self.cell_params = params.cell
        self.ring_size = params.ring_size
        self.synapses_per_cell = params.cell.synapses
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

        if self.d_size>1:
            from mpi4py import MPI
            total_comp = MPI.COMM_WORLD.reduce(total_comp, op=MPI.SUM, root=0)
            total_seg = MPI.COMM_WORLD.reduce(total_seg, op=MPI.SUM, root=0)

        if self.d_rank==0:
            print('cell stats: {} cells; {} segments; {} compartments; {} comp/cell.'.format(self.num_cells, total_seg, total_comp, total_comp/self.num_cells))

        # Generate the connections.
        # For each local gid, make an incoming connection with source at gid-1.
        self.connections = []
        num_local_cells = len(self.gids)
        self.stims = []
        self.stim_connections = []
        for i in range(num_local_cells):
            gid = self.gids[i]

            # attach ring connection to previous gid in local ring
            s = self.ring_size
            ring = int(gid/s)
            ring_start = s*ring;
            ring_end = min(ring_start+s, self.num_cells);
            src = gid-1
            if gid==ring_start:
                src = ring_end-1

            con = self.pc.gid_connect(src, self.cells[i].synapses[0])
            con.delay = self.min_delay
            con.weight[0] = 0.01
            self.connections.append(con)

            # Attach stimulus if cell is first in sub-ring
            if gid==ring_start:
                stim = h.NetStim()
                stim.number = 1 # one spike
                stim.start = 0  # at t=0
                stim_connection = h.NetCon(stim, self.cells[i].synapses[0])
                stim_connection.delay = 1
                stim_connection.weight[0] = 0.01
                self.stims.append(stim)
                self.stim_connections.append(stim_connection)

            # generate dummy connections with random source and zero weights.
            for sid in range(1, self.synapses_per_cell):
                src = random.randint(0, self.num_cells-2)
                if src==gid:
                    src=src+1
                delay = params.min_delay + random.uniform(0, 2*params.min_delay)
                con = self.pc.gid_connect(src, self.cells[i].synapses[sid])
                con.weight[0] = 0
                con.delay = delay
                self.connections.append(con)

# hoc setup
nrn.hoc_setup()

# create environment
ctx = nrn.neuron_context(env)
if ctx.rank==0:
    print(ctx)

meter = metering.meter(env.mpi)
meter.start()

# build the model
params = parameters.model_parameters(env.parameter_file)
if ctx.rank==0:
    print(params)
model = ring_network(params)

ctx.init(params.min_delay, params.dt)

# set up spike output
spikes = nrn.spike_record()

meter.checkpoint('model-init')

if env.dump_coreneuron:
    # The CoreNeuron model state is dumped into the input path, because
    # it is used as input for CoreNeuron.
    cnrn_output_path='%s/%s_core'%(env.ipath, params.name);
    ctx.write_core(cnrn_output_path)
    meter.checkpoint('model-output')

# run the simulation
ctx.run(params.duration)

meter.checkpoint('model-run')

meter.print()

prefix = env.opath+'/'+params.name+'_';

report = metering.report_from_meter(meter)
report.to_file(prefix+'meters.json')

spikes.print(prefix+'spikes.gdf')

