cnrn_repo_path="$ns_build_path/coreneuron"
cnrn_build_path="$cnrn_repo_path/build"
mod2c_repo_path="$cnrn_repo_path/external/mod2c"
mod2c_build_path="$mod2c_repo_path/build"
cnrn_checked_flag="${cnrn_repo_path}/checked_out"

# clear log file from previous builds
out="$ns_build_path/log_coreneuron"
rm -f $out

# aquire the code if it has not already been downloaded
if [ ! -f "$cnrn_checked_flag" ]; then
    rm -rf "$cnrn_repo_path"

    msg "CoreNEURON: cloning from $ns_cnrn_git_repo to $cnrn_repo_path"
    git clone --recursive "$ns_cnrn_git_repo" "$cnrn_repo_path" >> "${out}" 2>&1
    [ $? != 0 ] && exit_on_error "see ${out}"

    # check out the branch
    if [ "$ns_cnrn_sha" != "" ]; then
        msg "CoreNEURON: check out commit $ns_cnrn_sha"
        cd "$cnrn_repo_path"
        git checkout "$ns_cnrn_sha" >> "$out" 2>&1
        [ $? != 0 ] && exit_on_error "see ${out}"
    fi

    touch "${cnrn_checked_flag}"
fi

cd $cnrn_repo_path

# build CoreNEURON

# remove old build files
mkdir -p "$cnrn_build_path"

# configure the build with cmake
cd "$cnrn_build_path"
cmake_args=-DCMAKE_INSTALL_PREFIX:PATH="$ns_install_path"
cmake_args="$cmake_args -DCMAKE_BUILD_TYPE=release"
# Turn off tests, because these cause linking problems with boost.
cmake_args="$cmake_args -DUNIT_TESTS=off"
cmake_args="$cmake_args -DFUNCTIONAL_TESTS=off"
cmake_args="$cmake_args -DENABLE_MPI=$ns_with_mpi"
if [ "$ns_cnrn_gpu" == "true" ]
then
    cmake_args="$cmake_args -DCOMPILE_LIBRARY_TYPE=STATIC -DCUDA_HOST_COMPILER=`which gcc` -DCUDA_PROPAGATE_HOST_FLAGS=OFF -DENABLE_SELECTIVE_GPU_PROFILING=ON -DENABLE_OPENACC=ON -DCORENEURON_OPENMP=OFF"
else
    cmake_args="$cmake_args -DENABLE_OPENACC=OFF -DCORENEURON_OPENMP=ON"
fi

msg "CoreNEURON: cmake $cmake_args"
cmake "$cnrn_repo_path" $cmake_args -DCMAKE_C_FLAGS="$ns_cnrn_compiler_flags" -DCMAKE_CXX_FLAGS="$ns_cnrn_compiler_flags" >> "$out" 2>&1
[ $? != 0 ] && exit_on_error "see ${out}"

msg "CoreNEURON: make"
make -j $ns_makej >> "$out" 2>&1
[ $? != 0 ] && exit_on_error "see ${out}"

msg "CoreNEURON: install"
make install >> "$out" 2>&1
[ $? != 0 ] && exit_on_error "see ${out}"

cd $ns_base_path

coreneuronlib=$(find "$ns_install_path" -name libcoreneuron.so -print -quit)

msg "CoreNeuron: saving environment"
save_environment coreneuron "export CORENEURONLIB='$coreneuronlib'"
