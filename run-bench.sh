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

# try to auto-detect the number of cores/sockets
default_hardware

msg "---- PLATFORM ----"
msg "platform:          $ns_system ($(uname -or))"
msg "cores per socket:  $ns_cores_per_socket"
msg "threads per core:  $ns_threads_per_core"
msg "sockets:           $ns_sockets"
msg "mpi:               $ns_with_mpi"

#[ "$ns_bench_arbor"  = true ] && echo && source "$ns_base_path/benchmarks/arbor.sh"
#[ "$ns_bench_neuron" = true ] && echo && source "$ns_base_path/benchmarks/neuron.sh"

echo $PYTHONPATH

cd $ns_base_path/benchmarks/ring/neuron
python run.py

