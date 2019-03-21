#!/usr/bin/env bash

# Common set-up for validation models.

# Requires PATH, PYTHONPATH and LD_LIBRARY_PATH to be already configured
# for installed and common binaries, scripts and libraries.
#
# The following nsuite working paths are also required:
#     ns_validation_output
#     ns_cache_path

function die {
    echo "$@" >&2; exit 1
}

# Sets model_name, model_sim and model_param from arguments, provided in
# this order.
#
# Creates if required output dir and cache dir.
#
# Sets variables model_output_dir, model_cache_dir, model_param_data
# and model_status_path.

function model_setup {
    if [ -z "$ns_validation_output" -o -z "$ns_cache_path" ]; then
        echo "error: missing required ns_ path variables"
        exit 1
    fi

    model_name="$1"

    model_refresh=""
    if [ "$2" = "-r" ]; then model_refresh="-r"; shift; fi

    model_sim="$2"
    model_param="$3"

    model_cache_dir="$ns_cache_path/$model_name"
    mkdir -p "$model_cache_dir" || die "$model_name: cannot create directory '$model_cache_dir'"

    local -a fmtkeys
    fmtkeys=("T=$ns_timestamp" "S=$ns_sysname" "s=$model_sim" "m=$model_name" "p=$model_param")
    fmtkeys+=("H=$(git-repo-hash)" "h=$(git-repo-hash --short)")

    model_output_dir=$(pathsub --base="$ns_validation_output" "${fmtkeys[@]}" -- "${ns_validation_output_format:-%s/%m/%p}")

    mkdir -p "$model_output_dir" || die "$model_name: cannot create directory '$model_output_dir'"

    model_status_path="$model_output_dir/status"

    [ -r "${model_param}.param" ] || die "$model_name: unable to read parameter data '${pset}.param'"
    model_param_data=$(< ${model_param}.param)
}

# Print path to file if in CWD, or else relative to cache dir.
# Return non-zero if not in cache dir either.

function model_find_cacheable {
    file="$1"
    if [ -r "./$file" ]; then
               echo "$file"
        return 0
    else 
        local cached="$model_cache_dir/$file"
        echo "$cached"
        return $([ -e "$cached" ])
    fi
}

# Report pass/fail status to stdout based on argument,
# zero => pass; non-zero => fail.

function model_notify_pass_fail {
    local white=$'\033[1;37m'
    local green=$'\033[1;92m'
    local light_red=$'\033[1;31m'
    local nc=$'\033[0m'

    if [ "$1" -eq 0 ]; then
        echo "${green}[PASS]${nc} $model_sim $model_name/$model_param"
    else
        echo "${light_red}[FAIL]${nc} $model_sim $model_name/$model_param"
    fi
}

