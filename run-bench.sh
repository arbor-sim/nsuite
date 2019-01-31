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
ns_bench_coreneuron=false

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
        coreneuron )
            ns_bench_coreneuron=true
            ;;
        all )
            ns_bench_arbor=true
            ns_bench_neuron=true
            ns_bench_coreneuron=true
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

# load user-specified environment
if [ "$ns_environment" != "" ]; then
    if [ ! -f "$ns_environment" ]; then
        err "file '$ns_environment' not found"
        exit 1
    fi
    source "$ns_environment"
fi

export ARB_NUM_THREADS=$[ $ns_threads_per_core * $ns_cores_per_socket ]

msg "---- Platform ----"
msg "configuration:     $ns_environment"
msg "platform:          $ns_system ($(uname -or))"
msg "cores per socket:  $ns_cores_per_socket"
msg "threads per core:  $ns_threads_per_core"
msg "threads:           $ARB_NUM_THREADS"
msg "sockets:           $ns_sockets"
msg "mpi:               $ns_with_mpi"
echo

msg "---- Applications ----"
msg "arbor:             $ns_bench_arbor"
msg "NEURON:            $ns_bench_neuron"
msg "CoreNeuron:        $ns_bench_coreneuron"
echo

msg "---- Benchmarks ----"
echo

ns_ring_path="$ns_base_path/benchmarks/ring"
ns_ring_in="$ns_ring_path/input"
ns_ring_out="$ns_ring_path/output"
mkdir -p "$ns_ring_in"
mkdir -p "$ns_ring_out"
rm -f "$ns_ring_in/*"
rm -f "$ns_ring_out/*"
cd "$ns_ring_path"

# generate the inputs
$ns_python generate_inputs.py -c 14 -d 4 -n ring -s $ns_sockets

if [ "$ns_bench_arbor" = "true" ]; then
    msg Arbor ring benchmark
    source run_arb.sh
fi

if [ "$ns_bench_neuron" = "true" ]; then
    msg NEURON ring benchmark
    source run_nrn.sh
fi

if [ "$ns_bench_coreneuron" = "true" ]; then
    msg CoreNeuron ring benchmark
    source run_corenrn.sh
fi

