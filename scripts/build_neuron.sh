cd $base_path/build

msg "NEURON: starting build"

# get the code
msg "NEURON: cloning"
git clone https://github.com/neuronsimulator/nrn neuron
cd neuron

# TODO: currently just using master on the development repo, because
#       there are no release tags. Maybe download the source?

msg "NEURON: configure"
./build.sh
config_options=--prefix="$install_path"
config_options="$config_options --without-iv"
config_options="$config_options --with-nrnpython"
# TODO: mpi
#config_options="$config_options --with-mpi"
./configure $config_options

msg "NEURON: build"
make -j6

msg "NEURON: install"
make install

# install python stuff
msg "NEURON: python setup and install"
cd src/nrnpython
python setup.py install --prefix=$install_path

export PYTHONPATH=$install_path/lib/python3.6/site-packages/

cd $base
