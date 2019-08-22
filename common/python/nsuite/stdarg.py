#!/usr/bin/env python

# Common argument parsing for python validation scripts.

from __future__ import print_function
import re
import sys
from collections import namedtuple

def usage(errmsg=None, errcode=1):
    prog = re.search(r'[^/]*$', sys.argv[0]).group(0)
    out = sys.stderr if errcode!=0 else sys.stdout

    if errmsg is not None:
        print(prog+': '+errmsg, file=out)
    print('Usage: '+prog+' -o output [--tag TAG]... [key=value ...]', file=out)
    print('       '+prog+' --list-tags', file=out)
    print('       '+prog+' --help', file=out)
    sys.exit(errcode)

def parse_run_stdarg(tagset=[]):
    Stdarg = namedtuple('Stdarg', ['output', 'tags', 'params'])

    output = None
    params = {}
    tags = []

    args = sys.argv[1:]
    while args:
        o = args.pop(0)
        if o == '--help':
            usage(errcode=0)
        if o == '--list-tags':
            for tag in tagset:
                print(tag)
            sys.exit(0)
        elif o == '-o':
            if not args: usage('missing argument')
            output = args.pop(0)
        elif o == '--tag':
            if not args: usage('missing argument')
            tag = args.pop(0)
            if tag not in tagset: usage('unrecognized tag: '+tag, errcode=98)
            tags.append(tag)
        else:
            m = re.fullmatch(r'\s*((?!\d)[\w_]+)\s*=\s*(.*)', o)
            if m is None: usage('unrecognized argument: '+o)
            try:
                params[m.group(1)] = float(m.group(2))
            except ValueError:
                usage('value is not a number')

    if output is None: usage('require -o')
    return Stdarg(output, tags, params)

