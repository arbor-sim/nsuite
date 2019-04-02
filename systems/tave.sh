### environment ###

# set up environment for building on the multicore part of daint

[ "$PE_ENV" = "CRAY" ] && module swap PrgEnv-cray PrgEnv-gnu
export PATH="/users/bcumming/cmake/cmake-3.13.0-rc1/bin:$PATH"

# PyExtensions is needed for cython, mpi4py and others.
# It loads cray-python/3.6.5.1
module load cray-python/3.6.5.1
ns_python=python3

# load after python tools because easybuild...
module swap gcc/7.3.0

### compilation options ###

ns_cc=$(which cc)
ns_cxx=$(which CC)
ns_with_mpi=ON

ns_arb_arch=knl

export CRAYPE_LINK_TYPE=dynamic

ns_makej=20

### benchmark execution options ###

ns_threads_per_core=1
ns_cores_per_socket=64
ns_sockets=1
ns_threads_per_socket=64

run_with_mpi() {
    echo ARB_NUM_THREADS=$ns_threads_per_socket srun -n $ns_sockets -c $ns_threads_per_socket "${@}" 
    ARB_NUM_THREADS=$ns_threads_per_socket srun -n $ns_sockets -c $ns_threads_per_socket "${@}" 
}
