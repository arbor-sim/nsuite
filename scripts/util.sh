init_tcol() {
    # Set global associative array 'tcol' with entries for the eight
    # commonly supported colours plus entries for other highlight modes.
    #
    # Leave it empty if we're not attached to a tty.

    unset tcol
    declare -gA tcol

    if [[ -t 1 ]]; then
        local -a colname=(black red green yellow blue magenta cyan white)
        for i in ${!colname[@]}; do tcol[${colname[$i]}]="$(tput setaf $i)"; done

        # If we have 16+ colours, set high intensity versions of colours to these,
        # otherwise reuse the standard 8.

        if [[ $(tput colors) -ge 16 ]]; then
            for i in ${!colname[@]}; do
                let j=8+i
                tcol[hi_${colname[$i]}]="$(tput setaf $j)";
            done
        else
            for i in ${!colname[@]}; do tcol[hi_${colname[$i]}]="${tcol[${colname[$i]}]}"; done
        fi

        # Other entries:
        tcol[reset]=$(tput sgr0) # reset all attributes
        tcol[bold]=$(tput bold)  # bold
        tcol[ul]=$(tput smul)    # underline
        tcol[noul]=$(tput rmul)  # no underline
        tcol[so]=$(tput smso)    # standout
        tcol[noso]=$(tput rmso)  # no standout
    fi
}

# Always initialize colours on sourcing of util.sh
init_tcol

# Print a message to stderr.
# Output to stderr to help determine where in build script an error occurred.
msg() {
    local white="${tcol[hi_white]}"
    local light_cyan="${tcol[hi_cyan]}"
    local nc="${tcol[reset]}"

    >&2 printf "${light_cyan}== ${nc} ${white}$*${nc}\n"
}

err() {
    local white="${tcol[hi_white]}"
    local light_red="${tcol[hi_red]}"
    local nc="${tcol[reset]}"

    >&2 printf "${light_red}== ERROR${nc} ${white}$*${nc}\n"
}

dbg() {
    local white="${tcol[hi_white]}"
    local green="${tcol[hi_green]}"
    local nc="${tcol[reset]}"

    >&2 printf "${green}==== ${nc} ${white}$*${nc}\n"
}

# Print a message to stdout following msg() formatting.
info() {
    local white="${tcol[hi_white]}"
    local light_cyan="${tcol[hi_cyan]}"
    local nc="${tcol[reset]}"

    printf "${light_cyan}== ${nc} ${white}$*${nc}\n"
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
