#!/usr/bin/python
#-*- encoding: utf-8 -*-

'''
reporter -- check the homework with member list and generate report

@author:     zhangminjie
@contact:    ze.apollo@gmail.com
'''

import sys
import os
import traceback
import re

from argparse import ArgumentParser
from argparse import RawDescriptionHelpFormatter
from argparse import REMAINDER

__all__ = []
__version__ = 0.1
__date__ = '2016-11-18'
__updated__ = '2016-11-18'

def get_members_map(file_path):
    file = open(file_path, 'r')
    members_map = {}
    for line in file:
        line = line.replace("\n", "")
        members_map[line] = 0
    return members_map

def get_homework_filenames_map(dir_path):
    file_list_tmp = os.listdir(dir_path)
    file_list = {}
    for item in file_list_tmp:
        file_list[item] = 0
    return file_list

def main(argv=None):  # IGNORE:C0111
    '''Command line options.'''
    DEBUG = 0
    if argv is None:
        argv = sys.argv
    else:
        sys.argv.extend(argv)

    program_name = os.path.basename(sys.argv[0])
    program_version = "v%s" % __version__
    program_build_date = str(__updated__)
    program_version_message = '%%(prog)s %s (%s)' % (program_version,
            program_build_date)
    program_shortdesc ="reporter -- check the homework with member list and generate report"

    try:
        # Setup argument parser
        parser = ArgumentParser(description=program_shortdesc,
            formatter_class=RawDescriptionHelpFormatter)
        parser.add_argument("-m", "--member", dest="member_list", default=None, help="group member list")
        parser.add_argument("-d", "--dir", dest="homework_dir", default=None, help="homework directory")
        parser.add_argument('-D', '--debug', dest="debug", action='store_true', help="turn on DEBUG switch")
        parser.add_argument('-v', '--version', action='version', help="print the version ",
            version=program_version_message)

        # Process arguments
        if len(sys.argv) == 1:
            parser.print_help()
            exit(1)

        args = parser.parse_args()

        if args.debug:
            DEBUG = True
    except KeyboardInterrupt:
        ### handle keyboard interrupt ###
        return 0
    except Exception, e:
        if DEBUG :
            raise(e)
        indent = len(program_name) * " "
        sys.stderr.write(program_name + ": " + str(e) + "\n")
        sys.stderr.write(indent + "  for help use --help\n")
        return 2

    # traceback.print_exc()
    members_map = get_members_map(args.member_list)
    homework_map = get_homework_filenames_map(args.homework_dir)
    abnormal_files = []
    print "Members count: %s" % len(members_map)
    print "Homework count: %s" % len(homework_map)
    for filename in homework_map:
        match = re.match(r'【(.*)】【(.*)】【(.*)】.*', filename)
        if (match and match.group(1) in members_map):
            member_name = match.group(1)
            members_map[member_name]= 1
            homework_map[filename]= 1
        else:
            abnormal_files.append(filename)

    print "\nMember homework list:"
    for member in members_map:
        print "%s\t%s" % (member, members_map[member])

    print "\nAbnormal homework list:"
    for filename in abnormal_files:
        print filename

if __name__ == "__main__":
    main()
