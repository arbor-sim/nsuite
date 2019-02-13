#!/usr/bin/bash

usage() {
    echo "run-validation.sh [--list-models] [--model MODEL[/PARAMSET]] SIMULATOR [SIMULATOR...]"
    echo
    echo "SIMULATOR is one of: arbor, neuron"

    exit 1;
}


# Load some utility functions.
source ./scripts/environment.sh
source ./scripts/util.sh
default_environment

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
        all_models="$models $model_add"
    fi
done

while [ -n "$1" ]; do
    case $1 in
        --list-models )
            for m in "$all_models"; do echo $m; done
            exit 0
            ;;

        --model )
            shift
            models="$models $1"
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

# TODO: this has to go into the configuration environment setup scripts
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

msg "---- Validation ----"
echo

for sim in $sims; do
    sim_env="$ns_base_path/config/env_$sim.sh"
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

        model_config_path="$ns_base_path/validation/$basemodel"
        if [ ! -x "$model_config_path/run" ]; then
            echo "Missing run file for model $basemodel, skipping."
            continue
        fi

        cd "$model_config_path"

        if [ ! -r "$param.param" ]; then
            echo "Missing parameter file $param.param for model $basemodel, skipping."
            continue
        fi

        echo "-- model $model:"

        set -x
        (
          source "$sim_env";
          export ns_base_path ns_install_path ns_output_path ns_cache_dir ns_common_dir
          ./run "$sim" "$param"
        )
    done
done
