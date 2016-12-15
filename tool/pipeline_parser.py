#!/usr/bin/python
# parse from stdin line by line, escape gnu characters

import time, os, sys, re

for line in sys.stdin:
    escaped_line = re.sub("\x1b[[()=][;?0-9]*[0-9A-Za-z]?", "", line)
    escaped_line = re.sub("\r", "", escaped_line)
    escaped_line = re.sub("\n", "", escaped_line)
    escaped_line = re.sub("\007", "", escaped_line)
    print escaped_line
