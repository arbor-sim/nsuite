import os
import pathlib
import sys

import neuron

# Without neuron.gui, need to explicit load 'standard' hoc routines like 'run',
# but this is chatty on stdout, which means we get junk in our data if capturing
# output.
# Calling setup performs these setup steps while redirecting output to /dev/null

def hoc_setup():
    with open(os.devnull, 'wb') as null:
        fd = sys.stdout.fileno()
        keep = os.dup(fd)
        sys.stdout.flush()
        os.dup2(null.fileno(), fd)

        neuron.h('load_file("stdrun.hoc")')
        sys.stdout.flush()
        os.dup2(keep, fd)


class neuron_context:
    def __repr__(self):
        s = "-- neuron context ----------------------------\n" \
            "{0:20s}{1:>20d}\n" \
            "{2:20s}{3:>20d}\n" \
            "{4:20s}{5:>20d}\n" \
            "----------------------------------------------\n"\
            .format("threads", self.env.nthreads, "ranks", self.size, "rank", self.rank, "is_root", self.is_root)

        return s

    def __init__(self, env):
        from mpi4py import MPI

        self.env = env
        self.pc = neuron.h.ParallelContext()
        self.rank = self.pc.id()
        self.size = self.pc.nhost()
        self.pc.nthread(self.env.nthreads)
        self.is_root = self.rank==0
        self.comm = MPI.COMM_WORLD
        self.initialised = False
        # must be set to output model for coreneuron.
        neuron.h.cvode.cache_efficient(1)

    def init(self, min_delay, dt):
        # I don't know why this has to be done, but it does.
        local_minimum_delay = self.pc.set_maxstep(min_delay)
        # this initializes the neuron simulation state (I think...)
        neuron.h.stdinit()
        # this has to come after hoc stdinit call (why? not important: it makes a difference).
        neuron.h.dt = dt
        self.initialised = True

    def run(self, duration):
        if not self.initialised:
            print('ERROR: The neuron context must be initialized before a model can be run.')
        else:
            self.pc.psolve(duration)

    # dump model state for CoreNeuron here
    def write_core(self, path):
        if self.is_root:
            print('writing coreneuron model state to ', path)

            pathlib.Path(path).mkdir(parents=True, exist_ok=True)
            #for the_file in os.listdir(path):
            #    file_path = os.path.join(path, the_file)
            #    try:
            #        if os.path.isfile(file_path):
            #            os.unlink(file_path)
            #        elif os.path.isdir(file_path):
            #            shutil.rmtree(file_path)
            #    except Exception as e:
            #        print('  error: ', e)

        # MPI ranks wait for root rank to create output path before writing
        self.barrier()

        self.pc.nrnbbcore_write(path)

    def barrier(self):
        self.comm.Barrier()

# Helper that records and outputs spikes from a simulation
class spike_record:
    def __init__(self):
        self.times = neuron.h.Vector()
        self.ids = neuron.h.Vector()
        self.pc = neuron.h.ParallelContext()
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
            print('There were %d spikes.'%num_spikes)

        for r in range(nhost):
            if r == rank:
                f = open(fname, 'a')
                for i in range(self.size()):
                    f.write('%d %f\n' % (self.ids[i], self.times[i]))
                f.close()
            self.pc.barrier()

