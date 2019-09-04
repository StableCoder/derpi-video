#!/usr/bin/env python

# The file to remove the 'formats' section from is given as the program's single argument

import json
import sys
import os

# Write out the json w/o the 'formats' section into the same file but appended with the '.temp'
with open(sys.argv[1]) as f:
    d = json.load(f)
    del d['formats']
    del d['thumbnails']
    del d['thumbnail']
    with open(sys.argv[1] + '.temp', 'w') as outFile:
        json.dump(d, outFile, indent=4)

# Rename that temp file back to the original file, replacing it.
os.rename(sys.argv[1] + '.temp', sys.argv[1])
