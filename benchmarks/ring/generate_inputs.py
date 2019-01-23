import json
import argparse

def parse_clargs():
    P = argparse.ArgumentParser(description='Neuron Benchmark.')
    P.add_argument('-s', '--sockets', type=int, default=1,
                   help='number of sockets: effectively the number to scale the model size by.')
    P.add_argument('-n', '--name', type=str, default='test',
                   help='the name of the set of benchmarks.')
    P.add_argument('-c', '--cells', type=int, default=15,
                   help='2^c cells will be in the largest model.')
    P.add_argument('-d', '--depth', type=int, default=0,
                   help='depth of generated cells.')
    P.add_argument('-g', '--gencorenrn', type=bool, default=False,
                   help='generate coreneuron outputs.')

    return P.parse_args()

args = parse_clargs()

name = args.name
ns = args.sockets
nc = args.cells
dp = args.depth

if dp==0:
    depth_range=[2, 4, 6]
else:
    depth_range=[dp]

cell_range=[pow(2,x) for x in range(4,nc)]

arb_run_fid = open('run_arb.sh', 'w')
nrn_run_fid = open('run_nrn.sh', 'w')
corenrn_run_fid = open('run_corenrn.sh', 'w')
for depth in depth_range:
    corenrn_run_fid.write('echo depth '+str(depth)+'\n')
    corenrn_run_fid.write('echo "  cells compartments    wall(s)  throughput  mem-tot(MB) mem-percell(MB)"\n')
    nrn_run_fid.write(    'echo depth '+str(depth)+'\n')
    nrn_run_fid.write(    'echo "  cells       comps     wall(s)  throughput  mem-tot(MB) mem-percell(MB)"\n')
    arb_run_fid.write(    'echo depth '+str(depth)+'\n')
    arb_run_fid.write(    'echo "  cells       comps     wall(s)  throughput  mem-tot(MB) mem-percell(MB)"\n')
    for ncells in cell_range:
        run_name = '%s_%d_%d_%d'%(name, ns, ncells, depth)
        d = {
            'name': run_name,
            'num-cells': ncells*ns,
            'synapses': 10000,
            'min-delay': 10,
            'duration': 100,
            'depth': depth,
            'branch-probs': [1, 0.5],
            'compartments': [20, 2],
            'lengths': [200, 20]
            }

        fname = './input/'+run_name+'.json'
        pfid = open(fname, 'w')
        pfid.write(json.dumps(d, indent=4))
        pfid.close()

        nrn_run_fid.write('nrn_ofile=$ns_ring_out/nrn_'+run_name+'.out\n')
        nrn_run_fid.write('run_with_mpi $ns_python neuron/run.py --mpi --param %s --opath $ns_ring_out --dump > $nrn_ofile\n'%(fname))
        nrn_run_fid.write('./table_line.sh $nrn_ofile\n')

        corenrn_run_fid.write('corenrn_ofile=$ns_ring_out/corenrn_'+run_name+'.out\n')
        corenrn_run_fid.write('run_with_mpi coreneuron_exec -mpi -e 100 -d '+run_name+'_core &> $corenrn_ofile\n')
        corenrn_run_fid.write('./corenrn_table_line.sh $corenrn_ofile\n')

        arb_run_fid.write('arb_ofile=$ns_ring_out/arb_'+run_name+'.out\n')
        arb_run_fid.write('run_with_mpi ./arbor/run %s > $arb_ofile\n'%(fname))
        arb_run_fid.write('./table_line.sh $arb_ofile\n')

    nrn_run_fid.write('echo\n')
    corenrn_run_fid.write('echo\n')
    arb_run_fid.write('echo\n')

nrn_run_fid.close()
arb_run_fid.close()
