arb_repo_path=$ns_build_path/arbor
arb_build_path=$arb_repo_path/build
modcc_build_path=$arb_repo_path/build_modcc
arb_checked_flag="${arb_repo_path}/checked_out"

# clear log file from previous builds
out="$ns_build_path/log_arbor"
rm -f "$out"

# aquire the code if it has not already been downloaded
if [ ! -f "$arb_checked_flag" ]; then
    rm -rf "$arb_repo_path"

    # clone the repository
    msg "ARBOR: cloning from $ns_arb_git_repo"
    git clone "$ns_arb_git_repo" "$arb_repo_path" --recursive >> "$out" 2>&1
    [ $? != 0 ] && exit_on_error "see ${out}"

    # check out the branch
    if [ "$ns_arb_branch" != "master" ]; then
        msg "ARBOR: check out branch $ns_arb_branch"
        cd "$arb_repo_path"
        git checkout "$ns_arb_branch" >> "$out" 2>&1
        [ $? != 0 ] && exit_on_error "see ${out}"
    fi
    touch "${arb_checked_flag}"
else
    msg "ARBOR: repository has already downloaded"
fi

# remove old build files
mkdir -p "$arb_build_path"

# build modcc
if [ "$ns_arb_xcompile_modcc" == "ON" ]; then
    mkdir -p "$modcc_build_path"

    # build external modcc
    msg "ARBOR: build modcc"
    cd "$modcc_build_path"
    cmake .. -DARB_ARCH=native >> "$out" 2>&1
    make -j $ns_makej modcc >> "$out" 2>&1
    cd ..
fi

# configure the build with cmake
cd "$arb_build_path"
cmake_args=-DCMAKE_INSTALL_PREFIX:PATH="$ns_install_path"
cmake_args="$cmake_args -DARB_WITH_MPI=$ns_with_mpi"
cmake_args="$cmake_args -DARB_WITH_GPU=$ns_arb_with_gpu"
cmake_args="$cmake_args -DARB_ARCH=$ns_arb_arch"
cmake_args="$cmake_args -DARB_VECTORIZE=$ns_arb_vectorize"
if [ "$ns_arb_xcompile_modcc" == "ON" ]; then
    cmake_args="$cmake_args -DARB_MODCC=${modcc_build_path}/bin/modcc"
fi

msg "ARBOR: cmake $cmake_args"
cmake "$arb_repo_path" $cmake_args >> "$out" 2>&1
[ $? != 0 ] && exit_on_error "see ${out}"

cd "$arb_build_path"

msg "ARBOR: build"
make -j $ns_makej >> "$out" 2>&1
[ $? != 0 ] && exit_on_error "see ${out}"

msg "ARBOR: install"
make install >> "$out" 2>&1
[ $? != 0 ] && exit_on_error "see ${out}"

src_path="$arb_build_path/bin"
dst_path="$ns_install_path/bin"

msg "ARBOR: library build completed"
cd $ns_base_path

# Required for the CMake scripts that build the benchmarks to
# find the Arbor library that was built and installed above.
export CMAKE_PREFIX_PATH="$ns_install_path"

benchmarks="busyring"

for bench in $benchmarks
do
    echo
    msg "ARBOR: $bench benchmark"
    source_path="${ns_base_path}/benchmarks/engines/${bench}/arbor"
    build_path="${ns_build_path}/${bench}_arbor"
    mkdir -p "$build_path"
    cd "$build_path"

    msg "ARBOR: cmake"
    if [ "$ns_arb_xcompile_modcc" == "ON" ]; then
        cmake "$source_path" -DARB_MODCC=${modcc_build_path}/bin/modcc -DCMAKE_BUILD_TYPE=release -DCMAKE_INSTALL_PREFIX:PATH="$ns_install_path" >> "$out" 2>&1
    else
        cmake "$source_path" -DCMAKE_BUILD_TYPE=release -DCMAKE_INSTALL_PREFIX:PATH="$ns_install_path" >> "$out" 2>&1
    fi
    [ $? != 0 ] && exit_on_error "see ${out}"

    msg "ARBOR: make"
    make -j $ns_makej >> "$out" 2>&1
    [ $? != 0 ] && exit_on_error "see ${out}"

    msg "ARBOR: install"
    make install >> "$out" 2>&1
    [ $? != 0 ] && exit_on_error "see ${out}"
done

cd $ns_base_path

echo
msg "ARBOR: saving environment"
save_environment arbor
