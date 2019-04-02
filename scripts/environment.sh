# Set the base paths to working directories.
# Variables defined here use the prefix ns_
set_working_paths() {
    if [ -z "$ns_prefix" ]; then
        echo "error: empty ns_prefix"
        exit 1
    fi

    # Paths to working directories
    export ns_install_path="$ns_prefix/install"
    export ns_build_path="$ns_prefix/build"
    export ns_cache_path="$ns_prefix/cache"
    export ns_input_path="$ns_prefix/input"
    export ns_config_path="$ns_prefix/config"
    export ns_bench_input_path="$ns_prefix/input/benchmarks"
    export ns_bench_output="$ns_prefix/output/benchmark"
    export ns_validation_output="$ns_prefix/output/validation"

    export ns_pyvenv_path="$ns_build_path/pyvenv"
}

# Sets up the default enviroment.
# Variables defined here use the prefix ns_
default_environment() {
    set_working_paths

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

    # detect the hardware resources
    default_hardware

    # set the number of parallel build tasks
    ns_makej=6

    # detect python3
    ns_python=
    command -v python3 &> /dev/null
    [ $? = 0 ] && ns_python=$(which python3)

    # Python venv module list
    ns_pyvenv_modules="scipy netcdf4 xarray"

    # Arbor specific

    ns_arb_git_repo=https://github.com/arbor-sim/arbor.git
    ns_arb_branch=v0.2

    ns_arb_arch=native
    ns_arb_with_gpu=OFF
    ns_arb_vectorize=ON

    # Neuron specific

    # Neuron is inconsistent with the location and naming scheme of different
    # versions, so just hard code URL and name of the tar ball.

    # The path of the unpacked tar ball. It can't be determined from
    # inspecting the name of the tar ball.
    ns_nrn_path=nrn-7.6
    ns_nrn_tarball=nrn-7.6.5.tar.gz
    ns_nrn_url=https://neuron.yale.edu/ftp/neuron/versions/v7.6/7.6.5/${ns_nrn_tarball}

    # set to a git repository url to source from a git repo instead of using
    # official tar ball
    #ns_nrn_git_repo=https://github.com/neuronsimulator/nrn.git
    ns_nrn_git_repo=
    # set this variable if using git and want to use a branch other than master
    ns_nrn_branch=master

    # CoreNeuron specific
    ns_cnrn_git_repo=https://github.com/BlueBrain/CoreNeuron.git
    ns_cnrn_sha=0.14

    # CoreNeuron can optionally target GPUs using PGI OpenACC.
    ns_cnrn_gpu=false           # turned off by default.
    # CoreNeuron relies on passing compiler flags via CMAKE_CXX_FLAGS and CMAKE_C_FLAGS
    # for architecture-specific optimization. If using OpenACC or trying to coax the
    # Intel compiler to vectorize, set this variable.
    ns_cnrn_compiler_flags=-O2
}

# Attempts to detect harware resouces available on node
# These default values are probably acceptable for laptop and desktop systems.
# For detailed benchmarking, these defaults can be overridden.
default_hardware() {
    ns_threads_per_core=1
    ns_cores_per_socket=1
    ns_sockets=1

    if [ "${ns_system}" = "linux" ]; then
        ns_threads_per_core=`lscpu | grep ^"Thread(s) per core" | awk '{print $4}'`
        ns_cores_per_socket=`lscpu | grep ^"Core(s) per socket" | awk '{print $4}'`
        ns_sockets=`lscpu | grep ^"Socket(s)" | awk '{print $2}'`
    elif [ "${ns_system}" = "apple" ]; then
        ns_cores_per_socket=`sysctl hw.physicalcpu | awk '{print $2}'`
        nlog=`sysctl hw.logicalcpu | awk '{print $2}'`
        ns_threads_per_core=`echo "$nlog / $ns_cores_per_socket" | bc`
    fi

    ns_threads_per_socket=$[ $ns_threads_per_core * $ns_cores_per_socket ]
}

run_with_mpi() {
    if [ "$ns_with_mpi" = "ON" ]
    then
        echo ARB_NUM_THREADS=$ns_threads_per_socket mpirun -n $ns_sockets --map-by socket:PE=$ns_threads_per_socket $*
        ARB_NUM_THREADS=$ns_threads_per_socket mpirun -n $ns_sockets --map-by socket:PE=$ns_threads_per_socket $*
    else
        echo ARB_NUM_THREADS=$ns_threads_per_socket  $*
        ARB_NUM_THREADS=$ns_threads_per_socket  $*
    fi
}

find_installed_paths() {
    find "$ns_install_path" -type d -name "$1" | awk -v ORS=: '{print}'
}

# Save the environment used to build a simulation engine
# to a shell script that can be used to reproduce that
# environment for running the simulation engine.
#
# Record prefix to writable data (ns_prefix) and other
# installation-time information, viz. ns_timestamp and
# ns_sysname.
# 
# Take name of simulation engine (one of: {arb, nrn, corenrn}) as
# first argument; any additional arguments are appended to the
# generated config script verbatim.
save_environment() {
    set_working_paths
    sim="$1"
    shift

    # Find and record python, bin, and lib paths.
    python_path=$(find_installed_paths site-packages)"$ns_base_path/common/python:"
    bin_path=$(find_installed_paths bin)"$ns_base_path/common/bin:"
    lib_path=$(find_installed_paths lib)$(find_installed_paths lib64)

    config_file="${ns_config_path}/env_${sim}.sh"
    mkdir -p "$ns_config_path"

    source_env_script=
    if [ -n "$ns_environment" ]; then
        source_env_script='source '$(full_path "$ns_environment")
    fi

    pyvenv_activate=$ns_pyvenv_path/bin/activate
    source_pyvenv_script=
    if [ -r "$pyvenv_activate" ]; then
	source_pyvenv_script="source '$pyvenv_activate'"
    fi

    cat <<_end_ > "$ns_config_path/env_$sim.sh"
export ns_prefix="$ns_prefix"
export ns_timestamp="$ns_timestamp"
export ns_sysname="$ns_sysname"
export PATH="$bin_path\${PATH}"
export PYTHONPATH="$python_path\$PYTHONPATH"
export PATH="$bin_path\$PATH"
export LD_LIBRARY_PATH="${lib_path}:\$LD_LIBRARY_PATH"
source "$ns_base_path/scripts/environment.sh"
default_environment
$source_env_script
$source_pyvenv_script
_end_

    for appendix in "${@}"; do
        echo "$appendix" >> "$ns_config_path/env_$sim.sh"
    done
}

