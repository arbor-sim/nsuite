# set up path
base=`pwd`
install_path="$base"/install
mkdir nest
cd nest

# set up environment
module swap PrgEnv-cray PrgEnv-gnu
module swap gcc/7.2.0
module load daint-mc
module load cray-python/2.7.13.1
module load PyExtensions/2.7.13.1-CrayGNU-17.08 # for cython

export CC=`which cc`; export CXX=`which CC`
export CRAYPE_LINK_TYPE=dynamic

# get the code
# TODO: check out a tag/commit
git clone https://github.com/nest/nest-simulator.git --recursive
mv nest-simulator nest
cd nest

# configure

# TODO: python mpi
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX:PATH=$install_path

# make
make -j6
make install

cd $base
