from neuron import h

h('load_file("stdrun.hoc")')

soma = h.Section(name='soma')

bench = h.bench(soma(0.5))
print('benchmark freq: ', bench.frequency)
print('benchmark rate: ', bench.rate)
