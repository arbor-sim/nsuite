### environment ###

# Configuration for GPU support for CoreNEURON on Daint-GPU.
# CoreNEURON uses the PGI compiler for OpenACC support, so we make a special
# case for it, because we don't use PGI for any other simulators.

# record system name
ns_sysname="daint-gpu"

# set up environment for building on the multicore part of daint

module load daint-gpu
module load CMake

module load cudatoolkit/9.2.148_3.19-6.0.7.1_2.1__g3d9acc8
module load cray-hdf5 cray-netcdf

# PyExtensions is needed for cython, mpi4py and others.
# It loads cray-python/3.6.5.1 which points python at version 3.6.1.1
module load cray-python/3.6.5.1
ns_python=python3

# load PrgEnv-pgi after loading python module, because PyExtensions reloads PrgEnv-gnu, because... well, why not?
pe_env=$(echo $PE_ENV | tr '[:upper:]' '[:lower:]')
module swap PrgEnv-$pe_env PrgEnv-pgi

# load after python tools because easybuild...
module load gcc/6.2.0

# add mpi4py to virtualenv build
export MPICC="$(which cc)"
ns_pyvenv_modules+=" Cython>=0.28 mpi4py>=3.0"

### compilation options ###

ns_cc=$(which cc)
ns_cxx=$(which CC)
ns_with_mpi=ON

export CRAYPE_LINK_TYPE=dynamic

ns_makej=20

### CoreNeuron options
ns_cnrn_gpu=true
ns_cnrn_compiler_flags="-O2 -ta=tesla:cuda9.2"

### benchmark execution options ###

ns_threads_per_core=1
ns_cores_per_socket=12
ns_sockets=1
ns_threads_per_socket=12

run_with_mpi() {
    export ARB_NUM_THREADS=$ns_threads_per_socket
    export OMP_NUM_THREADS=$ns_threads_per_socket
    echo srun -Cgpu -n$ns_sockets -N1 -c$ns_threads_per_socket "${@}"
    srun -Cgpu -n$ns_sockets -N1 -c$ns_threads_per_socket "${@}"
}
