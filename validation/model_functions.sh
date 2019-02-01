model="$(basename $(pwd))"

function die {
    echo "$model: $@" >&2
    exit 1
}

function find_model_impl {
    local sim="$1" impl="$model_$sim"

    if [ -x "./$impl" ]; then
	local impl_exe="./$impl"
    else
	local impl_exe=$(which "$impl") || die "unable to find executable implementation $impl"
    fi
    echo "$impl_exe"
}

function make_model_out {
    local sim="$1" pset="$2"

    if [ -z "$pset" ]; then
	local config="$model/$sim"
    else
	local config="$model/$pset/$sim"
    fi

    # Replace '.' with correct NS base dir when that's sorted.
    local outdir="./$config"
    mkdir -p "$outdir" || die "unable to create output director $outdir"

    echo "$outdir"
}

function read_model_params {
    local pset="$1"
    if [ -n "$pset" ]; then
	if [ -r "./$pset.param" ]; then
	    cat "./$pset.param"
	else
	    die "unable to read parameter set file $pset.param"
	fi
    fi
}
