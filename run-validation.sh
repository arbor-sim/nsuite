#!/usr/bin/env bash

usage() {
    cat <<_end_
Usage: run-validation.sh [OPTIONS] SIMULATOR [SIMULATOR...]

Options:
    -h, --help                 Print this help message and exit.
    --prefix=PREFIX            Use PATH as base for working directories.
    -o, --output=FORMAT        Override default path to validation outputs.
    -l, --list-models          List available model/parameter tests.
    -r, --refresh              Regenerate any cached reference data.
    -m, --model=MODEL/[PARAM]  Run given model/parameter test.

SIMULATOR is one of: arbor, neuron
If no model is explicitly provided, all available tests will be run.

The output FORMAT is a pattern that is used to determine the output
directory for any given simulator, model and parameter set. If the
resulting path is not absolute, it will be taken relative to
the path PREFIX/output/validation.

Fields in FORMAT are substituted as follows:

  %T    Timestamp of invocation of install-local.sh.
  %H    Git commit hash of nsuite (with + on end if modified).
  %h    Git commit short hash of nsuite (with + on end if modified).
  %S    System name (if defined in system environment script) or host name.
  %s    Simulator name.
  %m    Model name.
  %p    Parameter set name.
  %%    Literal '%'.

If no --output option is provided, the default FORMAT %s/%m/%p is used.
_end_
    exit 0;
}

argerror() {
    cat >&2 <<_end_
run-validation.sh: $1
Try 'run-validation.sh --help' for more information.
_end_
    exit 1
}

# Determine NSuite root and default ns_prefix.

unset CDPATH
ns_base_path=$(cd "${BASH_SOURCE[0]%/*}"; pwd)
ns_prefix=${NS_PREFIX:-$(pwd)}

# Parse arguments.

sims=""
models=""
all_models=""

shopt -s nullglob

for modeldir in "$ns_base_path/validation/"*; do
    if [ -x "$modeldir/run" ]; then
        m=$(basename "$modeldir")
        model_add=""
        for paramfile in "$modeldir"/*.param; do
            model_add="$model_add $m/$(basename "$paramfile" .param)"
        done
        all_models="$all_models $model_add"
    fi
done

unset ns_refresh_cache
unset ns_validation_output_format

while [ -n "$1" ]; do
    case $1 in
        -h | --help )
            usage
            ;;
        -l | --list-models )
            for m in $all_models; do echo $m; done
            exit 0
            ;;
        --prefix=* )
            ns_prefix="${1#--prefix=}"
            ;;
        --prefix )
            shift
            ns_prefix=$1
            ;;
        --output=* )
            ns_validation_output_format="${1#--output=}"
            ;;
        -o | --output )
            shift
            ns_validation_output_format=$1
            ;;
        --model=* )
            models="$models ${1#--model=}"
            ;;
        -m | --model )
            shift
            models="$models $1"
            ;;
        -r | --refresh )
            ns_refresh_cache="-r"
            ;;
        neuron )
            sims="$sims neuron"
            ;;
        arbor )
            sims="$sims arbor"
            ;;
        * )
            argerror "unknown option '$1'"
    esac
    shift
done

[ -z "$models" ] && models="$all_models"

# Load utility functions and set up default environment.

source "$ns_base_path/scripts/util.sh"
mkdir -p "$ns_prefix"
ns_prefix=$(full_path "$ns_prefix")

source "$ns_base_path/scripts/environment.sh"
default_environment
export ns_validation_output_format

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

msg "---- Validation ----"
echo

for sim in $sims; do
    sim_env="$ns_prefix/config/env_$sim.sh"
    if [ ! -f "$sim_env" ]; then
        echo "Simulator $sim has not been locally installed, skipping."
        continue
    fi

    echo "Running validation for $sim:"

    for model in $models; do
        param=""
        if [[ ! "$model" == */* ]]; then
            model="$model/default"
        fi
        param="${model#*/}"
        basemodel="${model%/*}"

        model_path="$ns_base_path/validation/$basemodel"
        if [ ! -x "$model_path/run" ]; then
            echo "Missing run file for model $basemodel, skipping."
            continue
        fi

        if [ ! -r "$model_path/$param.param" ]; then
            echo "Missing parameter file $param.param for model $basemodel, skipping."
            continue
        fi

        (
          source "$sim_env";
          "$model_path/run" $ns_refresh_cache "$sim" "$param"
        )
    done
done
