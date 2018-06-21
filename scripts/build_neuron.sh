neuron_repo_path=$build_path/neuron

msg "NEURON: starting build"

# only check out code if not already checked out
if [ ! -d "$neuron_repo_path/.git" ]
then
    # TODO: currently just using master on the development repo, because
    #       there are no release tags. Maybe download the source?
    msg "NEURON: cloning"
    git clone https://github.com/neuronsimulator/nrn $neuron_repo_path
fi

cd $neuron_repo_path

# only run configure steps if Makefile has not previously been generated.
if [ ! -f "$neuron_repo_path/Makefile" ]
then
    msg "NEURON: configure"

    ./build.sh > $build_path/neuron_configure_log

    config_options=--prefix="$install_path"
    config_options="$config_options --without-iv"
    config_options="$config_options --with-nrnpython"
    if [ "$with_mpi" = "true" ]; then
        config_options="$config_options --with-mpi"
    fi

    ./configure $config_options >> $build_path/neuron_configure_log
fi

msg "NEURON: build"
make -j6

msg "NEURON: install"
make install > $build_path/neuron_install_log

# install python stuff
msg "NEURON: python setup and install"
cd "$neuron_repo_path/src/nrnpython"
python setup.py install --prefix=$install_path > $build_path/neuron_python_install_log

cd $base_path
