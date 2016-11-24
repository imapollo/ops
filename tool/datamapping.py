#!/usr/bin/python
#-*- encoding: utf-8 -*-

'''
datamapping -- cli tool to perform data mapping, by replacing old id with new id

@author:     zhangminjie
@contact:    ze.apollo@gmail.com
'''

from __future__ import print_function 
import sys
import os
import traceback
import re

from argparse import ArgumentParser
from argparse import RawDescriptionHelpFormatter
from argparse import REMAINDER

__all__ = []
__version__ = 0.1
__date__ = '2016-11-21'
__updated__ = '2016-11-21'

def get_id_map(file_path):
    file = open(file_path, 'r')
    map = {}
    for line in file:
        old_id, new_id= line.split()
        map[str(old_id)] = str(new_id)
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
    program_shortdesc ="datamapping -- cli tool to perform data mapping, by replacing old id with new id"

    try:
        # Setup argument parser
        parser = ArgumentParser(description=program_shortdesc,
            formatter_class=RawDescriptionHelpFormatter)
        parser.add_argument("-d", "--data", dest="data_file", default=None, help="data file path")
        parser.add_argument("-m", "--mapping", dest="mapping_file", default=None, help="mapping file path")
        parser.add_argument("-c", "--column", dest="column", default=1, help="column number")
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

    if (args.column == 1):
        pass
    else:
        column_pattern= "[^\\t]+\\t"
        pattern = ""
        i = 1
        while i < int(args.column):
            pattern += column_pattern
            i += 1
        pattern = "(%s)(%s)(.*)" % (pattern, "[0-9]+")

    id_map = get_id_map(args.mapping_file)
    data_file = open(args.data_file, 'r')
    for line in data_file:
        if (args.column == 1):
            match = re.match( r'([0-9]+).*', line)
            if match:
                old_id = match.group(1)
                if (old_id in id_map):
                    print(line.replace(old_id, id_map[old_id], 1), end='')
                else:
                    print("ERROR: No id [%s] in the map" % old_id)
            else:
                print("ERROR: No match on line: %s" % line)
        else:
            columns_match = re.match(r"%s" % pattern, line)
            if (columns_match):
                old_id = columns_match.group(2)
                if (old_id in id_map):
                    first_part = columns_match.group(1)
                    third_part = columns_match.group(3)
                    print(first_part + id_map[old_id] + third_part)
                else:
                    print("ERROR: No id [%s] in the map" % old_id)
            else:
                print("ERROR: No match on line: %s" % line)

if __name__ == "__main__":
    main()
