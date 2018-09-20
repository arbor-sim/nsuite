arb_repo_path=$ns_build_path/arbor
arb_build_path=$arb_repo_path/build

# clear log file from previous builds
out="$ns_base_path/log_arbor"
rm -rf "$out"

# only check out code if not already checked out
if [ ! -d "$arb_repo_path/.git" ]
then
    # clone the repository
    msg "ARBOR: cloning from $ns_arb_repo"
    git clone "$ns_arb_repo" "$arb_repo_path" --recursive &>> "$out"
    [ $? != 0 ] && err "see ${out}" && return 1

    # check out the branch
    if [ "$ns_arb_branch" != "master" ]; then
        msg "ARBOR: check out branch $ns_arb_branch"
        cd "$arb_repo_path"
        git checkout "mc_arb_branch" &>> "$out"
        [ $? != 0 ] && err "see ${out}" && return 1
    fi
else
    msg "ARBOR: repository has already been checked out"
fi

# only configure build if not already configured
if [ ! -d "$arb_build_path" ]
then
    mkdir -p "$arb_build_path"
    cd "$arb_build_path"
    cmake_args=-DCMAKE_INSTALL_PREFIX:PATH="$ns_install_path"
    cmake_args="$cmake_args -DARB_WITH_MPI=$ns_with_mpi"
    cmake_args="$cmake_args -DARB_WITH_GPU=$ns_arb_with_gpu"
    cmake_args="$cmake_args -DARB_ARCH=$ns_arb_arch"
    cmake_args="$cmake_args -DARB_VECTORIZE=$ns_arb_vectorize"
    msg "ARBOR: configure build with args: $cmake_args"
    cmake .. $cmake_args &>> "$out"
    [ $? != 0 ] && err "see ${out}" && return 1
fi

cd "$arb_build_path"

msg "ARBOR: build"
make -j6 &>> "$out"
[ $? != 0 ] && err "see ${out}" && return 1

msg "ARBOR: install"
make install &>> "$out"
[ $? != 0 ] && err "see ${out}" && return 1

msg "ARBOR: build completed"

cd $base_path

