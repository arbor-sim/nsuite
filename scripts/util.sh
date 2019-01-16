# Print a message to stderr.
# Output to stderr to help determine where in build script an error occurred.
msg() {
    local white='\033[1;37m'
    local light_cyan='\033[1;36m'
    local nc='\033[0m'

    >&2 printf "${light_cyan}== ${nc} ${white}$*${nc}\n"
}

err() {
    local white='\033[1;37m'
    local light_red='\033[1;31m'
    local nc='\033[0m'

    >&2 printf "${light_red}== ERROR${nc} ${white}$*${nc}\n"
}

dbg() {
    local white='\033[1;37m'
    local green='\033[1;92m'
    local nc='\033[0m'

    >&2 printf "${green}==== ${nc} ${white}$*${nc}\n"
}

exit_on_error() {
    err "$*"
    exit 1
}

# sets the variable system_name
detect_system() {
    # default option
    ns_system_name=linux;

    local name=`hostname`

    # by default target multicore on Piz Daint
    if [[ "$name" == 'daint'* ]]
    then
        ns_system_name=daintmc
    fi
}

find_paths() {
    local tmp=""
    for path in `find $ns_base_path/install -type d -name $2`
    do
        tmp="$path:$tmp"
    done
    export $1=$tmp
}

# Sets up the default enviroment.
# Variables defined here use the prefix ns_
default_environment() {
    # By default do not build any of the packages.
    ns_build_arbor=false
    ns_build_nest=false
    ns_build_neuron=false
    ns_build_coreneuron=false

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

    # set the number of parallel build tasks
    ns_makej=6

    # detect python3
    ns_python=
    command -v python3 &> /dev/null
    [ $? = 0 ] && ns_python=$(which python3)

    # Arbor specific

    #ns_arb_repo=https://github.com/arbor-sim/arbor.git
    #ns_arb_branch=v0.1
    ns_arb_repo=https://github.com/bcumming/arbor.git
    ns_arb_branch=meter-accumulate

    ns_arb_arch=native
    ns_arb_with_gpu=OFF
    ns_arb_vectorize=ON

    # Neuron specific

    # Neuron is inconsistent with the location and naming scheme of different
    # versions, so just hard code URL and name of the tar ball.

    # The path of the unpacked tar ball. It can't be determined from
    # inspecting the name of the tar ball.
    #ns_nrn_path=nrn-7.5
    #ns_nrn_tarball=nrn-7.5.tar.gz
    #ns_nrn_url=https://neuron.yale.edu/ftp/neuron/versions/v7.5/${ns_nrn_tarball}
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
    ns_cnrn_sha=
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
    echo ARB_NUM_THREADS=$ns_threads_per_socket mpirun -n $ns_sockets --map-by socket:PE=$ns_threads_per_socket $*
    ARB_NUM_THREADS=$ns_threads_per_socket mpirun -n $ns_sockets --map-by socket:PE=$ns_threads_per_socket $*
}

