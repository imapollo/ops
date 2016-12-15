#!/usr/bin/python

import time, os, threading, subprocess, re

# try this perl magic
# perl -ne 's/\x1b[[()=][;?0-9]*[0-9A-Za-z]?//g;s/\r//g;s/\007//g;print' < ss.txt

TMP_LOG_FILE_PATH = "ss.txt"
TMP_LOG_FILE = open(TMP_LOG_FILE_PATH, 'r+')
p = None
output = None

def repeat():
  print(time.ctime())
  threading.Timer(10, repeat).start()
  with open(TMP_LOG_FILE_PATH, 'w') as f:
    subprocess.call(["ls"],stdout=f)

def escape_gnu(line):
    escaped_line = re.sub("\x1b[[()=][;?0-9]*[0-9A-Za-z]?", "", line)
    escaped_line = re.sub("\r", "", escaped_line)
    escaped_line = re.sub("\n", "", escaped_line)
    escaped_line = re.sub("\007", "", escaped_line)
    return escaped_line

def parse_full_log():
    threading.Timer(5, parse_full_log).start()
    # TMP_LOG_FILE.flush()
    # lines = [escape_gnu(line.strip()) for line in TMP_LOG_FILE]
    print "-----------"
    # lines = [escape_gnu(line.strip()) for line in output]
    print p.stdout.read()
    # print output
    print "-----------"

def do_once():
    # p = subprocess.Popen("top", stdout=TMP_LOG_FILE)
    # p = subprocess.Popen("top", stdout=subprocess.PIPE, universal_newlines=True)
    print "abc"
    p = subprocess.Popen("top", stdout=subprocess.PIPE)
    print p.stdout.read()
    # for stdout_line in iter(p.stdout.readline, ""):
    #    yield stdout_line
    # p.stdout.close()
    # return_code = p.wait()

do_once()

