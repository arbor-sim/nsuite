source ./util.sh

load_modules()
{
    msg "set up environment"

    if [ $PE_ENV = "CRAY" ]
    then
        echo "loading GNU programming model"
        module swap PrgEnv-cray PrgEnv-gnu
    fi
    module load daint-mc
    module load cray-python/2.7.13.1
    module load PyExtensions/2.7.13.1-CrayGNU-17.08 # for cython
    # load after python tools because easybuild...
    module swap gcc/7.2.0

    export CC=`which cc`; export CXX=`which CC`
    export CRAYPE_LINK_TYPE=dynamic
}

