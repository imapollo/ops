#!/usr/bin/python

import os
import io
import time
import subprocess
import sys
import re
import tempfile
import signal

# Parse output from screen to json
class ScreenParser(object):

    TMP_FILE_NAME = tempfile.NamedTemporaryFile().name

    # Note:
    # override this method to handle lines
    # lines: all the lines from the screen
    def handle_output(self, lines):
        pass

    def signal_handler(self, signal, frame):
        os.remove(self.TMP_FILE_NAME)
        sys.exit(0)

    def escape_gnu(self, line):
        escaped_line = re.sub("\x1b[[()=][;?0-9]*[0-9A-Za-z]?", "", line)
        escaped_line = re.sub("\x00", "", escaped_line)
        escaped_line = re.sub("\r", "", escaped_line)
        escaped_line = re.sub("\n", "", escaped_line)
        escaped_line = re.sub("\007", "", escaped_line)
        return escaped_line

    def execute(self, commands, interval=2):
        # catch signal
        signal.signal(signal.SIGINT, self.signal_handler)

        writer = io.open(self.TMP_FILE_NAME, 'w')
        with io.open(self.TMP_FILE_NAME, 'r', 1) as reader:
            process = subprocess.Popen(commands, stdout=writer)
            while process.poll() is None:
                lines = reader.read()
                io.open(self.TMP_FILE_NAME, 'w').close()
                if lines:
                    escaped_lines = [self.escape_gnu(line) for line in lines.split("\n")]
                    self.handle_output(escaped_lines)
                time.sleep(interval)


