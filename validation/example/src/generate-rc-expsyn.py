import scipy.integrate as integrate
import numpy as np
import math

rm = 100;        # total membrane resistance [MΩ]
cm = 0.01;       # total membrane capacitance [nF]
Erev = -65;      # reversal potential [mV]
syntau = 1.0;    # synapse exponential time constant [ms]
syng0 = 1.0;     # synaptic conductance at time zero [µS] 

# cm · dv/dt = - 1/rm · ( v - Erev ) - syng0 · exp(-t/syntau) · v

def membrane_conductance(t, v):
    return 1/rm + syng0*math.exp(-t/syntau)

def dv_dt(t, v):
    return -1/cm * (membrane_conductance(t, v)*v - Erev/rm)

def jacobian(t, v):
    return np.array([[-1/cm * membrane_conductance(t, v)]])

# RC time constant is rm*cm = 1 ms; simulate up to 10 ms.

#tend = 10.
tend = 3.
result = integrate.solve_ivp(dv_dt, (0., tend), [Erev], method='LSODA', jac=jacobian, atol=1e-10, rtol=1e-10, max_step=0.025)

print(result.y[0][-1])

# Compare with integrated solution

def F(t):
    tau = rm*cm
    return math.exp(-syntau*syng0*math.exp(-t/syntau)/cm+t/tau)

def integrated_v(t):
    tau = rm*cm
    r, rerr = integrate.quad(F, 0, t, epsabs=1e-10, epsrel=1e-10)
    v = Erev/F(t)*(math.exp(-syntau*syng0/cm)+r/tau)
    verr = Erev/F(t)/tau*rerr
    return (v, verr)

print(integrated_v(tend))



