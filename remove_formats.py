#!/usr/bin/env python

import json

with open('a.json') as f:
    d = json.load(f)
    d['formats'] = []
    with open('b.json', 'w') as outFile:
        json.dump(d, outFile)
