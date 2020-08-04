model="$1"
config="$2"
base_path="$3"
env_path="$4"
input_base="$5"
output_base="$6"
output_fmt="$7"

input_path="$input_base/$model/$config"

config_json="`pwd`/$config.json"
engine=$(< engine)

[ ! -f "$config_json" ] && err "unable to find configuration file \"$config_json\"" && exit 1;

engine_path="$base_path/benchmarks/engines/$engine"
generator="$engine_path/generate_inputs.py"

# Generate output directory from template:
declare -a fmtkeys
fmtkeys=("T=$ns_timestamp" "S=$ns_sysname" "m=$model" "p=$config")
fmtkeys+=("H=$(git-repo-hash)" "h=$(git-repo-hash --short)")

for sim in arbor neuron coreneuron; do
    path=$(pathsub --base="$output_base" s="$sim" "${fmtkeys[@]}" -- "$output_fmt")
    printf -v "output_dir_$sim" %s "$path"
done

python3 "$generator" --idir "$input_path" --odir-arbor "$output_dir_arbor" --odir-neuron "$output_dir_neuron" --odir-coreneuron "$output_dir_coreneuron" --config "$config_json" --bdir "$engine_path" --sdir "$base_path/scripts" --edir="$env_path"

chmod +x "$input_path/run_arb.sh"
chmod +x "$input_path/run_nrn.sh"
chmod +x "$input_path/run_corenrn.sh"
