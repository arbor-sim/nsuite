neuron_repo_path="$build_path/neuron"

# clear log file from previous builds
out="$build_path/log_neuron"
rm -rf $out

msg "NEURON: starting build, see $out for log"

# only check out code if not already checked out
if [ ! -d "$neuron_repo_path/.git" ]
then
    # TODO: currently just using master on the development repo, because
    #       there are no release tags. Maybe download the source?
    msg "NEURON: cloning to $neuron_repo_path"
    git clone https://github.com/neuronsimulator/nrn $neuron_repo_path &>> ${out}
    [ $? != 0 ] && err "see ${out}" && return 1
fi

cd $neuron_repo_path

# only run configure steps if Makefile has not previously been generated.
if [ ! -f "$neuron_repo_path/Makefile" ]
then
    msg "NEURON: configure"

    ./build.sh &>> ${out}
    [ $? != 0 ] && err "see ${out}" && return 1

    config_options=--prefix="$install_path"
    config_options="$config_options --without-iv"
    config_options="$config_options --with-nrnpython"
    if [ "$with_mpi" = "true" ]; then
        config_options="$config_options --with-mpi --with-paranrn"
    fi

    msg "NEURON: configuring with: $config_options"

    ./configure $config_options &>> ${out}
    [ $? != 0 ] && err "see ${out}" && return 1
fi

msg "NEURON: build"
make -j6 &>> ${out}
[ $? != 0 ] && err "see ${out}" && return 1

msg "NEURON: install"
make install &>> ${out}
[ $? != 0 ] && err "see ${out}" && return 1

# install python stuff
msg "NEURON: python setup and install"
cd "$neuron_repo_path/src/nrnpython"
python setup.py install --prefix=$install_path &>> ${out}
[ $? != 0 ] && err "see ${out}" && return 1

cd $base_path
