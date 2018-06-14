# Print a message to stderr.
# Output to stderr to help determine where in build script an error occurred.
msg() {
    local black='\033[0;30m'
    local red='\033[0;31m'
    local green='\033[0;32m'
    local orange='\033[0;33m'
    local blue='\033[0;34m'
    local purple='\033[0;35m'
    local cyan='\033[0;36m'
    local light_gray='\033[0;37m'
    local light_green='\033[1;32m'
    local yellow='\033[1;33m'
    local light_blue='\033[1;34m'
    local light_purple='\033[1;35m'
    local light_cyan='\033[1;36m'
    local white='\033[1;37m'
    local light_red='\033[1;31m'
    local nc='\033[0m'
    >&2 printf "${light_cyan}== ${nc} ${white}$*${nc}\n"
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
