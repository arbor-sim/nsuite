NEURON {
    POINT_PROCESS bench
    RANGE frequency, rate
}

UNITS {
}

PARAMETER {
    frequency = 20 (Hz)
    rate = 1
    dt (ms)
}

VERBATIM
#include <time.h>
ENDVERBATIM

ASSIGNED {}

STATE {}

INITIAL {
    : calculate time for the first event
}


BREAKPOINT {
    VERBATIM
    struct timespec s__, e__;
    clock_gettime(CLOCK_MONOTONIC_RAW, &s__);

    // TODO: generate events

    /* number of nanoseconds to wait */
    /* factor of 1e6 converts ms to ns */
    long interval_ns__ = dt/rate*1e6;
    printf("waiting %d ms\n", (int)interval_ns__/1000000);

    clock_gettime(CLOCK_MONOTONIC_RAW, &e__);
    long elapsed_ns__ = (e__.tv_sec - s__.tv_sec) * 1000000000 + (e__.tv_nsec - s__.tv_nsec);

    /* busy wait until elapsed time in ns has passed */
    while (elapsed_ns__<interval_ns__) {
        clock_gettime(CLOCK_MONOTONIC_RAW, &e__);
        elapsed_ns__ = (e__.tv_sec - s__.tv_sec) * 1000000000 + (e__.tv_nsec - s__.tv_nsec);
    }
    ENDVERBATIM
}

NET_RECEIVE(weight) {}
