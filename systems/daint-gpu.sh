### environment ###

# record system name
ns_sysname="daint-gpu"

# set up environment for building on the multicore part of daint

[ "$PE_ENV" = "CRAY" ] && module swap PrgEnv-cray PrgEnv-gnu
module load daint-gpu
module load CMake

module load cudatoolkit/9.2.148_3.19-6.0.7.1_2.1__g3d9acc8
module load cray-hdf5 cray-netcdf

module load cray-python/3.6.5.1
ns_python=python3

# load after python because easybuild...
module swap gcc/6.2.0

# add mpi4py to virtualenv build
export MPICC="$(which cc)"
ns_pyvenv_modules+=" Cython>=0.28 mpi4py>=3.0"

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
ns_threads_per_socket=12

run_with_mpi() {
    export ARB_NUM_THREADS=$ns_threads_per_socket
    export OMP_NUM_THREADS=$ns_threads_per_socket
    echo srun -Cgpu -n$ns_sockets -N1 -c $ns_threads_per_socket "${@}"
    srun -Cgpu -n$ns_sockets -N1 -c $ns_threads_per_socket "${@}"
}
