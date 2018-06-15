# set up path
base_path=`pwd`
install_path="$base_path"/install
build_path="$base_path"/build

. $base_path/scripts/util.sh

# This will set the system_name variable to the name 
# system on which we are running.
detect_system;

msg "target system: $system_name"

. $base_path/systems/"$system_name".sh

msg "working path:  $base_path"
msg "install path:  $install_path"
msg "build path:    $build_path"

mkdir -p $base_path/build
. $base_path/scripts/build_arbor.sh
. $base_path/scripts/build_nest.sh
. $base_path/scripts/build_neuron.sh

# find and record the python and binary paths
find_paths python_path site-packages
find_paths bin_path bin

msg "python paths: $python_path"
msg "bin paths:    $bin_path"

export PYTHONPATH="$python_path:$PYTHONPATH"
export PATH="$bin_path:$PATH"

mkdir -p config

echo $python_path >> config/python_path
echo $bin_path    >> config/bin_path
echo $system_name >> config/target

