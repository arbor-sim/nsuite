### environment ###

# record system name
ns_sysname="daint-mc"

# set up environment for building on the multicore part of daint

[ "$PE_ENV" = "CRAY" ] && module swap PrgEnv-cray PrgEnv-gnu
module load daint-mc
module load CMake

module load cray-hdf5 cray-netcdf

module load cray-python/3.6.5.1
ns_python=python3

# load after python because easybuild...
module swap gcc/7.3.0

# add mpi4py to virtualenv build
export MPICC="$(which cc)"
ns_pyvenv_modules+=" Cython>=0.28 mpi4py>=3.0"

### compilation options ###

ns_cc=$(which cc)
ns_cxx=$(which CC)
ns_with_mpi=ON

ns_arb_arch=broadwell

export CRAYPE_LINK_TYPE=dynamic

ns_makej=20

### benchmark execution options ###

ns_threads_per_core=2
ns_cores_per_socket=18
ns_sockets=2
ns_threads_per_socket=36

run_with_mpi() {
    export ARB_NUM_THREADS=$ns_threads_per_socket
    export OMP_NUM_THREADS=$ns_threads_per_socket
    echo srun -Cmc -n$ns_sockets -N1 -c$ns_threads_per_socket "${@}"
    srun -Cmc -n$ns_sockets -N1 -c$ns_threads_per_socket "${@}"
}
