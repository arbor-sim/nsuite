config="$1"
base_path="$2"
env_path="$3"
input_base="$4"
output_base="$5"
run_name="$6"

input_path="$input_base/$run_name"
output_path="$output_base/$run_name"

config_json="`pwd`/$config.json"

[ ! -f "$config_json" ] && err "unable to find configuration file \"$config_json\"" && exit 1;

config_name="ring-$config"

engine_path="$base_path/benchmarks/engines/busyring"
generator="$engine_path/generate_inputs.py"

python3 "$generator" --idir "$input_path" --odir "$output_path" --config "$config_json" --bdir "$engine_path" --sdir "$base_path/scripts" --edir="$env_path"

chmod +x "$input_path/run_arb.sh"
chmod +x "$input_path/run_nrn.sh"
chmod +x "$input_path/run_corenrn.sh"
