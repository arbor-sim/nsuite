#!/usr/bin/env bash

usage() {
    cat <<_end_
Usage: run-validation.sh [OPTIONS] SIMULATOR[:TAG...] [SIMULATOR[:TAG...] ...]

Options:
    -h, --help                 Print this help message and exit.
    --prefix=PREFIX            Use PATH as base for working directories.
    -o, --output=FORMAT        Override default path to validation outputs.
    -l, --list-models          List available model/parameter tests.
    -r, --refresh              Regenerate any cached reference data.
    -m, --model=MODEL/[PARAM]  Run given model/parameter test.

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

One or more TAGs can be suffixed to a simulator. These are passed to the
corresponding test implementations and are meant to describe runtime simulator
configuration options.

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

unset ns_cache_refresh
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
            ns_cache_refresh=1
            ;;
        -* | --* )
            argerror "unknown option '$1'"
            ;;
        * )
            sims="$sims $1"
            ;;
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

export ns_cache_refresh

# Add common/bin scripts to our path (used for git-repo-hash, pathsub).
export PATH="$ns_base_path/common/bin${PATH:+:}$PATH"

# TODO: this has to go into the configuration environment setup scripts
export ARB_NUM_THREADS=$[ $ns_threads_per_core * $ns_cores_per_socket ]

info "---- Platform ----"
info "platform:          $ns_system"
info "cores per socket:  $ns_cores_per_socket"
info "threads per core:  $ns_threads_per_core"
info "threads:           $ARB_NUM_THREADS"
info "sockets:           $ns_sockets"
info "mpi:               $ns_with_mpi"
echo

info "---- Validation ----"

# Colour highlight shortcuts:
red=${tcol[hi_red]}
green=${tcol[hi_green]}
cyan=${tcol[hi_cyan]}
nc=${tcol[reset]}

# Grab git repo hash and install timestamp for substitution in output directories below.
# TODO: Move this sort of thing into a config/common_env.sh script at install time?
repo_hash=$(git-repo-hash ${ns_base_path})
repo_hash_short=$(git-repo-hash --short ${ns_base_path})
ns_timestamp=$(< "$ns_build_path/timestamp")
ns_sysname=$(< "$ns_build_path/sysname")

for sim_with_tags in $sims; do
    unset tagsplit
    IFS=':' read -r -a tagsplit <<<"$sim_with_tags"
    sim=${tagsplit[0]}

    echo
    sim_env="$ns_prefix/config/env_$sim.sh"
    if [ ! -f "$sim_env" ]; then
        info "Simulator $sim has not been locally installed, skipping."
        continue
    fi

    info "Running validation for $sim:"

    for model in $models; do
        param=""
        if [[ ! "$model" == */* ]]; then
            model="$model/default"
        fi
        param="${model#*/}"
        basemodel="${model%/*}"

        model_path="$ns_base_path/validation/$basemodel"
        if [ ! -x "$model_path/run" ]; then
            info "Missing run file for model $basemodel, skipping."
            continue
        fi

        if [ ! -r "$model_path/$param.param" ]; then
            info "Missing parameter file $param.param for model $basemodel, skipping."
            continue
        fi

        outdir=$(pathsub --base="$ns_validation_output" \
            T="$ns_timestamp" S="$ns_sysname" H="$repo_hash" h="$repo_hash_short" \
            s="$sim_with_tags" m="$basemodel" p="$param" \
            -- \
            "${ns_validation_output_format:-%s/%m/%p}")

        mkdir -p "$outdir" || exit_on_err "run-validation.sh: cannot create directory '$outdir'"

        model_status="$outdir/status"
        test_id="$sim_with_tags $basemodel/$param"

        # Run script exit codes:
        #     0 => success: test passed.
        #    96 => failure: test run but validation failed.
        #    97 => missing: no implementation for given simulator.
        #    98 => unsupported tag: implementation does not recognize requested tag.
        # other => error: execution error.

        (
          source "$sim_env";
          "$model_path/run" "$outdir" "$sim_with_tags" "$param"
        ) > "$outdir/run.out" 2> "$outdir/run.err"

        case $? in
            0 )
                echo "$green[PASS]$nc $test_id"
                echo pass > "$model_status"
                ;;
           96 )
                echo "$red[FAIL]$nc $test_id"
                echo fail > "$model_status"
                ;;
           97 )
                echo "$cyan[MISSING]$nc $test_id"
                echo missing > "$model_status"
                ;;
           98 )
                echo "$cyan[UNSUPPORTED]$nc $test_id"
                echo "unsupported tag" > "$model_status"
                ;;
            * )
                echo "$red[ERROR]$nc $test_id"
                echo error > "$model_status"
                ;;
        esac
    done
done
