#!/usr/bin/python

import io
import time
import subprocess
import sys
import re

TMP_FILE_NAME = 'test.log'

def escape_gnu(line):
    escaped_line = re.sub("\x1b[[()=][;?0-9]*[0-9A-Za-z]?", "", line)
    escaped_line = re.sub("\r", "", escaped_line)
    escaped_line = re.sub("\n", "", escaped_line)
    escaped_line = re.sub("\007", "", escaped_line)
    return escaped_line

# TODO
# 1. demo to parse top to json
# 2. resolve file growing too large issue

def handle_output(lines):
    output_file = open("test2.log", "a")
    for line in lines:
        if "mongo" in line:
            output_file.write("%s\n" % line)
    output_file.close()

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

