### environment ###

# record system name
ns_sysname="juwels-gpu"

# set up environment for building on the booster part of juwels
ml CMake/3.21.1 Python/3.9.6 NVHPC/22.1 ParaStationMPI/5.5.0-1
ml Python/3.9.6 mpi4py/3.1.3

ns_validate=disable

ns_python=$(which python3)
ns_cc=$(which mpicc)
ns_cxx=$(which mpicxx)
ns_with_mpi=ON

ns_arb_gpu=cuda
ns_arb_vectorize=ON
ns_arb_arch=native

ns_arb_branch=master

ns_makej=20

ns_threads_per_core=2
ns_cores_per_socket=24
ns_sockets=2
ns_threads_per_socket=24

# activate budget via jutil env activate -p <cproject> -A <budget> before running the benchmark
run_with_mpi() {
    export ARB_NUM_THREADS=$ns_threads_per_socket
    export OMP_NUM_THREADS=$ns_threads_per_socket
    echo srun -n$ns_sockets -N1 -c$ns_threads_per_socket "${@}"
    srun -n$ns_sockets -N1 -c$ns_threads_per_socket "${@}"
}
