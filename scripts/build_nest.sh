cd $base_path/build

msg "NEST: starting build"

# get the code
msg "NEST: cloning"
git clone https://github.com/nest/nest-simulator.git nest
cd nest

# check out a tag/commit
nest_version="v2.14.0"
msg "NEST: checkout version $nest_version"
git checkout tags/"$nest_version"

# TODO: mpi
msg "NEST: configure build"
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX:PATH=$install_path

# make
msg "NEST: build"
make -j6

msg "NEST: install"
make install

msg "NEST: build completed"

cd $base_path
