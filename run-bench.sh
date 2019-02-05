usage() {
    echo
    echo "nsuite benchmark runner:"
    echo
    echo "run with one, and only one, of the following options:"
    echo "   arbor  : run arbor benchmarks"
    echo "   neuron : run neuron benchmarks"
    echo "   coreneuron : run coreneuron benchmarks"
    echo

    exit 1;
}
ns_sim=
ns_sim_set=false

# Load some utility functions.
source ./scripts/environment.sh
source ./scripts/util.sh
default_environment

# parse arguments
while [ "$1" != "" ]
do
    case $1 in
        arbor )
            [ "$ns_sim_set" = "true" ] && exit_on_error "only one simulator can be benchmarked in one run"
            ns_sim="arbor"
            ns_sim_set=true
            ;;

        neuron )
            [ "$ns_sim_set" = "true" ] && exit_on_error "only one simulator can be benchmarked in one run"
            ns_sim="neuron"
            ns_sim_set=true
            ;;

        coreneuron )
            [ "$ns_sim_set" = "true" ] && exit_on_error "only one simulator can be benchmarked in one run"
            ns_sim="coreneuron"
            ns_sim_set=true
            ;;

        * )
            echo "unknown option '$1'"
            usage
    esac
    shift
done

[ "$ns_sim_set" == "false" ] && usage;

# Load the environment used to build the simulation engines.
env_script="$ns_base_path/config/env_${ns_sim}.sh"
if [ -f "$env_script" ]; then
    msg "loading $env_script"
    source "$env_script";
    echo
else
    err "the simulation engine $ns_sim has not been installed"
    exit 1
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

msg "---- Application ----"
msg "simulation engine: $ns_sim"
echo

msg "---- Benchmarks ----"
echo

ns_ring_path="$ns_base_path/benchmarks/ring"
mkdir -p "$ns_input_path"
cd "$ns_ring_path"

# generate the inputs
$ns_python generate_inputs.py -c 10 -d 2 -n ring -s $ns_sockets -i "$ns_input_path" -o "$ns_output_path"

if [ "$ns_sim" = "arbor" ]; then
    msg Arbor ring benchmark
    source run_arb.sh
elif [ "$ns_sim" = "neuron" ]; then
    msg NEURON ring benchmark
    source run_nrn.sh
elif [ "$ns_sim" = "coreneuron" ]; then
    msg CoreNeuron ring benchmark
    source run_corenrn.sh
fi
