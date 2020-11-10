#!/usr/bin/env python

from math import pi
import sys
import os

from neuron import h
import nsuite.stdarg as stdarg
import nsuite.stdattr as stdattr
import xarray

ra =         1.0   # axial resistivity [Ω m]
rm =         4.0   # membrane resistivity [Ω m²]
cm =        0.01   # memrane specific capacitance [F/m²]
Erev =       -65   # reversal potential [mV]

diam =       1.0   # cable diameter [µm]
length =    1000   # cable length [µm]
iinj =       0.1   # current injection [nA]
sample_dt = 0.01   # [ms]

# Paramset parameters

dt =        0.05   # [ms]
n =         1000   # compartments
x0 =           0   # measurement points (proportion of length)
x1 =           1
tend =       250   # stop time [ms]

# One recognized tag: 'firstorder'

output, tags, params = stdarg.parse_run_stdarg(tagset=['firstorder'])

for v in ['dt', 'tend', 'n', 'x0', 'x1']:
    if v in params: globals()[v] = params[v]

# Don't sample at a smaller timestep than the integration timestep.
sample_dt = max(sample_dt, dt)


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

cable = h.Section(name='cable')
cable.diam = diam
cable.L= length
cable.cm = 100*cm       # [µF/cm² = 0.01 F/m²]
cable.Ra = 100*ra       # [Ω cm = 0.01 Ω m]
cable.nseg = int(n)

cable.insert('pas')
cable.g_pas = 0.0001/rm  # [S/cm² = 10000 S/m²]
cable.e_pas = Erev

stim = h.IClamp(cable(0))
stim.delay = 0
stim.dur = tend
stim.amp = iinj

h.v_init = Erev

# Run model

v0 = h.Vector()
v0.record(cable(x0)._ref_v, sample_dt)

v1 = h.Vector()
v1.record(cable(x1)._ref_v, sample_dt)

t = h.Vector()
t.record(h._ref_t, sample_dt)

h.dt = dt
h.steps_per_ms = 1/dt # or else NEURON might noisily fudge dt
if 'firstorder' in tags:
    h.secondorder = 0
else:
    h.secondorder = 2
h.tstop = tend
h.run()

# Collect and save data

out = xarray.Dataset({'v0': (['time'], list(v0)), 'v1': (['time'], list(v1))}, coords={'time': list(t)})
out.time.attrs['units'] = 'ms'
out.v0.attrs['units'] = 'mV'
out.v1.attrs['units'] = 'mV'

nrnver = h.nrnversion()
stdattr.set_stdattr(out, model='rallpack1', simulator='neuron', simulator_build=nrnver, tags=tags, params=params)

out.to_netcdf(output)

