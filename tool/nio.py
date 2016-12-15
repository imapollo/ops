#!/usr/bin/python

import os
import sys
import time
import fcntl
import subprocess

def async_read(fd):
    # set non-blocking flag while preserving old flags
    fl = fcntl.fcntl(fd, fcntl.F_GETFL)
    fcntl.fcntl(fd, fcntl.F_SETFL, fl | os.O_NONBLOCK)
    # read char until EOF hit
    chs = []
    i = 1
    while True:
        try:
            ch = os.read(fd.fileno(), 1)
            # EOF
            if not ch:
                break
            print ch
            #sys.stdout.write(ch)
            chs.append(ch)
        except OSError:
            # waiting for data be available on fd
            pass

def shell(args, async=True):
    # merge stderr and stdout
    proc = subprocess.Popen(args, shell=False, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    if async: async_read(proc.stdout)
    sout, serr = proc.communicate()
    return (sout, serr)

if __name__ == '__main__':
    cmd = 'top'
    sout, serr = shell(cmd.split())

