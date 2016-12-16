#!/usr/bin/python

import io
import time
import subprocess
import sys
import re

TMP_FILE_NAME = 'test.log'

def escape_gnu(line):
    escaped_line = re.sub("\x1b[[()=][;?0-9]*[0-9A-Za-z]?", "", line)
    escaped_line = re.sub("\x00", "", escaped_line)
    escaped_line = re.sub("\r", "", escaped_line)
    escaped_line = re.sub("\n", "", escaped_line)
    escaped_line = re.sub("\007", "", escaped_line)
    return escaped_line

# TODO
# 2. resolve file growing too large issue

def handle_output(lines):
    results = []
    for line in lines:
        line = re.sub("\s+", " ", line)
        line = re.sub("^ ", "", line)
        if line.startswith("top -") \
            or line.startswith("Tasks:") \
            or line.startswith("Cpu(s):") \
            or line.startswith("Mem:") \
            or line.startswith("Swap:") \
            or line.startswith("PID"):
                continue
        elements = line.split(" ")
        if (len(elements) > 1):
            result = {}
            result["pid"] = elements[0]
            result["user"] = elements[1]
            results.append(result)
    print results

writer = io.open(TMP_FILE_NAME, 'w')
with io.open(TMP_FILE_NAME, 'r', 1) as reader:
    process = subprocess.Popen("top", stdout=writer)
    while process.poll() is None:
        lines = reader.read()
        if lines:
            escaped_lines = [escape_gnu(line) for line in lines.split("\n")]
            handle_output(escaped_lines)
        time.sleep(2)

    # Skip the remaining

