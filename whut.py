from mpi4py import MPI
import neuron

mpi_rank = MPI.COMM_WORLD.rank
mpi_size = MPI.COMM_WORLD.size

pc = neuron.h.ParallelContext()
nrn_rank = pc.id()
nrn_size = pc.nhost()

print('ranks', nrn_rank, mpi_rank)
print('sizes', nrn_size, mpi_size)
