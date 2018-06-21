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

# sets the variable system_name
detect_system() {
    # default option
    system_name=linux;

    local name=`hostname`

    # by default target multicore on Piz Daint
    if [[ "$name" == 'daint'* ]]
    then
        system_name=daintmc
    fi
}

find_paths() {
    local tmp=""
    for path in `find $base_path/install -type d -name $2`
    do
        tmp="$path:$tmp"
    done
    export $1=$tmp
}
