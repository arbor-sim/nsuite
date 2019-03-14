#!/usr/bin/bash

usage() {
    cat <<_end_
Usage: run-validation.sh [OPTIONS] SIMULATOR [SIMULATOR...]

Options:
    --prefix=PREFIX            Use PATH as base for working directories.
    -l, --list-models          List available model/parameter tests.
    -r, --refresh              Regenerate any cached reference data.
    -m, --model=MODEL/[PARAM]  Run given model/parameter test.

SIMULATOR is one of: arbor, neuron
If no model is explicitly provided, all available tests will be run.
_end_
    exit 1;
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

ns_refresh_cache=""
while [ -n "$1" ]; do
    case $1 in
        -l | --list-models )
            for m in "$all_models"; do echo $m; done
            exit 0
            ;;
        --prefix=* )
            ns_prefix="${1#--prefix=}"
            ;;
        --prefix )
	    shift
            ns_prefix=$1
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
            echo "unknown option '$1'"
            usage
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
          export ns_base_path ns_prefix ns_validation_output ns_cache_path
	  "$model_path/run" $ns_refresh_cache "$sim" "$param"
        )
    done
done
