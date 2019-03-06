#!/usr/bin/env python

from math import pi
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
delay =     3.3;    # delay on connection from cell 0 to cell 1 [ms]
threshold = -10;    # spike threshold [mV]
dt =     0.0025;    # sim dt

output, params = stdarg.parse_run_stdarg()
param_vars = ['dt', 'g0', 'delay', 'threshold']
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
        soma_area = 4*pi*soma_radius**2;  # [m²]

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

cell0 = soma_cell()
cell1 = soma_cell()

stim = h.NetStim()
stim.number = 1
stim.start = 0

nc_stim = h.NetCon(stim, cell0.syn, 0, 0, g0, sec=cell0.soma)
nc0 = h.NetCon(cell0.soma(0.5)._ref_v, cell1.syn, threshold, delay, g0, sec=cell0.soma)
nc1 = h.NetCon(cell1.soma(0.5)._ref_v, None, threshold, 0, 0, sec=cell1.soma)

h.v_init = Erev

# Run model

cell0_v = h.Vector()
cell0_v.record(cell0.soma(0.5)._ref_v, sample_dt)

cell1_v = h.Vector()
cell1_v.record(cell1.soma(0.5)._ref_v, sample_dt)

sample_t = h.Vector()
sample_t.record(h._ref_t, sample_dt)

spike = [None, None]
def recorder(rec, idx):
    def f():
        if rec[idx] is None:
            rec[idx] = h.t
    return f

nc0.record(recorder(spike, 0))
nc1.record(recorder(spike, 1))

h.dt = dt
h.steps_per_ms = 1/dt # or else NEURON might noisily fudge dt
h.secondorder = 2
h.tstop = tend
h.run()

# Collect and save data

v0 = list(cell0_v)
v1 = list(cell1_v)
ts = list(sample_t)
out = xarray.Dataset({'v0': (['t0'], v0), 'v1': (['t1'], v1)}, coords={'t0': ts, 't1': ts})

out['spike0'] = np.NaN if spike[0] is None else spike[0]
out['spike1'] = np.NaN if spike[1] is None else spike[1]

for v in param_vars:
    out[v] = np.float64(globals()[v])

out.to_netcdf(output)

