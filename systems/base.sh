### environment ###

.util/field-max() {
    local n=$1; shift
    lscpu --parse=$n | grep -v '#' | sort -n -r | head -1
}

.util/logical-cores-per-socket() {
    echo $(($(.util/field-max cpu)+1))
}

.util/cores-per-socket() {
    echo $(($(.util/field-max core)+1))
}

.util/sockets() {
    echo $(($(.util/field-max socket)+1))
}

.util/threads-per-core() {
    echo $(($(.util/logical-cores-per-socket) / $(.util/cores-per-socket)))
}

# record system name
ns_sysname="base"

# set up environment for building on the multicore part of juwels
ns_python=$(which python3)

# for (core)neuron
#module load mpi4py/3.0.1-Python-3.6.8
#module load flex/2.6.4

# for validation tests
#module load netCDF/4.6.3-serial

### compilation options ###
ns_cc=$(which mpicc)
ns_cxx=$(which mpicxx)
ns_with_mpi=ON

ns_arb_arch=native
ns_arb_branch=master

ns_makej=$(($(.util/sockets)*$(.util/logical-cores-per-socket)))

### benchmark execution options ###
ns_threads_per_core=$(.util/threads-per-core)
ns_cores_per_socket=$(.util/cores-per-socket)
ns_sockets=$(.util/sockets)
ns_threads_per_socket=$((ns_cores_per_socket*ns_threads_per_core))

# activate budget via jutil env activate -p <cproject> -A <budget> before running the benchmark
run_with_mpi() {
    export ARB_NUM_THREADS=$ns_threads_per_socket
    export OMP_NUM_THREADS=$ns_threads_per_socket
    echo srun -n$ns_sockets -N1 -c$ns_threads_per_socket "${@}"
    mpirun -n$ns_sockets -N1 -c$ns_threads_per_socket "${@}"
}
