NEURON {
    POINT_PROCESS bench
    RANGE first, frequency, rate
}

PARAMETER {
    frequency = 100 (Hz)
    rate = 1      : 1-> realtime, 0.1 -> 10x faster than realtime
    first = 0 (ms)
}

VERBATIM
#include <time.h>
ENDVERBATIM

ASSIGNED {
    spike_interval
}

STATE {}

INITIAL {
    spike_interval = 1000/frequency
    net_send(first, 42)
}

BREAKPOINT {
    VERBATIM
        struct timespec s__, e__;
        clock_gettime(CLOCK_MONOTONIC_RAW, &s__);

        /* number of nanoseconds to wait */
        /* factor of 1e6 converts ms to ns */
        long long interval_ns__ = dt*rate*1e6;

        clock_gettime(CLOCK_MONOTONIC_RAW, &e__);
        long long elapsed_ns__ = (e__.tv_sec - s__.tv_sec) * 1000000000 + (e__.tv_nsec - s__.tv_nsec);

        /* busy wait until elapsed time in ns has passed */
        while (elapsed_ns__<interval_ns__) {
            clock_gettime(CLOCK_MONOTONIC_RAW, &e__);
            elapsed_ns__ = (e__.tv_sec - s__.tv_sec) * 1000000000 + (e__.tv_nsec - s__.tv_nsec);
        }
    ENDVERBATIM
}

NET_RECEIVE(w) {
    : flag==42 implies a self-event, so go ahead and generate a spike along
    : with the next wake up call.
    if (flag==42) {
        net_send(spike_interval, 42)
        net_event(t)
    }
}
