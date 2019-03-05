usage() {
    echo
    echo "nsuite installer options:"
    echo
    echo "   arbor       : build Arbor"
    echo "   neuron      : build NEURON"
    echo "   coreneuron  : build CoreNEURON"
    echo "   all         : build all simulators"
    echo "   -e filename : source filename before building"
    echo
    echo "examples:"
    echo
    echo "install only Arbor:"
    echo "$ install arbor"
    echo
    echo "install Arbor, NEURON and CoreNEURON:"
    echo "$ install all"
    echo
    echo "install NEURON using environment configured in config.sh:"
    echo "$ install neuron -e config.sh"
    echo
}

# Load some utility functions.
source ./scripts/util.sh
source ./scripts/environment.sh

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
        coreneuron )
            ns_build_coreneuron=true
            ;;
        all )
            ns_build_arbor=true
            ns_build_neuron=true
            ns_build_coreneuron=true
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
msg "build arbor:       $ns_build_arbor"
msg "build neuron:      $ns_build_neuron"
msg "build coreneuron:  $ns_build_coreneuron"
echo
msg "---- PATHS ----"
msg "working path:  $ns_base_path"
msg "install path:  $ns_install_path"
msg "build path:    $ns_build_path"
msg "input path:    $ns_input_path"
msg "output path:   $ns_output_path"
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
msg "tarball:       $ns_nrn_tarball"
msg "url:           $ns_nrn_url"
msg "repo:          $ns_nrn_git_repo"
msg "branch:        $ns_nrn_branch"
echo
msg "---- CoreNEURON ----"
msg "repo:          $ns_cnrn_git_repo"
msg "sha:           $ns_cnrn_sha"

mkdir -p "$ns_build_path"

export CC="$ns_cc"
export CXX="$ns_cxx"

[ "$ns_build_arbor"  = true ] && echo && source "$ns_base_path/scripts/build_arbor.sh"
cd "$ns_base_path"
[ "$ns_build_neuron" = true ] && echo && source "$ns_base_path/scripts/build_neuron.sh"
cd "$ns_base_path"
[ "$ns_build_coreneuron" = true ] && echo && source "$ns_base_path/scripts/build_coreneuron.sh"
cd "$ns_base_path"

# Always attempt to build validation models/generators, regardless of simulator.
source "$ns_base_path/scripts/build_validation_models.sh"
cd "$ns_base_path"

echo
msg "Installation finished"
echo

