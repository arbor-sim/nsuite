# set up path
base_path=`pwd`
install_path="$base_path"/install
build_path="$base_path"/build

. $base_path/scripts/util.sh

python_path=`cat config/python_path`
bin_path=`cat config/bin_path`
system_name=`cat config/target`

PYTHONPATH=$python_path:$PYTHONPATH
PATH=$bin_path:$PATH

msg "target system: $system_name"

. $base_path/systems/"$system_name".sh
