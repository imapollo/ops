#!/usr/bin/python

import os
import io
import time
import subprocess
import sys
import re
import tempfile
import signal

TMP_FILE_NAME = tempfile.NamedTemporaryFile().name

writer = io.open(TMP_FILE_NAME, 'w')

def signal_handler(signal, frame):
    os.remove(TMP_FILE_NAME)
    sys.exit(0)

def escape_gnu(line):
    escaped_line = re.sub("\x1b[[()=][;?0-9]*[0-9A-Za-z]?", "", line)
    escaped_line = re.sub("\x00", "", escaped_line)
    escaped_line = re.sub("\r", "", escaped_line)
    escaped_line = re.sub("\n", "", escaped_line)
    escaped_line = re.sub("\007", "", escaped_line)
    return escaped_line

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

# catch signal
signal.signal(signal.SIGINT, signal_handler)

with io.open(TMP_FILE_NAME, 'r', 1) as reader:
    process = subprocess.Popen("top", stdout=writer)
    while process.poll() is None:
        lines = reader.read()
        io.open(TMP_FILE_NAME, 'w').close()
        if lines:
            escaped_lines = [escape_gnu(line) for line in lines.split("\n")]
            handle_output(escaped_lines)
        time.sleep(2)

