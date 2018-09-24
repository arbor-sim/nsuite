usage() {
    echo
    echo "nsuite installer options:"
    echo
    echo "   arbor  : build arbor"
    echo "   neuron : build neuron"
    echo "   all    : build arbor and neuron"
    echo "   -e filename: source filename before building"
    echo
    echo "examples:"
    echo
    echo "install only arbor:"
    echo "$ install arbor"
    echo
    echo "install arbor and neuron:"
    echo "$ install all"
    echo
    echo "install neuron using environment configured in config.sh:"
    echo "$ install neuron -e config.sh"
    echo
}

# Load some utility functions.
source ./scripts/util.sh

# Set up default environment variables
default_environment

# parse arguments
while [ "$1" != "" ]
do
    case $1 in
        arbor )
            ns_build_arbor=true
            ;;
        neuron )
            ns_build_neuron=true
            ;;
        all )
            ns_build_arbor=true
            ns_build_neuron=true
            ;;
        -e )
            shift
            ns_environment=$1
            ;;
        * )
            echo "unknown option '$1'"
            usage
            exit 1
    esac
    shift
done

# Run a user supplied configuration script if it was provided with the -e flag.
# This will make changes to the configuration variables ns_* set in environment()
if [ "$ns_environment" != "" ]; then
    msg "using additional configuration: $ns_environment"
    if [ ! -f "$ns_environment" ]; then
        err "file '$ns_environment' not found"
        exit 1
    fi
    source "$ns_environment"
    echo
fi

msg "---- TARGETS ----"
msg "build arbor:   $ns_build_arbor"
msg "build neuron:  $ns_build_neuron"
echo
msg "---- PATHS ----"
msg "working path:  $ns_base_path"
msg "install path:  $ns_install_path"
msg "build path:    $ns_build_path"
echo
msg "---- SYSTEM ----"
msg "system:        $ns_system"
msg "using mpi:     $ns_with_mpi"
msg "C compiler:    $ns_cc"
msg "C++ compiler:  $ns_cxx"
msg "python:        $ns_python"
echo
msg "---- ARBOR ----"
msg "repo:          $ns_arb_repo"
msg "branch:        $ns_arb_branch"
msg "arch:          $ns_arb_arch"
msg "gpu:           $ns_arb_with_gpu"
msg "vectorize:     $ns_arb_vectorize"
echo
msg "---- NEURON ----"
msg "version:       ${ns_nrn_version_major}.${ns_nrn_version_minor}"
msg "repo:          $ns_nrn_git_repo"
msg "branch:        $ns_nrn_branch"

mkdir -p "$ns_build_path"

export CC="$ns_cc"
export CXX="$ns_cxx"

[ "$ns_build_arbor"  = true ] && echo && source "$ns_base_path/scripts/build_arbor.sh"
[ "$ns_build_neuron" = true ] && echo && source "$ns_base_path/scripts/build_neuron.sh"

echo
msg "Installation finished"
echo

# find and record the python and binary paths
find_paths python_path site-packages
find_paths bin_path bin

msg "python paths: $python_path"
msg "bin paths:    $bin_path"

export PYTHONPATH="$python_path:$PYTHONPATH"
export PATH="$bin_path:$PATH"

mkdir -p config

echo $python_path > config/python_path
echo $bin_path    > config/bin_path
echo $system_name > config/target

