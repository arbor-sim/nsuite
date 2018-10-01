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

    return P.parse_args()

args = parse_clargs()

name = args.name
ns = args.sockets
nc = args.cells

arb_run_fid = open('run_arb.sh', 'w')
nrn_run_fid = open('run_nrn.sh', 'w')
#for depth in [2, 4, 6]:
for depth in [2, 4, 6]:
    for ncells in [pow(2,x) for x in range(4,nc)]:
        run_name = '%s_%d_%d_%d'%(name, ns, ncells, depth)
        d = {
            'name': run_name,
            'num-cells': ncells*ns,
            'min-delay': 10,
            'duration': 100,
            'depth': depth,
            'branch-probs': [1, 0.5],
            'compartments': [20, 2],
            'lengths': [200, 20]
            }

        fname = './input/'+run_name+'.json'
        pfid = open(fname, 'w')
        pfid.write(json.dumps(d))
        pfid.close()

        ### one rank per socket with threads_per_socket threads
        nrn_run_fid.write('ofile=$ns_ring_out/nrn_'+run_name+'.out\n')
        nrn_run_fid.write('ARB_NUM_THREADS=$ns_threads_per_socket mpirun -n $ns_sockets --map-by socket:PE=$ns_threads_per_socket $ns_python neuron/run.py --mpi --param %s --opath $ns_ring_out > $ofile\n'%(fname))
        nrn_run_fid.write('grep -e ^cell -e ^model-run $ofile\n')

        arb_run_fid.write('ARB_NUM_THREADS=$ns_threads_per_socket mpirun -n $ns_sockets --map-by socket:PE=$ns_threads_per_socket arb_ring %s | grep ^model-run\n'%(fname))
    nrn_run_fid.write('echo\n')
    arb_run_fid.write('echo\n')

nrn_run_fid.close()
arb_run_fid.close()
