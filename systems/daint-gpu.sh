### environment ###

# record system name
ns_sysname="daint-gpu"

# set up environment for building on the multicore part of daint

[ "$PE_ENV" = "CRAY" ] && module swap PrgEnv-cray PrgEnv-gnu
module load daint-gpu
module load CMake

module load cudatoolkit/9.2.148_3.19-6.0.7.1_2.1__g3d9acc8
module load cray-hdf5 cray-netcdf

# PyExtensions is needed for cython, mpi4py and others.
# It loads cray-python/3.6.5.1 which points python at version 3.6.1.1
module load PyExtensions/3.6.5.1-CrayGNU-18.08
ns_python=$(which python3)

# load after python tools because easybuild...
module swap gcc/6.2.0

### compilation options ###

ns_cc=$(which cc)
ns_cxx=$(which CC)
ns_with_mpi=ON

ns_arb_with_gpu=ON
ns_arb_arch=haswell

export CRAYPE_LINK_TYPE=dynamic

ns_makej=20

### benchmark execution options ###

ns_threads_per_core=2
ns_cores_per_socket=12
ns_sockets=1
ns_threads_per_socket=24

run_with_mpi() {
    echo ARB_NUM_THREADS=$ns_threads_per_socket srun -n $ns_sockets -N $ns_sockets -c $ns_threads_per_socket $*
    ARB_NUM_THREADS=$ns_threads_per_socket srun -n $ns_sockets -N $ns_sockets -c $ns_threads_per_socket $*
}
