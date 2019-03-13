#!/usr/bin/env python

import math
import sys
import os

from neuron import h
import nsuite.stdarg as stdarg
import numpy as np
import xarray

rm =        100;    # total membrane resistance [MΩ]
cm =       0.01;    # total membrane capacitance [nF]
Erev =      -65;    # reversal potential [mV]
tau1 =      0.5;    # synapse double exponential time constants [ms]
tau2 =      4.0;
g0 =        0.1;    # synaptic conductance upon first spike arrival [µS]
mindelay =  3.3;    # minimum delay on connections from cell 0 [ms]
threshold = -10;    # spike threshold [mV]
dt =     0.0025;    # sim dt
ncell =     101;    # total number of cells

output, params = stdarg.parse_run_stdarg()
param_vars = ['dt', 'g0', 'mindelay', 'threshold', 'ncell']
for v in param_vars:
    if v in params: globals()[v] = params[v]

tend = 8.
sample_dt = 0.05

# TODO: resolve routines below with exisiting neuron support code.

def hoc_execute_quiet(arg):
    with open(os.devnull, 'wb') as null:
        fd = sys.stdout.fileno()
        keep = os.dup(fd)
        sys.stdout.flush()
        os.dup2(null.fileno(), fd)
        h(arg)
        sys.stdout.flush()
        os.dup2(keep, fd)

def hoc_setup():
    hoc_execute_quiet('load_file("stdrun.hoc")')

# Make model

class soma_cell:
    def __init__(self):
        soma_radius = 9e-6;               # [m]
        soma_area = 4*math.pi*soma_radius**2;  # [m²]

        self.soma = h.Section(name='soma')
        self.soma.diam = 2e6*soma_radius       # [µm]
        self.soma.L = 2e6*soma_radius          # [µm]
        self.soma.cm = cm*1e-7/soma_area       # [µF/cm² = 10⁷ nF/m²]

        self.soma.insert('pas')
        self.soma.g_pas = 1e-10/(rm*soma_area) # [S/cm²]
        self.soma.e_pas = Erev

        self.syn  = h.Exp2Syn(self.soma(0.5))
        self.syn.tau1 = tau1
        self.syn.tau2 = tau2
        self.syn.e = 0

hoc_setup()

cell = [soma_cell() for i in range(ncell)]

stim = h.NetStim()
stim.number = 1
stim.start = 0

nc_stim = h.NetCon(stim, cell[0].syn, 0, 0, g0, sec=cell[0].soma)
nc_c2c = []
delta = 0
delays = [0]
for i in range(1, ncell):
    delta += (math.sqrt(5)-1)/2
    delta -= math.floor(delta)
    delay = mindelay+delta
    delays.append(delay)
    nc_c2c.append(h.NetCon(cell[0].soma(0.5)._ref_v, cell[i].syn, threshold, delay, g0, sec=cell[0].soma))

nc_record = []
for i in range(ncell):
    nc_record.append(h.NetCon(cell[i].soma(0.5)._ref_v, None, threshold, 0, 0, sec=cell[i].soma))

h.v_init = Erev

# Run model

cell0_v = h.Vector()
cell0_v.record(cell[0].soma(0.5)._ref_v, sample_dt)

sample_t = h.Vector()
sample_t.record(h._ref_t, sample_dt)

spike = [None] * ncell
def recorder(rec, idx):
    def f():
        if rec[idx] is None:
            rec[idx] = h.t
    return f

for i in range(ncell):
    nc_record[i].record(recorder(spike, i))

h.dt = dt
h.steps_per_ms = 1/dt # or else NEURON might noisily fudge dt
h.secondorder = 2
h.tstop = tend
h.run()

# Collect and save data

v0 = list(cell0_v)
ts = list(sample_t)
out = xarray.Dataset(
    {'v0': (['time'], v0),
     'spike': (['gid'], spike),
     'delay': (['gid'], delays)
    }, coords={'time': ts, 'gid': list(range(0,ncell))})

for v in param_vars:
    out[v] = np.float64(globals()[v])

out.to_netcdf(output)
