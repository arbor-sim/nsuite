import json
import argparse
import os

def parse_clargs():
    P = argparse.ArgumentParser(description='Neuron Benchmark.')
    P.add_argument('-n', '--name', type=str, default='test',
                   help='the name of the set of benchmarks.')
    P.add_argument('-c', '--cells', type=int, default=15,
                   help='2^c cells will be in the largest model.')
    P.add_argument('-d', '--depth', type=int, default=0,
                   help='depth of generated cells.')
    P.add_argument('-g', '--gencorenrn', type=bool, default=False,
                   help='generate coreneuron outputs.')
    P.add_argument('-i', '--idir', type=str, default='./input',
                   help='path for generating input files.')
    P.add_argument('-o', '--odir', type=str, default='./output',
                   help='path for generating output files.')

    return P.parse_args()

args = parse_clargs()

name = args.name
nc = args.cells
depth = args.depth
idir = args.idir + '/benchmark/ring'
odir = args.odir + '/benchmark/ring'

os.makedirs(idir, exist_ok=True)
os.makedirs(odir, exist_ok=True)

cell_range=[pow(2,x) for x in range(4,nc)]

duration=200

arb_run_fid = open('run_arb.sh', 'w')
nrn_run_fid = open('run_nrn.sh', 'w')
corenrn_run_fid = open('run_corenrn.sh', 'w')

arb_run_fid.write('odir="'+odir+'"\n')
nrn_run_fid.write('odir="'+odir+'"\n')
corenrn_run_fid.write('odir="'+odir+'"\n')

header='echo "depth %d"\necho "  cells compartments    wall(s)  throughput  mem-tot(MB) mem-percell(MB)"\n'%(depth)

corenrn_run_fid.write(header)
nrn_run_fid.write(header)
arb_run_fid.write(header)

for ncells in cell_range:
    run_name = '%s_%d_%d'%(name, ncells, depth)
    d = {
        'name': run_name,
        'num-cells': ncells,
        'synapses': 5000,
        'min-delay': 5,
        'duration': duration,
        'ring-size': 10,
        'dt': 0.025,
        'depth': depth,
        'branch-probs': [1, 0.5],
        'compartments': [20, 2],
        'lengths': [200, 20]
        }

    fname = idir+'/'+run_name+'.json'
    pfid = open(fname, 'w')
    pfid.write(json.dumps(d, indent=4))
    pfid.close()

    nrn_run_fid.write('nrn_ofile="$odir/nrn_'+run_name+'".out\n')
    nrn_run_fid.write('run_with_mpi $ns_python neuron/run.py --mpi --param %s --opath "%s" --ipath "%s" --dump > "$nrn_ofile"\n'%(fname, odir, idir))
    nrn_run_fid.write('./table_line.sh $nrn_ofile\n')

    corenrn_run_fid.write('corenrn_ofile="$odir/corenrn_'+run_name+'".out\n')
    cnrn_input_path=('%s/%s_core'%(idir, run_name))
    corenrn_run_fid.write('if [ -d "%s" ]; then\n'%(cnrn_input_path))
    corenrn_run_fid.write('  run_with_mpi coreneuron_exec -mpi -d "%s" -e %s --outpath "%s" &> "$corenrn_ofile"\n'%(cnrn_input_path, str(duration), odir))
    corenrn_run_fid.write('  ./corenrn_table_line.sh "$corenrn_ofile"\n')
    corenrn_run_fid.write('else\n')
    corenrn_run_fid.write('  echo "    %d:   run neuron to generate model input %s"\n'%(ncells, cnrn_input_path))
    corenrn_run_fid.write('fi\n')

    arb_run_fid.write('arb_ofile="$odir/arb_'+run_name+'".out\n')
    arb_run_fid.write('run_with_mpi ./arbor/run %s > $arb_ofile\n'%(fname))
    arb_run_fid.write('./table_line.sh $arb_ofile\n')

nrn_run_fid.write('echo\n')
corenrn_run_fid.write('echo\n')
arb_run_fid.write('echo\n')

nrn_run_fid.close()
arb_run_fid.close()
