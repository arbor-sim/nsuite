NEURON {
    POINT_PROCESS bench
    RANGE first, frequency, rate
}

UNITS {
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
        //printf("waiting %d ms on %d\n", (int)interval_ns__/1000000, (int)instance);

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
    if (flag==42) {
        VERBATIM
            //printf("generate spike at t = %g flag %g\n", t, _lflag);
        ENDVERBATIM
        net_send(spike_interval, 42)
        net_event(t)
    }
    else {
        VERBATIM
            //static int frog_pop__ = 0;
            //++frog_pop__;
            //printf("received event %d at t = %g\n", frog_pop__, t);
        ENDVERBATIM
    }
}
