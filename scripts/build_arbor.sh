arb_repo_path=$ns_build_path/arbor
arb_build_path=$arb_repo_path/build
arb_checked_flag="${arb_repo_path}/checked_out"

# clear log file from previous builds
out="$ns_build_path/log_arbor"
rm -f "$out"

# aquire the code if it has not already been downloaded
if [ ! -f "$arb_checked_flag" ]; then
    rm -rf "$arb_repo_path"

    # clone the repository
    msg "ARBOR: cloning from $ns_arb_repo"
    git clone "$ns_arb_repo" "$arb_repo_path" --recursive &>> "$out"
    [ $? != 0 ] && exit_on_error "see ${out}"

    # check out the branch
    if [ "$ns_arb_branch" != "master" ]; then
        msg "ARBOR: check out branch $ns_arb_branch"
        cd "$arb_repo_path"
        git checkout "$ns_arb_branch" &>> "$out"
        [ $? != 0 ] && exit_on_error "see ${out}"
    fi
    touch "${arb_checked_flag}"
else
    msg "ARBOR: repository has already downloaded"
fi

# remove old build files
mkdir -p "$arb_build_path"

# configure the build with cmake
cd "$arb_build_path"
cmake_args=-DCMAKE_INSTALL_PREFIX:PATH="$ns_install_path"
cmake_args="$cmake_args -DARB_WITH_MPI=$ns_with_mpi"
cmake_args="$cmake_args -DARB_WITH_GPU=$ns_arb_with_gpu"
cmake_args="$cmake_args -DARB_ARCH=$ns_arb_arch"
cmake_args="$cmake_args -DARB_VECTORIZE=$ns_arb_vectorize"
msg "ARBOR: cmake $cmake_args"
cmake .. $cmake_args &>> "$out"
[ $? != 0 ] && exit_on_error "see ${out}"

cd "$arb_build_path"

msg "ARBOR: build"
make -j $ns_makej examples &>> "$out"
[ $? != 0 ] && exit_on_error "see ${out}"

msg "ARBOR: install"
make install &>> "$out"
[ $? != 0 ] && exit_on_error "see ${out}"

src_path="$arb_build_path/bin"
dst_path="$ns_install_path/bin"
msg "ARBOR: copy examples to '${dst_path}'"
cp $src_path/ring $dst_path/arb_ring  &>> "$out"
[ $? != 0 ] && exit_on_error "see ${out}"
cp $src_path/bench $dst_path/arb_bench &>> "$out"
[ $? != 0 ] && exit_on_error "see ${out}"

msg "ARBOR: build completed"

cd $ns_base_path

