nrn_repo_path="$ns_build_path/neuron"
nrn_checked_flag="${nrn_repo_path}/checked_out"

# clear log file from previous builds
out="$ns_build_path/log_neuron"
rm -f $out

# aquire the code if it has not already been downloaded
if [ ! -f "$nrn_checked_flag" ]; then
    rm -rf "$nrn_repo_path"

    # If a git repository is set, use it.
    # Use git with a specific commit for reproducability, because the
    # "versioned" tar balls on the Neuron web site are not actually versioned.
    if [ "${ns_nrn_git_repo}" != "" ]; then
        msg "NEURON: cloning from $ns_nrn_git_repo to $nrn_repo_path"
        git clone "$ns_nrn_git_repo" "$nrn_repo_path" >> "${out}" 2>&1
        [ $? != 0 ] && exit_on_error "see ${out}"

        # check out the branch
        if [ "$ns_nrn_branch" != "master" ]; then
            msg "NEURON: check out branch $ns_nrn_branch"
            cd "$nrn_repo_path"
            git checkout "$ns_nrn_branch" >> "$out" 2>&1
            [ $? != 0 ] && exit_on_error "see ${out}"
        fi
    # Otherwise download a tar ball.
    # This is brittle and ugly, because the name format for the neuron tar ball
    # changes from time to time, making it impossible to parameterize this
    # on the version number. Furthermore patch updates are automatically
    # rolled into the release tar ball, so a url won't always point to the same
    # code.
    else
        cd "$ns_build_path"

        msg "NEURON: download tarball ${ns_nrn_tarball} from ${ns_nrn_url}"
        wget "$ns_nrn_url" >> ${out} 2>&1
        [ $? != 0 ] && exit_on_error "see ${out}"

        msg "NEURON: untar ${ns_nrn_tarball}"
        tar -xzf "${ns_nrn_tarball}" >> ${out} 2>&1
        [ $? != 0 ] && exit_on_error "see ${out}"
        mv "${ns_nrn_path}" "$nrn_repo_path"  >> ${out} 2>&1
        [ $? != 0 ] && exit_on_error "see ${out}"
    fi

    touch "${nrn_checked_flag}"
fi

cd $nrn_repo_path

# fix neuron to use CoreNEURON-compatble output
# don't use -i argument to sed, because it is a non-posix extension that is implemented differently
# on Linux and BSD.
sed -e 's|GLOBAL minf|RANGE minf|g' -e 's|TABLE minf|:TABLE minf|g' src/nrnoc/hh.mod > tmp
mv tmp src/nrnoc/hh.mod

# only run configure steps if Makefile has not previously been generated.
if [ ! -f "$nrn_repo_path/Makefile" ]
then
    msg "NEURON: build.sh"

    ./build.sh >> "${out}" 2>&1
    [ $? != 0 ] && exit_on_error "see ${out}"

    config_options="--prefix=${ns_install_path} --exec-prefix=${ns_install_path}"
    config_options="$config_options --without-iv"
    config_options="$config_options --with-nrnpython=${ns_python}"
    [ "$ns_with_mpi" = "ON" ] && config_options="$config_options --with-mpi --with-paranrn"

    msg "NEURON: configure $config_options"

    ./configure $config_options >> ${out} 2>&1
    [ $? != 0 ] && exit_on_error "see ${out}"
fi

msg "NEURON: make"
make -j $ns_makej >> "${out}" 2>&1
[ $? != 0 ] && exit_on_error "see ${out}"

msg "NEURON: install"
make install >> "$out" 2>&1
[ $? != 0 ] && exit_on_error "see ${out}"

# install python stuff
msg "NEURON: python setup and install"
cd "$nrn_repo_path/src/nrnpython"
#"$ns_python" setup.py install --prefix=$ns_install_path >> ${out} 2>&1
python3 setup.py install --prefix=$ns_install_path >> ${out} 2>&1
[ $? != 0 ] && exit_on_error "see ${out}"

cd $ns_base_path

msg "NEURON: saving environment"
save_environment neuron

