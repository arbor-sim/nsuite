#!/usr/bin/env python

from math import pi
import sys
import os

from neuron import h
import nsuite.stdarg as stdarg
import nsuite.stdattr as stdattr
import xarray

rm =     100;    # total membrane resistance [MΩ]
cm =    0.01;    # total membrane capacitance [nF]
Erev =   -65;    # reversal potential [mV]
syntau = 1.0;    # synapse exponential time constant [ms]
g0 =     0.1;    # synaptic conductance at time zero [µS] 
dt = 0.0025

sample_dt = 0.05
tend = 10

# One recognized tag: 'firstorder'

output, tags, params = stdarg.parse_run_stdarg(tagset=['firstorder'])
for v in ['dt', 'g0']:
    if v in params: globals()[v] = params[v]

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

hoc_setup()

soma_radius = 9e-6;               # [m]
soma_area = 4*pi*soma_radius**2;  # [m²]

soma = h.Section(name='soma')
soma.diam = 2e6*soma_radius       # [µm]
soma.L = 2e6*soma_radius          # [µm]
soma.cm = cm*1e-7/soma_area       # [µF/cm² = 10⁷ nF/m²]

soma.insert('pas')
soma.g_pas = 1e-10/(rm*soma_area) # [S/cm²]
soma.e_pas = Erev

syn  = h.ExpSyn(soma(0.5))
syn.tau = syntau
syn.e = 0

stim = h.NetStim()
stim.number = 1
stim.start = 0
nc = h.NetCon(stim, syn, 0, 0, g0)

h.v_init = Erev

# Run model

soma_v = h.Vector()
soma_v.record(soma(0.5)._ref_v, sample_dt)
soma_t = h.Vector()
soma_t.record(h._ref_t, sample_dt)

h.dt = dt
h.steps_per_ms = 1/dt # or else NEURON might noisily fudge dt
if 'firstorder' in tags:
    h.secondorder = 0
else:
    h.secondorder = 2
h.tstop = tend
h.run()

# Collect and save data

out = xarray.Dataset({'voltage': (['time'], list(soma_v))}, coords={'time': list(soma_t)})
out.voltage.attrs['units'] = 'mV'
out.time.attrs['units'] = 'ms'

nrnver = h.nrnversion()
stdattr.set_stdattr(out, model='rc-expsyn', simulator='neuron', simulator_build=nrnver, tags=tags, params=params)
out.to_netcdf(output)

