#!/usr/bin/python
# encoding: utf-8
'''
phaktor - write facter facts to a FS database

@author:     Geoff White
@copyright:  2013 StubHub. All rights reserved.
@license:    Apache License 2.0
@contact:    geowhite@stubhub.com
@suumary:    This program is a work-around until puppetDB and or mcollective come on line.
             It is designed to run on each host in the dev/QA infrastructure triggered by
             a puppet job.  When the job triggers, it will run facter ahd write JSON output 
             to a specially named file in a file system whoose root is the -r root_dir argument.
             This directory structure contains a directory for each environment, in side of each
             environment there are files assiciated to each host(role). these files contain the
             JSON string containing the autdit attributes for the role at the particular timestamp.
             the name of the file is <hostname>.<iso-time-string> where <iso-time-string> is a unique
             string mapping based on the UTC time that the facter was performed.  A symbolic link,
             <hostname> always points the the most recent output.  Previous events are saved in the
             same directory.  The last 3 by default, but this can be set to as low as 1 or a maximum
             of 20.
'''
import os
import errno
import re
import sys
import time
import socket
from yaml import load
from optparse import OptionParser

__all__ = []
__version__ = 0.92
__date__ = '2013-12-11'
__updated__ = '2014-06-20'
program_name = os.path.basename(sys.argv[0])
program_version = "v%s" % __version__
program_build_date = str(__updated__)
program_version_message = '%s %s (%s)' % (program_name, program_version,
                                                 program_build_date)
program_shortdesc ="phaktor - write facter facts to a FS database"

parser = OptionParser(version=program_version_message)
parser.add_option("-c", "--config", dest="config_file", default="generic.yaml",
                  help="file containing keys to save", metavar="FILE")
parser.add_option("-r","--root", dest="root_dir", default=None,
                  help="root directory to store events")
parser.add_option("-d","--depth", dest="depth", default=3, type="int",
                  help="number of events to keep in history")


(options, args) = parser.parse_args()

try:
    q = open(options.config_file, "r")
except IOError:
    print(" %s  : file not found or cannot open" % options.config_file)
    sys.exit()
    
facts = load( q )
event = {}

gmtime = time.gmtime()
iso_time = time.strftime("%Y-%m-%dT%H:%M:%S", gmtime)
fname_time = time.strftime(".%Y%m%dT%H%M%S", gmtime)
hostname = (socket.gethostname()).split(".")[0]

fname = hostname + fname_time
envidsp = re.search("(?P<envid>srw[dqe][0-9]{2})(?P<roleid>[a-z]{3}[0-9]{3})",fname)
if not envidsp:
    print("This is not running on a DEV system")
    sys.exit()
envid = envidsp.group("envid")
roleid = envidsp.group("roleid")


p = os.popen("facter","r")

event["iso_time"] = iso_time
for line in p.readlines():
    fsp = re.search("(?P<key>.+)=>(?P<value>.+)",line.rstrip())
    if (line.split())[0] in facts["body"]:
        event[fsp.group("key").rstrip()] = fsp.group("value").rstrip()
        
if options.root_dir:
    env_dir = os.path.abspath( options.root_dir + "/" + envid + "/" + hostname ) + "/"
    if not os.path.exists(env_dir):
        try:
            os.makedirs(env_dir)

        except OSError:
            print ("Can't make directory %s" % env_dir)
            sys.exit()
    try:
        recfd = open((env_dir + fname),"w")
    except IOError:
        print("Can't open %s " % (env_dir + fname))

    try:
        os.unlink(env_dir + "current" )
    except OSError:
        pass
    os.symlink((env_dir + fname), env_dir + "current")
    dirlist = sorted(os.listdir(env_dir),reverse=True)[:-1]
    
    if options.depth < 1:
        options.depth = 0
    elif options.depth > 20:
        options.depth = 20
    if len(dirlist) > options.depth :
        for remove_file in dirlist[options.depth: ]:
            os.remove(env_dir + remove_file)

    sys.stdout = recfd

print("{"),
# Generate the meta
print('"meta" : { "type" : "%s", "name" : "%s", "version" : "%s" },' % ( "phaktor", facts["meta"]["type"], facts["meta"]["version"]) ),
# Generate the body
print('"body" : { '),
first_item = 1
for key, value in event.iteritems():
    if ( not first_item ):
        print(","),
    print( '"%s" : "%s"' % (key, value)),
    first_item = 0
print("}"),
print("}")

sys.stdout = sys.__stdout__
sys.exit()
