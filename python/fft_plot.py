#!/cpd/misc/bin/python

import numpy as np
# do this before importing pylab or pyplot
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import sys


y = [float(i) for i in open(sys.argv[2]).read().split("\n")[:-1]]

samp_freq = float(sys.argv[1])

fresp = np.fft.fft(y)
f = np.linspace(0, samp_freq, len(y))
fig = plt.figure()
ax = fig.add_subplot(111)
plt.xscale('log')
plt.yscale('log')
ax.plot(f[:len(f)/2], abs(fresp[:len(f)/2]))
ax.grid(True)
fig.savefig(sys.argv[3])
