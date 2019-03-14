import random
from neuron import h

class cell_parameters:
    def __repr__(self):
        return 'branchy cell parameters: depth {}; branch_probs {}; compartments {}; lengths {}'\
                .format(self.max_depth, self.branch_probs, self.compartments, self.lengths)

    def __init__(self, max_depth, branch_prob, compartment, length, synapses):
        self.max_depth = max_depth          # maximum number of levels
        self.branch_probs = branch_prob     # range of branching probabilities at each level
        self.compartments = compartment     # range of compartment counts at each level
        self.lengths = length               # range of lengths of sections at each level
        self.synapses = synapses            # the nyumber of synapses per cell

def interp(r, i, n):
    p = i * 1.0/(n-1)
    return (1-p)*r[0] + p*r[1]

def printcell(c):
    print('cell with ', len(c.sections), ' levels:')
    s = ''
    for l in range(len(c.sections)):
        s += '  level {} : {} sections\n'.format(l, len(c.sections[l]))
    print(s)

#
#   Branching cell.
#   It branches, and stuff
#
class branchy_cell:
    def __repr__(self):
        s = 'cell_%d\n' % self.gid
        return s

    def __init__(self, gid, params):
        self.gid = gid

        # generate the soma
        soma = h.Section(name='soma', cell=self)
        soma.L = soma.diam = 12.6157 # Makes a soma of 500 microns squared
        soma.Ra = 100
        soma.cm = 1
        soma.insert('hh')
        for seg in soma:
            seg.hh.gnabar = 0.12  # Sodium conductance in S/cm2
            seg.hh.gkbar = 0.036  # Potassium conductance in S/cm2
            seg.hh.gl = 0.0003    # Leak conductance in S/cm2
            seg.hh.el = -54.3     # Reversal potential in mV

        self.sections = []
        self.sections.append([soma])

        self.nseg = 0
        self.ncomp = 0

        # build the dendritic tree
        nlev = params.max_depth
        random.seed(gid) # seed the random number generator on gid
        flat_section_list = [soma]
        for i in range(params.max_depth):
            level_secs = []
            count = 0
            # branch prob at this level
            bp = interp(params.branch_probs, i, params.max_depth)
            # length at this level
            l = interp(params.lengths, i, params.max_depth)
            # number of compartments at this level
            nc = round(interp(params.compartments, i, params.max_depth))

            j = 0
            for sec in self.sections[i]:
                # attempt to make some branches
                if random.uniform(0, 1) < bp:
                    for branch  in [0,1]:
                        dend = h.Section(name='dend{}_{}'.format(i, count))
                        dend.L = l      # microns
                        dend.diam = 1   # microns
                        dend.Ra = 100
                        dend.cm = 1
                        dend.nseg = nc
                        dend.insert('pas')
                        for seg in dend:
                            seg.pas.g = 0.001  # Passive conductance in S/cm2
                            seg.pas.e = -65    # Leak reversal potential mV

                        dend.connect(sec(1))
                        level_secs.append(dend)
                        flat_section_list.append(dend)
                        count += 1
                        self.ncomp += nc
                j += 1

            self.nseg += count
            if count==0:
                break

            self.sections.append(level_secs)

        self.soma = soma

        # stick a synapse on the soma
        self.synapses = [h.ExpSyn(self.soma(0.5))]
        self.synapses[0].tau = 2

        # add additional synapses that will be connected to the "ghost" network
        for i in range(1, params.synapses):
            seg = random.randint(1, self.nseg-1)
            pos = random.uniform(0, 1)
            self.synapses.append(h.ExpSyn(flat_section_list[seg](pos)))


    def set_recorder(self):
        """Set soma, dendrite, and time recording vectors on the cell.

        :param cell: Cell to record from.
        :return: the soma, dendrite, and time vectors as a tuple.
        """
        soma_v = h.Vector()   # Membrane potential vector at soma
        dend_v = h.Vector()   # Membrane potential vector at dendrite
        t = h.Vector()        # Time stamp vector
        soma_v.record(self.soma(0.5)._ref_v)
        dend_v.record(self.dend(0.5)._ref_v)
        t.record(h._ref_t)
        return soma_v, dend_v, t
