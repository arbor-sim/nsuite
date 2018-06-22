import os
import sys
import neuron

# Without neuron.gui, need to explicit load 'standard' hoc routines like 'run',
# but this is chatty on stdout, which means we get junk in our data if capturing
# output.

def hoc_setup():
    with open(os.devnull, 'wb') as null:
        fd = sys.stdout.fileno()
        keep = os.dup(fd)
        sys.stdout.flush()
        os.dup2(null.fileno(), fd)

        neuron.h('load_file("stdrun.hoc")')
        sys.stdout.flush()
        os.dup2(keep, fd)
