usage() {
    cat <<_end_
Usage: run-bench.sh [OPTIONS] SIMULATOR

Run NSuite benchmarks for SIMULATOR.

Options:
    --prefix=PATH    Use PATH as base for working directories.
    --model=MODEL    Run benchmark MODEL.
    --config=CONFIG  Run benchmarks with configuration CONFIG.
    SIMULATOR        One of: arbor, neuron, or coreneuron.

--model and --config can be supplied multiple times. If omitted, the ring
benchmark will be run with the small configuration.
_end_

    exit 1;
}

# Determine NSuite root and default ns_prefix.

unset CDPATH
ns_base_path=$(cd "${BASH_SOURCE[0]%/*}"; pwd)
ns_prefix=${NS_PREFIX:-$(pwd)}

# Parse arguments.

run_arb=false
run_nrn=false
run_corenrn=false

while [ "$1" != "" ]
do
    case $1 in
        arbor )
            run_arb=true
            ;;
        neuron )
            run_nrn=true
            ;;
        coreneuron )
            run_corenrn=true
            ;;
        --prefix=* )
            ns_prefix="${1#--prefix=}"
            ;;
        --prefix )
            shift
            ns_prefix=$1
            ;;
        --model )
            shift
            models="$models $1"
            ;;
        --model=* )
            models="$models ${1#--model=}"
            ;;
        --model )
            shift
            models="$models $1"
            ;;
        --config=* )
            configs="$configs ${1#--config=}"
            ;;
        --config )
            shift
            configs="$configs $1"
            ;;
        * )
            echo "unknown option '$1'"
            usage
    esac
    shift
done

models=${models:-ring}
configs=${configs:-small}

# Load utility functions and set up default environment.

source "$ns_base_path/scripts/util.sh"
mkdir -p "$ns_prefix"
ns_prefix=$(full_path "$ns_prefix")

source "$ns_base_path/scripts/environment.sh"
default_environment

# Check simulator installation status.

if [ "$run_arb" == "true" ]; then
    [ ! -f "$ns_prefix/config/env_arbor.sh" ] &&  err "Arbor must be installed to run Arbor benchmarks." && run_arb=false
fi
if [ "$run_nrn" == "true" ]; then
    [ ! -f "$ns_prefix/config/env_neuron.sh" ] &&  err "NEURON must be installed to run NEURON benchmarks." && run_nrn=false
fi
if [ "$run_corenrn" == "true" ]; then
    [ ! -f "$ns_prefix/config/env_coreneuron.sh" ] &&  err "CoreNeuron must be installed to run CoreNeuron benchmarks." && run_corenrn=false
fi

# TODO: this has to go into the configuration environment setup scripts
export ARB_NUM_THREADS=$[ $ns_threads_per_core * $ns_cores_per_socket ]

msg "---- Platform ----"
msg "platform:          $ns_system ($(uname -or))"
msg "cores per socket:  $ns_cores_per_socket"
msg "threads per core:  $ns_threads_per_core"
msg "threads:           $ARB_NUM_THREADS"
msg "sockets:           $ns_sockets"
msg "mpi:               $ns_with_mpi"
echo

msg "---- Application ----"
msg "Arbor:      $run_arb"
msg "NEURON:     $run_nrn"
msg "CoreNeuron: $run_corenrn"
echo

msg "---- Benchmarks ----"
echo

mkdir -p "$ns_input_path"
for model in $models
do
    model_config_path="$ns_base_path/benchmarks/models/$model"

    cd "$model_config_path"

    for config in $configs
    do

        msg $model-$config
        echo

        model_input_path="$ns_input_path/benchmarks/$model/$config"
        model_output_path="$ns_benchmark_output/$model/$config"

        ./config.sh $config "$ns_base_path" "$model_input_path" "$model_output_path" "$ns_prefix"

        # todo: hoist check for env file outside loop, which would unset any simulation engine that has not been installed
        if [ "$run_arb" == "true" ]; then
            msg "  arbor"
            "$model_input_path/run_arb.sh"
        fi
        if [ "$run_nrn" == "true" ]; then
            msg "  neuron"
            "$model_input_path/run_nrn.sh"
        fi
        if [ "$run_corenrn" == "true" ]; then
            msg "  coreneuron"
            "$model_input_path/run_corenrn.sh"
        fi
    done
done
