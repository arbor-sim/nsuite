import argparse
import os

class environment:
    def __repr__(self):
        s = "-- environment -------------------------------\n" \
            "{0:20s}{1:>20d}\n" \
            "{2:20s}{3:>20s}\n" \
            "{4:20s}{5:>20d}\n" \
            "{6:20s}{7:>20.4f}\n" \
            "{8:20s}{9:>20s}\n" \
            "{10:20s}{11:>20s}\n" \
            "{11:20s}{12:>20s}\n" \
            "----------------------------------------------\n"\
            .format("threads", self.nthreads,
                    "mpi", 'yes' if self.mpi else 'no',
                    'duration (ms)', int(self.duration),
                    'dt (ms)', self.dt,
                    'output path', self.opath,
                    'parameter file', self.parameter_file if self.parameter_file else 'none',
                    'dump coreneuron', 'yes' if self.dump_coreneuron else 'no')

        return s

    def __init__(self):
        self.nthreads = 1
        self.mpi = False
        self.dt = 0.025
        self.duration = 100
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
    P.add_argument('--dt', type=float, default=0.025,
                   help='time step size')
    P.add_argument('--opath', type=str, default='.',
                   help='path for output files')
    P.add_argument('--duration', type=float, default=100,
                   help='time step size')

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
    env.dt = args.dt
    env.opath = args.opath
    env.duration = args.duration
    env.dump_coreneuron = args.dump

    return env

