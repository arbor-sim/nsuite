### environment ###

# record system name
ns_sysname="GH"

### compilation options ###
# -DPYTHON_EXECUTABLE=/usr/local/bin/python3.8
ns_cc="gcc"
ns_cxx="g++"
ns_with_mpi=OFF
ns_arb_arch=native
ns_arb_gpu=none

ns_arb_git_repo='https://github.com/arbor-sim/arbor.git'
ns_arb_branch='master'

ns_makej=4

### benchmark execution options ###
ns_threads_per_core=2
ns_cores_per_socket=12
ns_sockets=1
ns_threads_per_socket=2

run_with_mpi() {
    export ARB_NUM_THREADS=$ns_threads_per_socket
    export OMP_NUM_THREADS=$ns_threads_per_socket
    echo ${@}
    ${@}
}
