#!/usr/bin/python
#-*- encoding: utf-8 -*-

'''
idmapping -- cli tool to perform id mapping between 2 files

@author:     zhangminjie
@contact:    ze.apollo@gmail.com
'''

import sys
import os
import traceback

from argparse import ArgumentParser
from argparse import RawDescriptionHelpFormatter
from argparse import REMAINDER

__all__ = []
__version__ = 0.1
__date__ = '2016-11-18'
__updated__ = '2016-11-18'

def get_id_name_map(file_path):
    file = open(file_path, 'r')
    map = {}
    for line in file:
        id, name = line.split()
        map[name] = id
    file.close()
    return map


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
    program_shortdesc ="idmapping - cli tool to perform id mapping between 2 files"

    try:
        # Setup argument parser
        parser = ArgumentParser(description=program_shortdesc,
            formatter_class=RawDescriptionHelpFormatter)
        parser.add_argument("-o", "--old", dest="old_file", default=None, help="old file path")
        parser.add_argument("-n", "--new", dest="new_file", default=None, help="new file path")
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
    old_map = get_id_name_map(args.old_file)
    new_map = get_id_name_map(args.new_file)

    for name in old_map:
        if name in new_map:
            print "%s %s" % (old_map[name], new_map[name])
        else:
            print "ERROR: fail to find name [%s] in new list" % name

if __name__ == "__main__":
    main()
