#!/usr/bin/env python
# encoding: utf-8
'''
env-audit -- cli tool to perform auditing operations on Dev/QA collection data

jclose is a CLI based tool that allows you to close a JIRA issue from any
         CLI that can access the JIRA server.  All that is required is your
         JIRA login and the Issue ID. This program uses jiralab.auth so it
         will cache your password in an encrypted file so that you don't have
         to keep entering it, for subsequent commands. If you pipe input into
         stdin, this input will show up in the comment field of the issue
         between two {code} tags.

@author:     geowhite
@copyright:  2014 StubHub. All rights reserved.
@license:    Apache License 2.0
@contact:    geowhite@stubhub.com
'''

import sys
import os


from argparse import ArgumentParser
from argparse import RawDescriptionHelpFormatter
from argparse import REMAINDER

__all__ = []
__version__ = 0.1
__date__ = '2014-06-09'
__updated__ = '2014-06-09'


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
    program_shortdesc ="env-audit - get audit information for Dev/QA environments"

    try:
        # Setup argument parser
        parser = ArgumentParser(description=program_shortdesc,
            formatter_class=RawDescriptionHelpFormatter)
        parser.add_argument("-e", "--env", dest="envid",
            default=None, help="target environment")
        parser.add_argument("-t", "--template", dest="template",
            default=None, help="template to use for auditing")
        parser.add_argument("-r", "--role", dest="role",
            default=None, help="fqdn of the role  to be used ")
        parser.add_argument('-l', '--list', action='store_true', help="list the template or collection data ",
            dest="list" )
        parser.add_argument('-v', '--version', action='version', help="print the version ",
            version=program_version_message)
        parser.add_argument('-D', '--debug', dest="debug",
            action='store_true', help="turn on DEBUG switch")

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
#    except Exception, e:
#        if DEBUG :
#            raise(e)
#        indent = len(program_name) * " "
#        sys.stderr.write(program_name + ": " + str(e) + "\n")
#        sys.stderr.write(indent + "  for help use --help\n")
#        return 2


if __name__ == "__main__":
    main()
