# set up environment for building on the multicore part of daint

[ "$PE_ENV" = "CRAY" ] && module swap PrgEnv-cray PrgEnv-gnu
module load daint-mc
module load CMake

# PyExtensions is needed for cython, mpi4py and others.
# It loads cray-python/3.6.1.1 which points python at version 3.6.1.1
module load PyExtensions/3.6.1.1-CrayGNU-17.08
ns_python=$(which python3)

# load after python tools because easybuild...
module swap gcc/7.2.0

ns_cc=$(which cc)
ns_cxx=$(which CC)
ns_with_mpi=ON

ns_arb_arch=broadwell

export CRAYPE_LINK_TYPE=dynamic

ns_makej=20
