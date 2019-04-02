### environment ###

# record system name
ns_sysname="jureca-gpu"

# set up environment for building on the gpu part of jureca

module use /usr/local/software/jureca/OtherStages/
module load Stages/Devel-2018b

module load CMake/3.13.0

module load GCC/7.3.0 
module load CUDA/9.2.88 
module load MVAPICH2/2.3-GDR

module load Python/3.6.6
ns_python=python3

# modules for (core)neuron
module load mpi4py/3.0.0-Python-3.6.6
module load flex/2.6.4
module load Bison/.3.1

### compilation options ###

ns_cc=$(which mpicc)
ns_cxx=$(which mpicxx)
ns_with_mpi=ON

ns_arb_with_gpu=ON
ns_arb_arch=haswell

ns_makej=20

### benchmark execution options ###

ns_threads_per_core=2
ns_cores_per_socket=12
ns_sockets=2
ns_threads_per_socket=24

# activate budget via jutil env activate -p <cproject> -A <budget> before running the benchmark
run_with_mpi() {
    echo ARB_NUM_THREADS=$ns_threads_per_socket srun -n $ns_sockets -N $ns_sockets -c $ns_threads_per_socket "${@}" 
    ARB_NUM_THREADS=$ns_threads_per_socket srun -n $ns_sockets -N $ns_sockets -c $ns_threads_per_socket "${@}" 
}
