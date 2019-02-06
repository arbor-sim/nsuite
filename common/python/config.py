import argparse
import os

class environment:
    def __repr__(self):
        s = "-- environment -------------------------------\n" \
            "{0:20s}{1:>20d}\n" \
            "{2:20s}{3:>20s}\n" \
            "{4:20s}{5:>20s}\n" \
            "{6:20s}{7:>20s}\n" \
            "{7:20s}{8:>20s}\n" \
            "----------------------------------------------\n"\
            .format("threads", self.nthreads,
                    "mpi", 'yes' if self.mpi else 'no',
                    'output path', self.opath,
                    'parameter file', self.parameter_file if self.parameter_file else 'none',
                    'dump coreneuron', 'yes' if self.dump_coreneuron else 'no')

        return s

    def __init__(self):
        self.nthreads = 1
        self.mpi = False
        self.parameter_file = None
        self.opath = 'output'
        self.dump_coreneuron = False

def parse_clargs():
    P = argparse.ArgumentParser(description='Neuron Benchmark.')
    P.add_argument('--mpi', action='store_true',
                   help='run with mpi')
    P.add_argument('--dump', action='store_true',
                   help='dump neuron state as coreneuron input')
    P.add_argument('--param', metavar='FILE',
                   help='file with parameters for the model')
    P.add_argument('--opath', type=str, default='.',
                   help='path for output files')
    P.add_argument('--ipath', type=str, default='.',
                   help='path for input files')

    return P.parse_args()

def load_env():
    env = environment()
    if "ARB_NUM_THREADS" in os.environ:
        arg = os.environ['ARB_NUM_THREADS']
        try:
            env.nthreads = int(arg)
        except ValueError:
            print('environment error: invalid value for ARB_NUM_THREADS:', arg)

    args = parse_clargs()

    env.mpi = args.mpi
    env.parameter_file = args.param
    env.opath = args.opath
    env.ipath = args.ipath
    env.dump_coreneuron = args.dump

    return env

