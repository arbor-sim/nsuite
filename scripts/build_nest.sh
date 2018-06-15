nest_repo_path=$build_path/nest
nest_build_path=$nest_repo_path/build

msg "NEST: starting build"

# only check out code if not already checked out
if [ ! -d "$nest_repo_path/.git" ]
then
    msg "NEST: cloning"
    git clone https://github.com/nest/nest-simulator.git $nest_repo_path

    cd $nest_repo_path

    nest_version="v2.14.0"
    msg "NEST: checkout version $nest_version"
    git checkout tags/"$nest_version"
fi

cd $nest_repo_path

# only configure build if not already configured
if [ ! -d "$nest_build_path" ]
then
    # TODO: mpi
    msg "NEST: configure build"
    mkdir -p "$nest_build_path"
    cd "$nest_build_path"
    cmake .. -DCMAKE_INSTALL_PREFIX:PATH="$install_path"
fi

cd "$nest_build_path"

msg "NEST: build"
make -j6

msg "NEST: install"
make install > $build_path/nest_install_log

msg "NEST: build completed"

cd $base_path
