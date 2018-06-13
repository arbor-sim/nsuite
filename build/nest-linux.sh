source ./linux.sh

# set up path
base=`pwd`
install_path="$base"/install
mkdir nest
cd nest

msg "building NEST to install at $install_path"

# get the code
# TODO: check out a tag/commit
msg "clone code"
git clone https://github.com/nest/nest-simulator.git --recursive
cd nest-simulator

# configure

# TODO: python if not by default
msg "configure build"
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX:PATH=$install_path

# make
msg "build"
make -j6
msg "install"
make install

cd $base
