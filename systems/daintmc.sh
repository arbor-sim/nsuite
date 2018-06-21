# set up environment for building on the multicore part of daint

if [ $PE_ENV = "CRAY" ]
then
    echo "loading GNU programming model"
    module swap PrgEnv-cray PrgEnv-gnu
fi
module load daint-mc

# PyExtensions is needed for cython.
# It loads cray-python/3.6.1.1 which points python at version 3.6.1.1
module load PyExtensions/3.6.1.1-CrayGNU-17.08

# load after python tools because easybuild...
module swap gcc/7.2.0

export CC=`which cc`; export CXX=`which CC`
export CRAYPE_LINK_TYPE=dynamic

export with_mpi=true
