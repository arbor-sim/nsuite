#!/usr/bin/env python

from math import pi
import sys
import os

from neuron import h
import nsuite.stdarg as stdarg
import nsuite.stdattr as stdattr
import numpy as np
import xarray

ra =     1.0     # axial resistivity [Ω m]
rm =     4.0     # membrane resistivity [Ω m²]
cm =    0.01     # memrane specific capacitance [F/m²]
Erev =     0     # reversal potential [mV]

length = 1000.0  # cable length [µm]
iinj =    0.1    # current injection [nA]

# Parameters
d0 =      1.0  # cable diameter (left) [µm]
d1 =      1.5  # cable diameter (right) [µm]
dt =      0    # [ms]
n =       0    # number of compartments

# One recognized tag: 'firstorder'

output, tags, params = stdarg.parse_run_stdarg(tagset=['firstorder'])

for v in ['d0', 'd1', 'dt', 'n']:
    if v in params: globals()[v] = params[v]

tau = rm*cm*1000 # time constant [ms]
tend = 20*tau # transient amplitude is proportional to exp(-t/tau).
tsample = tend-dt

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
h.pt3dadd(0.0, 0.0, 0.0, d0,  sec=cable)
h.pt3dadd(length, 0.0, 0.0, d1, sec=cable)

cable.cm = 100*cm       # [µF/cm² = 0.01 F/m²]
cable.Ra = 100*ra       # [Ω cm = 0.01 Ω m]
cable.nseg = int(n)

cable.insert('pas')
cable.g_pas = 0.0001/rm  # [S/cm² = 10000 S/m²]
cable.e_pas = Erev

stim = h.IClamp(cable(1))
stim.delay = 0
stim.dur = tend
stim.amp = iinj

h.v_init = Erev

# Run model

# Take samples from the middle of each compartment.
xs = [(2.0*i+1)/(2*n) for i in range(int(n))]

tvec = h.Vector([tsample])
vrecs = []
for x in xs:
    vrecs.append(h.Vector())
    vrecs[-1].record(cable(x/length)._ref_v, tvec)

t = h.Vector()
t.record(h._ref_t, tvec)

h.dt = dt
h.steps_per_ms = 1/dt # or else NEURON might noisily fudge dt
if 'firstorder' in tags:
    h.secondorder = 0
else:
    h.secondorder = 2
h.tstop = tend
h.run()

# Collect and save data

vs = [rec.x[0] for rec in vrecs]

out = xarray.Dataset({'v': (['x'], vs), 't_sample': ([], t.x[0])}, coords={'x': list(xs)})
out.x.attrs['units'] = 'µm'
out.v.attrs['units'] = 'mV'
out.t_sample.attrs['units'] = 'ms'

nrnver = h.nrnversion()
stdattr.set_stdattr(out, model='cable-steadystate', simulator='neuron', simulator_build=nrnver, tags=tags, params=params)

out.to_netcdf(output)
