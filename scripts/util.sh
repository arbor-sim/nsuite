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

find_paths() {
    local tmp=""
    for path in `find $ns_base_path/install -type d -name $2`
    do
        tmp="$path:$tmp"
    done
    export $1=$tmp
}

# Find the absolute path from a relative path
full_path() {
    echo "$(cd "$(dirname "$1")"; pwd)/$(basename "$1")"
}
