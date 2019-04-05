#!/usr/bin/env bash

# Common set-up for validation models.

# Requires PATH, PYTHONPATH and LD_LIBRARY_PATH to be already configured
# for installed and common binaries, scripts and libraries.
#
# The following nsuite variables are used:
#     ns_cache_path     (required)
#     ns_cache_refresh  (optionally set)

function die {
    echo "$@" >&2; exit 1
}

function exit_model_fail { exit 96; }
function exit_model_missing { exit 97; }

# Sets model_name, model_sim and model_param from arguments, provided in
# this order.
#
# If sim has tags, remove them from model_sim, add them to model_tags array.
# Computes and sets variables model_cache_dir, model_param_data.
# Creates cache directory if not present.
#
# Sets array variable model_impl_stdargs that contains conventional arguments
# for a model implementation script, viz. --tag TAG ... KEY=VALUE ...

function model_setup {
    if [ -z "$ns_cache_path" ]; then
        echo "error: missing required ns_ path variables"
        exit 1
    fi

    model_name="$1"
    model_sim="$2"
    model_param="$3"

    IFS=':' read -r -a model_tags <<<"$model_sim"
    model_sim="${model_tags[0]}"
    model_tags=("${model_tags[@]:1}")

    model_cache_dir="$ns_cache_path/$model_name"
    mkdir -p "$model_cache_dir" || die "$model_name: cannot create directory '$model_cache_dir'"

    [ -r "${model_param}.param" ] || die "$model_name: unable to read parameter data '${pset}.param'"
    model_param_data=$(< ${model_param}.param)

    unset model_impl_stdargs
    for tag in "${model_tags[@]}"; do model_impl_stdargs+=(--tag "$tag"); done
    for kv in $model_param_data; do model_impl_stdargs+=("$kv"); done
}

# Print path to file if in CWD, or else relative to cache dir.
# Return non-zero if not in cache dir, or if "$ns_cache_refresh" is
# set to a non-empty string.

function model_find_cacheable {
    file="$1"
    if [ -r "./$file" ]; then
               echo "$file"
        return 0
    else 
        local cached="$model_cache_dir/$file"
        echo "$cached"
        return $([ -z "$ns_cache_refresh" -a -e "$cached" ])
    fi
}
