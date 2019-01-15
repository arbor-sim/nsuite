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
for depth in depth_range:
    nrn_run_fid.write('echo depth '+str(depth)+'\n')
    nrn_run_fid.write('echo "  cells       comps        wall  throughput"\n')
    arb_run_fid.write('echo depth '+str(depth)+'\n')
    arb_run_fid.write('echo "  cells       comps        wall  throughput"\n')
    for ncells in cell_range:
        run_name = '%s_%d_%d_%d'%(name, ns, ncells, depth)
        d = {
            'name': run_name,
            'core-path': run_name+'_core',
            'num-cells': ncells*ns,
            'synapses': 1000,
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
        nrn_run_fid.write('run_with_mpi $ns_python neuron/run.py --mpi --param %s --opath $ns_ring_out > $nrn_ofile\n'%(fname))
        nrn_run_fid.write('./table_line.sh $nrn_ofile\n')

        arb_run_fid.write('arb_ofile=$ns_ring_out/arb_'+run_name+'.out\n')
        arb_run_fid.write('run_with_mpi arb_ring %s > $arb_ofile\n'%(fname))
        arb_run_fid.write('./table_line.sh $arb_ofile\n')

    nrn_run_fid.write('echo\n')
    arb_run_fid.write('echo\n')

nrn_run_fid.close()
arb_run_fid.close()
