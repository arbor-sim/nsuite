#!/usr/bin/env bash

# Common set-up for validation models.

# Expects ns_base_path to be set; default paths to
# output and cache directories can be overridden with
# ns_output_path and ns_base_path respectively.

function die {
    echo "$@" >&2; exit 1
}

# Sets model_name, model_sim and model_param from arguments,
#
# Creates if required output dir and cache dir.
#
# Sets variables model_output_dir, model_cache_dir, model_param_data
# and model_status_path.
#
# Prefixes path with cwd, nsuite common/bin and nsuite install/bin.

function model_setup {
    model_name="$1"

    model_refresh=""
    if [ "$2" = "-r" ]; then model_refresh="-r"; shift; fi

    model_sim="$2"
    model_param="$3"

    local output_dir="${ns_output_path:-$ns_base_path/output}"
    local cache_dir="${ns_cache_path:-$ns_base_path/cache}"

    model_cache_dir="$cache_dir/$model_name"
    mkdir -p "$model_cache_dir" || die "$model_name: cannot create directory '$model_cache_dir'"

    model_output_dir="$output_dir/$model_sim/$model_name/$model_param"
    mkdir -p "$model_output_dir" || die "$model_name: cannot create directory '$model_output_dir'"

    model_status_path="$model_output_dir/status"

    [ -r "${model_param}.param" ] || die "$model_name: unable to read parameter data '${pset}.param'"
    model_param_data=$(< ${model_param}.param)

    local install_dir="${ns_install_path:-$ns_base_path/install}"
    local common_dir="${ns_common_path:-$ns_base_path/common}"
    export PATH=".:${install_dir}/bin:${common_dir}/bin:$PATH"
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

