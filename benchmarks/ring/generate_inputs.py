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

for ncells in [pow(2,x) for x in range(nc)]:
    for depth in [2, 4, 8]:
        run_name = '%s_%d_%d_%d'%(name, ns, ncells, depth)
        d = {
            'name': run_name,
            'num-cells': ncells*ns,
            'min-delay': 10,
            'duration': 500,
            'depth': depth,
            'branch-probs': [1, 0.5],
            'compartments': [20, 2],
            'lengths': [200, 20]
            }

        fid = open(run_name+'.json', 'w')
        fid.write(json.dumps(d))
        fid.close()
