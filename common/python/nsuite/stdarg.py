#!/usr/bin/env python

# Common argument parsing for python validation scripts

from __future__ import print_function
import re
import sys
from collections import namedtuple

usage_stdarg = 'output [key=value ...]'

def usage_error(errmsg=None, usagestr=usage_stdarg):
    prog = re.search(r'[^/]*$', sys.argv[0]).group(0)
    if errmsg is not None:
        print(prog+': '+errmsg, file=sys.stderr)
    print('Usage: '+prog+' '+usagestr, file=sys.stderr)
    sys.exit(1)

def parse_run_stdarg():
    if len(sys.argv)<2:
        usage_error('missing output file')

    Stdarg = namedtuple('Stdarg', ['output', 'params'])

    params = {}
    for arg in sys.argv[2:]:
        m = re.fullmatch(r'\s*((?!\d)[\w_]+)\s*=\s*(.*)', arg)
        if m is None: usage()
        try:
            params[m.group(1)] = float(m.group(2))
        except ValueError:
            usage('value is not a number')

    return Stdarg(sys.argv[1], params)

