from timeit import default_timer as timer

class Meter:
    def __repr__(self):
        s = "-- meters ------------------------------------\n" \
            "{0:20s}{1:>20s}\n" \
            "----------------------------------------------\n"\
            .format("region", "time (s)")

        for i in range(len(self.checkpoints)):
            s += "{0:20s}{1:20.5f}\n".format(self.checkpoints[i], self.times[i])

        return s

    def __init__(self, filename=None):
        self.checkpoints = []
        self.times = []
        self.running = False
        self.timepoint = timer()

    def start(self):
        self.timepoint = timer()

    def checkpoint(self, name):
        end = timer()
        self.times.append(end-self.timepoint)
        self.checkpoints.append(name)
        self.timepoint = timer()
