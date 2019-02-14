#!/usr/bin/env bash

# Build any CMake projects living in validation/src/<proj>/.

# If not set, attempt to deduce nsuite paths from script directory.
if [ -z "$ns_base_path" ]; then
    unset CDPATH
    ns_base_path=$(cd "${BASH_SOURCE[0]%/*}/.."; pwd)
fi

[ -n "$ns_install_path" ] || ns_install_path="$ns_base_path/install"
[ -n "$ns_build_path" ] || ns_build_path="$ns_base_path/build"

function try_build_project {
    local src="$1" build="$2" install="$3"

    typeset -x CMAKE_PREFIX_PATH="$ns_install_path:$CMAKE_PREFIX_PATH"

    if [ -e "$build" -a ! -d "$build" ]; then
	echo "File exists at '$build', skipping."
	return 1
    fi

    # Move any existing build directory out of the way.
    if [ -d "$build" ]; then
	local i=1
	while [ -e "$build.$i" ]; do ((++i)); done

	mv "$build" "$build.$i" || {
	    echo "Fatal error: could not move existing build directory '$build'."
	    return 2
	}
    fi

    mkdir -p "$build" || {
	echo "Fatal error: unable to create build directory '$build'."
	return 2
    }

    cd "$build"

    echo "Configuring ${src##*/}."
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX:PATH="$install" "$src" &> config.log || {
	echo "Error: refer to log file '$build/config.log'"
    	return 1
    }
    
    echo "Building ${src##*/}."
    make install &> build.log || {
	echo "Error: refer to log file '$build/build.log'"
	return 1
    }
}

for ppath in "$ns_base_path"/validation/src/*/CMakeLists.txt; do
    project_dir="${ppath%/*}"
    project_name="${project_dir##*/}"
    build_dir="$ns_build_path/validation/$project_name"

    try_build_project "$project_dir" "$build_dir" "$ns_install_path"
    if [ $? -gt 1 ]; then exit $?; fi
done

