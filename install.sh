#!/usr/bin/bash

usage() {
    echo
    echo "nsuite installer options:"
    echo
    echo "   arbor  : build arbor"
    echo "   neuron : build neuron"
    echo "   nest   : build nest"
    echo "   all    : build all of nest, neuron and arbor"
    echo "   -e filename: source filename before building"
    echo
    echo "examples:"
    echo
    echo "install arbor and nest, but not neuron:"
    echo "$ install arbor nest"
    echo
    echo "install arbor, nest and neuron:"
    echo "$ install all"
    echo
    echo "install arbor using environment configured in config.sh:"
    echo "$ install arbor -e config.sh"
    echo
}

# Load some utility functions.
source ./scripts/util.sh

# Sets up the default enviroment.
# Variables defined here use the prefix ns_
default_environment() {
    # By default do not build any of the packages.
    ns_build_arbor=false
    ns_build_nest=false
    ns_build_neuron=false

    # No additional environment script to run.
    ns_environment=

    # Where software packages will be built then installed.
    ns_base_path=$(pwd)
    ns_install_path="$ns_base_path/install"
    ns_build_path="$ns_base_path/build"

    # Detect OS
    case "$OSTYPE" in
      linux*)   ns_system=linux ;;
      darwin*)  ns_system=apple ;;
      *)        err "unsuported OS: $OSTYPE"; exit 1 ;;
    esac

    # Choose compiler based on OS
    if [ "$ns_system" = "linux" ]; then
        ns_cc=$(which gcc)
        ns_cxx=$(which g++)
    elif [ "$ns_system" = "apple" ]; then
        ns_cc=$(which clang)
        ns_cxx=$(which clang++)
    fi

    # use MPI if we can find it
    ns_with_mpi=OFF
    command -v mpicc &> /dev/null
    [ $? = 0 ] && command -v mpic++ &> /dev/null
    if [ $? = 0 ]; then
        ns_with_mpi=ON
        ns_cc=$(which mpicc)
        ns_cxx=$(which mpic++)
    fi

    # detect python3
    ns_python=
    command -v python3 &> /dev/null
    [ $? = 0 ] && ns_python=$(which python3)

    # Arbor specific
    ns_arb_repo=https://github.com/eth-cscs/arbor.git
    ns_arb_branch=master

    ns_arb_arch=native
    ns_arb_with_gpu=OFF
    ns_arb_vectorize=ON
}

# Set up default environment variables
default_environment

# parse arguments
while [ "$1" != "" ]
do
    case $1 in
        arbor )
            ns_build_arbor=true
            ;;
        nest )
            ns_build_nest=true
            ;;
        neuron )
            ns_build_neuron=true
            ;;
        all )
            ns_build_arbor=true
            ns_build_nest=true
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
    msg "using user-supplied configuration: $ns_environment"
    if [ ! -f "$ns_environment" ]; then
        err "file '$ns_environment' not found"
        exit 1
    fi
    source "$ns_environment"
fi

msg "---- TARGETS ----"
msg "build arbor:   $ns_build_arbor"
msg "build nest:    $ns_build_nest"
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

mkdir -p "$ns_build_path"

[ "$ns_build_arbor"  = true ] && source "$ns_base_path/scripts/build_arbor.sh"
[ "$ns_build_neuron" = true ] && source "$ns_base_path/scripts/build_neuron.sh"
[ "$ns_build_nest"   = true ] && source "$ns_base_path/scripts/build_nest.sh"

exit 0

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

