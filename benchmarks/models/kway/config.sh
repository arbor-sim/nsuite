config=$1
base_path=$2
input_path=$3
output_path=$4
prefix=$5

config_json="`pwd`/$config.json"

[ ! -f "$config_json" ] && err "unable to find configuration file \"$config_json\"" && exit 1;

config_name="ring-$config"

engine_path="$base_path/benchmarks/engines/busyring"
generator="$engine_path/generate_inputs.py"

python3 "$generator" --idir "$input_path" --odir "$output_path" --config "$config_json" --bdir "$engine_path" --prefix "$prefix" --sdir "$base_path/scripts"

chmod +x "$input_path/run_arb.sh"
chmod +x "$input_path/run_nrn.sh"
chmod +x "$input_path/run_corenrn.sh"
