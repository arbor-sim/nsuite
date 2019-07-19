### environment ###

# record system name
ns_sysname="jureca-mc"

# set up environment for building on the multicore part of jureca
module purge
module use /usr/local/software/jureca/OtherStages/
module load Stages/2019a

module load GCC
module load ParaStationMPI
module load CMake

module load Python/3.6.8
module load SciPy-Stack/2019a-Python-3.6.8
ns_python=$(which python3)

# for (core)neuron
module load mpi4py/3.0.1-Python-3.6.8
module load flex/2.6.4

# for validation tests
module load netCDF/4.6.3

### compilation options ###
ns_cc=$(which mpicc)
ns_cxx=$(which mpicxx)
ns_with_mpi=ON

ns_arb_arch=haswell
ns_arb_branch=master

ns_makej=20

### benchmark execution options ###
ns_threads_per_core=2
ns_cores_per_socket=12
ns_sockets=2
ns_threads_per_socket=24

# activate budget via jutil env activate -p <cproject> -A <budget> before running the benchmark
run_with_mpi() {
    export ARB_NUM_THREADS=$ns_threads_per_socket
    export OMP_NUM_THREADS=$ns_threads_per_socket
    echo srun -n$ns_sockets -N1 -c$ns_threads_per_socket "${@}"
    srun -n$ns_sockets -N1 -c$ns_threads_per_socket "${@}"
}
