usage() {
    cat <<_end_
Usage: run-bench.sh [OPTIONS] SIMULATOR

Run NSuite benchmarks for SIMULATOR.

Options:
    --help             Print this help mesage.
    --prefix=PATH      Use PATH as base for working directories.
    --model=MODEL      Run benchmark MODEL.
    --config=CONFIG    Run benchmarks with configuration CONFIG.
    --output=FORMAT    Override default path to benchmark outputs.
    SIMULATOR          One of: arbor, neuron, or coreneuron.

--model and --config can be supplied multiple times. If omitted, the ring
benchmark will be run with the small configuration.

The output FORMAT is a pattern that is used to determine the output
directory for any given simulator, model and parameter set. If the
resulting path is not absolute, it will be taken relative to
the path PREFIX/output/benchmark.

Fields in FORMAT are substituted as follows:

  %T    Timestamp of invocation of install-local.sh.
  %H    Git commit hash of nsuite (with + on end if modified).
  %h    Git commit short hash of nsuite (with + on end if modified).
  %S    System name (if defined in system environment script) or host name.
  %s    Simulator name.
  %m    Model name.
  %p    Config name.
  %%    Literal '%'.

If no --output option is provided, the default FORMAT %m/%p/%s is used.
_end_

    exit 0
}

argerror() {
    cat >&2 <<_end_
run-bench.sh: $1
Try 'run-bench.sh --help' for more information.
_end_
    exit 1
}

# Determine NSuite root and default ns_prefix.

unset CDPATH
ns_base_path=$(cd "${BASH_SOURCE[0]%/*}"; pwd)
ns_prefix=${NS_PREFIX:-$(pwd)}

# Parse arguments.

run_arb=false
run_nrn=false
run_corenrn=false

unset ns_bench_output_format

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
        --help )
            usage
            ;;
        --prefix=* )
            ns_prefix="${1#--prefix=}"
            ;;
        --prefix )
            shift
            ns_prefix=$1
            ;;
        --output=* )
            ns_bench_output_format="${1#--output=}"
            ;;
        --output )
            shift
            ns_bench_output_format=$1
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
            argerror "unknown option '$1'"
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
export PATH="$ns_base_path/common/bin:$PATH"

# Grab timestamp and sysname from build directory for export.

ns_timestamp=$(< "$ns_build_path/timestamp")
ns_sysname=$(< "$ns_build_path/sysname")
export ns_timestamp
export ns_sysname

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
msg "platform:          $ns_system"
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


mkdir -p "$ns_bench_input_path"
for model in $models
do
    model_config_path="$ns_base_path/benchmarks/models/$model"

    cd "$model_config_path"

    for config in $configs
    do

        msg $model-$config
        echo

        model_input_path="$ns_bench_input_path/$model/$config"

        "$ns_base_path/scripts/bench_config.sh" "$model" "$config" "$ns_base_path" "$ns_config_path" "$ns_bench_input_path" "$ns_bench_output" "${ns_bench_output_format:-%m/%p/%s}"

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
