import json
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

def from_json(o, key):
    if key in o:
        return o[key]
    else:
        raise Exception(str('parameter "'+ key+ '" not in input file'))

class Params:
    def __repr__(self):
        s = "parameters\n" \
            "  name         : {0:>10s}\n" \
            "  cells        : {1:10d}\n" \
            "  duration     : {2:10.0f} ms\n" \
            "  fan in       : {3:10d}\n" \
            "  min delay    : {4:10.0f} ms\n" \
            "  spike freq   : {5:13.2f} Hz\n" \
            "  integration  : {6:14.3f} times faster than realtime\n" \
            .format(self.name, self.num_cells, self.duration, self.fan_in,\
                    self.min_delay, self.spike_frequency, 1/self.realtime_ratio)
        return s

    def __init__(self, filename=None):
        if filename:
            with open(filename) as f:
                data = json.load(f)
                self.name = from_json(data, 'name')
                self.num_cells = from_json(data, 'num-cells')
                self.duration = from_json(data, 'duration')
                self.fan_in = from_json(data, 'fan-in')
                self.min_delay = from_json(data, 'min-delay')
                self.spike_frequency = from_json(data, 'spike-frequency')
                self.realtime_ratio = from_json(data, 'realtime-ratio')

        else:
            self.name = 'default'
            self.num_cells = 100
            self.duration = 100
            self.fan_in = 1000
            self.min_delay = 10
            self.spike_frequency = 20
            self.realtime_ratio = 0.1

