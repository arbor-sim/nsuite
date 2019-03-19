import json
import argparse
import os

def parse_clargs():
    P = argparse.ArgumentParser(description='Neuron Benchmark.')
    P.add_argument('-c', '--config', type=str, default='',
                   help='file with configuration of the benchmark.')
    P.add_argument('-i', '--idir', type=str, default='./input',
                   help='path for the generated input files.')
    P.add_argument('-o', '--odir', type=str, default='./output',
                   help='path for output generated by benchmarks.')
    P.add_argument('-b', '--bdir', type=str, default='.',
                   help='path of the benchmark engine.')
    P.add_argument('-e', '--edir', type=str, default='.',
                   help='the path with the environment configurations for the simulators.')
    P.add_argument('-s', '--sdir', type=str, default='.',
                   help='the path of the nsuite bash scripts.')

    return P.parse_args()

# parse command line args
args = parse_clargs()

# load the configuration file
conf_file = args.config

# parse parameters from config file
conf_fid=open(conf_file).read()
conf_dat = json.loads(conf_fid)
depth = conf_dat['depth']       # depth of cell
synapses = conf_dat['synapses']       # depth of cell
# The same benchmark will be run multiple times, with an increasing
# number of cells in each run. The min-cells and max-cells parameters
# describe the range of model sizes.
cb = range(conf_dat['min-cells'], conf_dat['max-cells']+1)
cell_range=[pow(2,x) for x in cb]
duration=200                    # simulation duration (ms)

# find the current directory

# make the directories for the input and output for this model.
idir = args.idir
odir = args.odir
bdir = args.bdir
os.makedirs(idir, exist_ok=True)
os.makedirs(odir, exist_ok=True)

# the path containing simulator-specific scripts that set up the environment for the benchmark
envdir    = args.edir # path with environments for each simulation engine
scriptdir = args.sdir # nsuite bash scripts

arb_run_fid = open('%s/run_arb.sh'%(idir), 'w')
nrn_run_fid = open('%s/run_nrn.sh'%(idir), 'w')
cnr_run_fid = open('%s/run_corenrn.sh'%(idir), 'w')

arb_run_fid.write('source "%s/env_arbor.sh"\n'%(envdir))
nrn_run_fid.write('source "%s/env_neuron.sh"\n'%(envdir))
cnr_run_fid.write('source "%s/env_coreneuron.sh"\n'%(envdir))

arb_run_fid.write('source "%s/bench_output.sh"\n'%(scriptdir))
nrn_run_fid.write('source "%s/bench_output.sh"\n'%(scriptdir))
cnr_run_fid.write('source "%s/bench_output.sh"\n'%(scriptdir))

# todo: remove hard coding of simulator-specific output paths
arb_run_fid.write('odir="%s/arbor"\n'%(odir))
nrn_run_fid.write('odir="%s/neuron"\n'%(odir))
cnr_run_fid.write('odir="%s/coreneuron"\n'%(odir))
# make output paths if they don't exist, and clean them.
arb_run_fid.write('mkdir -p "$odir"\n')
nrn_run_fid.write('mkdir -p "$odir"\n')
cnr_run_fid.write('mkdir -p "$odir"\n')
arb_run_fid.write('rm -f "$odir/*"\n')
nrn_run_fid.write('rm -f "$odir/*"\n')
cnr_run_fid.write('rm -f "$odir/*"\n')

# quit early if required simulation engine is not in path
arb_run_fid.write('[[ ! $(type -P arbor-busyring) ]]  && echo "Arbor needs to be installed before running benchmark"      && exit\n')
nrn_run_fid.write('[[ ! $(type -P nrniv) ]]           && echo "NEURON needs to be installed before running benchmark"     && exit\n')
cnr_run_fid.write('[[ ! $(type -P coreneuron_exec) ]] && echo "CoreNeuron needs to be installed before running benchmark" && exit\n')

# quit early if required simulation engine is not in path
arb_run_fid.write('[[ ! $(type -P arbor-busyring) ]]  && echo "Arbor needs to be installed before running benchmark"      && exit\n')
nrn_run_fid.write('[[ ! $(type -P nrniv) ]]           && echo "NEURON needs to be installed before running benchmark"     && exit\n')
cnr_run_fid.write('[[ ! $(type -P coreneuron_exec) ]] && echo "CoreNeuron needs to be installed before running benchmark" && exit\n')

header='echo "  cells compartments    wall(s)  throughput  mem-tot(MB) mem-percell(MB)"\n'
cnr_run_fid.write(header)
nrn_run_fid.write(header)
arb_run_fid.write(header)

for ncells in cell_range:
    run_name = 'run_%d_%d'%(ncells, depth)
    d = {
        'name': run_name,
        'num-cells': ncells,
        'synapses': synapses,
        'min-delay': 5,
        'duration': duration,
        'ring-size': 10,
        'dt': 0.025,
        'depth': depth,
        'branch-probs': [1, 0.5],
        'compartments': [20, 2],
        'lengths': [200, 20],
        }

    fname = idir+'/'+run_name+'.json'
    pfid = open(fname, 'w')
    pfid.write(json.dumps(d, indent=4))
    pfid.close()

    nrn_run_fid.write('nrn_ofile="$odir/%s".out\n'%(run_name))
    nrn_run_fid.write('run_with_mpi $ns_python "%s/neuron/run.py" --mpi --param %s --opath "$odir" --ipath "%s" --dump > "$nrn_ofile"\n'%(bdir, fname, idir))
    nrn_run_fid.write('table_line $nrn_ofile\n')

    # coreneuron is more difficult than the others to run robustly:
    #   * it requires input that we have to generate using NEURON
    #   * it is a binary with a fixed interface, so for example
    #     we can't find a way to store the spikes in a file that
    #     isn't called "out.dat" in the path where the executable was run.
    cnr_run_fid.write('corenrn_ofile="$odir/%s".out\n'%(run_name))
    cnrn_input_path=('%s/%s_core'%(idir, run_name))
    cnr_run_fid.write('if [ -d "%s" ]; then\n'%(cnrn_input_path))
    cnr_run_fid.write('  run_with_mpi coreneuron_exec -mpi -d "%s" -e %s --outpath "$odir" &> "$corenrn_ofile"\n'%(cnrn_input_path, str(duration)))
    cnr_run_fid.write('  coreneuron_table_line "$corenrn_ofile"\n')
    cnr_run_fid.write('  [ -f "$odir/out.dat" ] && mv "$odir/out.dat" "$odir/%s_spikes.dat"\n'%(run_name))
    cnr_run_fid.write('else\n')
    cnr_run_fid.write('  echo "    %d:   run neuron to generate model input %s"\n'%(ncells, cnrn_input_path))
    cnr_run_fid.write('fi\n')

    arb_run_fid.write('arb_ofile="$odir/%s".out\n'%(run_name))
    arb_run_fid.write('run_with_mpi arbor-busyring "%s" "$odir" > $arb_ofile\n'%(fname))
    arb_run_fid.write('table_line $arb_ofile\n')

nrn_run_fid.write('echo\n')
cnr_run_fid.write('echo\n')
arb_run_fid.write('echo\n')

arb_run_fid.write('%s/csv_bench.sh --path="$odir"\n'%(scriptdir))
nrn_run_fid.write('%s/csv_bench.sh --path="$odir"\n'%(scriptdir))
cnr_run_fid.write('%s/csv_bench.sh --path="$odir" --coreneuron\n'%(scriptdir))

nrn_run_fid.close()
arb_run_fid.close()
