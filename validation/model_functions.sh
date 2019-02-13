function model_name {
    echo "$(basename $(pwd))"
}

function die {
    echo "$(model_name): $@" >&2
    exit 1
}

function find_exe {
    local exe="$1"

    # seach cwd and nsuite paths:
    for dir in . "$ns_install_path/bin" "$ns_common_dir/bin"; do
        if [ -x "$dir/$exe" ]; then
            echo "$dir/$exe"
            return
        fi
    done
}

function make_model_out {
    local model="$1" sim="$2" pset="$3"
    local config="$sim-$model-$pset"

    # Replace '.' with correct NS base dir when that's sorted.
    local outdir="./$config"
    mkdir -p "$outdir" || die "unable to create output director $outdir"

    echo "$outdir"
}

function read_model_params {
    local pset_path="$1"
    [ -n "$pset" ] || pset="default"

    [ -r "./$pset.param" ] || die "unable to read parameter set file $pset.param"
    cat "./$pset.param"
}

function cache_if_not_local {
    local file="$1"
    if [ -r "$file" ]; then
        echo "$file";
    else
        mkdir -p "$ns_cache_dir"
        echo "$ns_cache_dir/$file"
    fi
}

function model_setup {
    local sim="$1" pset="$2"

    model=$(model_name)

    model_impl_basename="run-${model}-${sim}"
    model_impl=$(find_exe "$model_impl_basename")
    [ -n "$model_impl" ] || die "unable to find executable implementation $model_impl_basename"

    model_outdir=$(make_model_out "$model" "$sim" "$pset")
    model_params=$(read_model_params "$pset")

    model_output_default="${model_outdir}/run.n4"
    model_ref_default=$(cache_if_not_local "${model}-${pset}-ref.n4")
    model_generate_default=$(find_exe "generate-${model}")
}
