# set up path
base=`pwd`
install_path="$base"/install
mkdir neuron
cd neuron

# set up environment
module swap PrgEnv-cray PrgEnv-gnu
module swap gcc/7.2.0
module load daint-mc
module load cray-python/2.7.13.1

export CC=`which cc`; export CXX=`which CC`
export CRAYPE_LINK_TYPE=dynamic

# get the code
# TODO: check out a tag/commit
git clone https://github.com/neuronsimulator/nrn
cd nrn

# TODO:
#       mpi
#       python
mkdir build; cd build;
./build.sh
config_options=--prefix="$install_path"
config_options="$config_options --without-iv"
config_options="$config_options --with-nrnpython"
#config_options="$config_options --with-mpi"

./configure $config_options

make -j6
make install

cd $base
