nrn_repo_path="$ns_build_path/neuron"
nrn_checked_flag="${nrn_repo_path}/checked_out"

# clear log file from previous builds
out="$ns_build_path/log_neuron"
rm -f $out

# aquire the code if it has not already been downloaded
if [ ! -f "$nrn_checked_flag" ]; then
    rm -rf "$nrn_repo_path"

    # if a git repository is set, use that
    if [ "${ns_nrn_git_repo}" != "" ]; then
        msg "NEURON: cloning from $ns_nrn_git_repo to $nrn_repo_path"
        git clone "$ns_nrn_git_repo" "$nrn_repo_path" &>> "${out}"
        [ $? != 0 ] && exit_on_error "see ${out}"

        # check out the branch
        if [ "$ns_nrn_branch" != "master" ]; then
            msg "NEURON: check out branch $ns_nrn_branch"
            cd "$nrn_repo_path"
            git checkout "$ns_nrn_branch" &>> "$out"
            [ $? != 0 ] && exit_on_error "see ${out}"
        fi
    # otherwise download an X.Y release tar ball
    else
        cd "$ns_build_path"
        nrn_tar="nrn-${ns_nrn_version}"
        nrn_src="neuron.yale.edu/ftp/neuron/versions/v${ns_nrn_version}/${nrn_tar}.tar.gz"

        msg "NEURON: download version ${ns_nrn_version} from ${nrn_src}"
        wget "$nrn_src" &>> ${out}
        [ $? != 0 ] && exit_on_error "see ${out}"

        msg "NEURON: expanding tar ball"
        tar -xzf "${nrn_tar}.tar.gz" &>> ${out}
        [ $? != 0 ] && exit_on_error "see ${out}"

        mv "${nrn_tar}" "$nrn_repo_path"
    fi

    touch "${nrn_checked_flag}"
fi

cd $nrn_repo_path

# only run configure steps if Makefile has not previously been generated.
if [ ! -f "$nrn_repo_path/Makefile" ]
then
    msg "NEURON: build.sh"

    ./build.sh &>> "${out}"
    [ $? != 0 ] && exit_on_error "see ${out}"

    config_options="--prefix=${ns_install_path} --exec-prefix=${ns_install_path}"
    config_options="$config_options --without-iv"
    config_options="$config_options --with-nrnpython=${ns_python}"
    [ "$ns_with_mpi" = "ON" ] && config_options="$config_options --with-mpi --with-paranrn"

    msg "NEURON: configure $config_options"

    ./configure $config_options &>> ${out}
    [ $? != 0 ] && exit_on_error "see ${out}"
fi

msg "NEURON: build"
make -j6 &>> ${out}
[ $? != 0 ] && exit_on_error "see ${out}"

msg "NEURON: install"
make install &>> ${out}
[ $? != 0 ] && exit_on_error "see ${out}"

# install python stuff
msg "NEURON: python setup and install"
cd "$nrn_repo_path/src/nrnpython"
python setup.py install --prefix=$ns_install_path &>> ${out}
[ $? != 0 ] && exit_on_error "see ${out}"

cd $base_path
