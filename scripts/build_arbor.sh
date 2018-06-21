arb_repo_path=$build_path/arbor
arb_build_path=$arb_repo_path/build

# clear log file from previous builds
out="$build_path/log_arbor"
rm -rf $out

msg "ARBOR: starting build"

# only check out code if not already checked out
if [ ! -d "$arb_repo_path/.git" ]
then
    msg "ARBOR: cloning"
    git clone https://github.com/eth-cscs/arbor.git $arb_repo_path --recursive &>> "$out"
    [ $? != 0 ] && err "see ${out}" && return 1
else
    msg "ARBOR: repository has already been checked out"
fi

# only configure build if not already configured
if [ ! -d "$arb_build_path" ]
then
    # TODO: mpi
    msg "ARBOR: configure build"
    mkdir -p "$arb_build_path"
    cd "$arb_build_path"
    cmake .. -DCMAKE_INSTALL_PREFIX:PATH="$install_path" &>> "$out"
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
