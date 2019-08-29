#!/usr/bin/env python

import math
import sys
import os
import re
import tempfile
import contextlib

from neuron import h
import nsuite.stdarg as stdarg
import nsuite.stdattr as stdattr
import numpy as np
import xarray

rm =        100;    # total membrane resistance [MΩ]
cm =       0.01;    # total membrane capacitance [nF]
Erev =      -65;    # reversal potential [mV]
tau1 =      0.5;    # synapse double exponential time constants [ms]
tau2 =      4.0;
g0 =        0.1;    # synaptic conductance upon first spike arrival [µS]
mindelay =  4.0;    # minimum delay on connections from cell 0 [ms]
threshold = -10;    # spike threshold [mV]
dt =     0.0025;    # sim dt
ncell =     101;    # total number of cells

coreneuron = 0;     # run with coreneuron? 1 => yes

output, tags, params = stdarg.parse_run_stdarg(tagset=['firstorder'])
param_vars = ['dt', 'g0', 'mindelay', 'threshold', 'ncell', 'coreneuron']
for v in param_vars:
    if v in params: globals()[v] = params[v]

# 'coreneuron' isn't actually one of the standard parameters for this model,
# so remove it from params so we don't record it as such in the output.
params.pop('coreneuron', None)

outdir = os.path.dirname(output)
ncell = int(ncell)

tend = 8.
sample_dt = 0.05

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

h('load_file("stdrun.hoc")')

cell = [soma_cell() for i in range(ncell)]

stim = h.NetStim()
stim.number = 1
stim.start = 0
nc_stim = h.NetCon(stim, cell[0].syn, 0, 0, g0, sec=cell[0].soma)

nc_c2c = []
nc_record = []
delta = 0
delays = [0]

for i in range(1, ncell):
    delta += (math.sqrt(5)-1)/2
    delta -= math.floor(delta)
    delay = mindelay+delta
    delays.append(delay)

# Connection and spike recording set up differs greatly between NEURON and CoreNEURON:

if not coreneuron:
    for i in range(ncell):
        nc_record.append(h.NetCon(cell[i].soma(0.5)._ref_v, None, threshold, 0, 0, sec=cell[i].soma))

    for i in range(1, ncell):
        nc_c2c.append(h.NetCon(cell[0].soma(0.5)._ref_v, cell[i].syn, threshold, delays[i], g0, sec=cell[0].soma))

else:
    pc = h.ParallelContext()
    for i in range(ncell):
        pc.set_gid2node(i, 0)
        pc.cell(i, h.NetCon(cell[i].soma(0.5)._ref_v, None, sec=cell[i].soma))
        pc.threshold(i, threshold)

    for i in range(1, ncell):
        nc = pc.gid_connect(0, cell[i].syn)
        nc.delay = delays[i]
        nc.weight[0] = g0
        nc_c2c.append(nc)

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

for i in range(len(nc_record)):
    nc_record[i].record(recorder(spike, i))

h.dt = dt
h.steps_per_ms = 1/dt # or else NEURON might noisily fudge dt
if 'firstorder' in tags:
    h.secondorder = 0
else:
    h.secondorder = 2
h.tstop = tend

if not coreneuron:
    h.finitialize()
    h.run()

    # Collect and save data

    v0 = list(cell0_v)
    ts = list(sample_t)
    out = xarray.Dataset(
        {'v0': (['time'], v0),
         'spike': (['gid'], spike),
         'delay': (['gid'], delays)
        }, coords={'time': ts, 'gid': list(range(0,ncell))})

    out.v0.attrs['units'] = "mV"
    out.spike.attrs['units'] = "ms"
    out.delay.attrs['units'] = "ms"

    for v in param_vars:
        out[v] = np.float64(globals()[v])

    nrnver = h.nrnversion()
    stdattr.set_stdattr(out, model='rc-exp2syn-spike', simulator='neuron', simulator_build=nrnver, tags=tags, params=params)

    out.to_netcdf(output)

else:
    h.cvode.cache_efficient(1)

    pc.set_maxstep(mindelay)
    h.finitialize()

    # CoreNEURON output is always in the form of a file
    # 'out.dat' containing spike data.
    #
    # The spike data is formatted with one record per line,
    # two fields per record delimitted by tab: time (ms) and
    # gid.

    pc.nrncore_run("-e %g -o %s" % (tend, outdir))
    with open(outdir+'/out.dat') as f:
        for line in f:
            m = re.search(r'(\S+)\s*(\S+)', line)
            spike[int(m.group(2))] = float(m.group(1))

    out = xarray.Dataset(
        {'spike': (['gid'], spike),
         'delay': (['gid'], delays)
        }, coords={'gid': list(range(0,ncell))})

    out.spike.attrs['units'] = "ms"
    out.delay.attrs['units'] = "ms"

    for v in param_vars:
        out[v] = np.float64(globals()[v])

    nrnver = h.nrnversion()
    stdattr.set_stdattr(out, model='rc-exp2syn-spike', simulator='coreneuron', simulator_build=nrnver, tags=tags, params=params)

    out.to_netcdf(output)
