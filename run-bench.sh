usage() {
    echo
    echo "nsuite benchmark runner:"
    echo
    echo "   arbor  : run arbor benchmarks"
    echo "   neuron : run neuron benchmarks"
    echo "   all    : run all benchmarks"
    echo "   -e filename: source filename before building"
    echo
}

# Load some utility functions.
source ./scripts/util.sh

# Set up default environment variables
default_environment

ns_bench_arbor=false
ns_bench_neuron=false

# parse arguments
while [ "$1" != "" ]
do
    case $1 in
        arbor )
            ns_bench_arbor=true
            ;;
        neuron )
            ns_bench_neuron=true
            ;;
        all )
            ns_bench_arbor=true
            ns_bench_neuron=true
            ;;
        -e )
            shift
            ns_environment=$1
            ;;
        * )
            echo "unknown option '$1'"
            usage
            exit 1
    esac
    shift
done

# set up paths for finding the libraries/executables
export PATH="${ns_install_path}/bin:${PATH}"
export PYTHONPATH="${ns_base_path}/benchmarks/common:${PYTHONPATH}"
cpath="${ns_base_path}/config"
[ -f "${cpath}/bin_path" ]    && export PATH="$(cat ${cpath}/bin_path):${PATH}"
[ -f "${cpath}/python_path" ] && export PYTHONPATH="$(cat ${cpath}/python_path):${PYTHONPATH}"

echo cpath:      $cpath
echo PTYHONPATH: $PYTHONPATH
cat ${cpath}/python_path

# try to auto-detect the number of cores/sockets
default_hardware

# load user-specified environment
if [ "$ns_environment" != "" ]; then
    msg "using additional configuration: $ns_environment"
    if [ ! -f "$ns_environment" ]; then
        err "file '$ns_environment' not found"
        exit 1
    fi
    source "$ns_environment"
    echo
fi

export ARB_NUM_THREADS=$[ $ns_threads_per_core * $ns_cores_per_socket ]

msg "---- PLATFORM ----"
msg "platform:          $ns_system ($(uname -or))"
msg "cores per socket:  $ns_cores_per_socket"
msg "threads per core:  $ns_threads_per_core"
msg "threads:           $ARB_NUM_THREADS"
msg "sockets:           $ns_sockets"
msg "mpi:               $ns_with_mpi"

#[ "$ns_bench_arbor"  = true ] && echo && source "$ns_base_path/benchmarks/arbor.sh"
#[ "$ns_bench_neuron" = true ] && echo && source "$ns_base_path/benchmarks/neuron.sh"

cd $ns_base_path/benchmarks/ring/neuron

tps=$ns_threads_per_socket
ARB_NUM_THREADS=$tps mpirun -n 1 --map-by socket:PE=$tps $ns_python run.py --mpi --dt 0.025 --duration 200
