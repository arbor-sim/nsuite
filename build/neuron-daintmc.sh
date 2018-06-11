. ./daintmc.sh

# set up path
base=`pwd`
install_path="$base"/install
mkdir neuron
cd neuron

msg "building NEURON to install at $install_path"

# set up environment
load_modules

# get the code
# TODO: check out a tag/commit
msg "clone code"
git clone https://github.com/neuronsimulator/nrn
cd nrn

# TODO:
#       mpi
#       python
msg "configure build"
./build.sh
config_options=--prefix="$install_path"
config_options="$config_options --without-iv"
config_options="$config_options --with-nrnpython"
#config_options="$config_options --with-mpi"

./configure $config_options

msg "build"
make -j6
msg "install"
make install

cd $base
