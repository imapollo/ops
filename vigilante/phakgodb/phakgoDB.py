#!/usr/bin/env python
# encoding: utf-8
'''
phakgoDB - Run from crontab to collect facts from puppetdb, and store
           the information into mongo db.

@author:     minjzhang
@copyright:  2014 StubHub. All rights reserved.
@license:    Apache License 2.0
@contact:    minjzhang@ebay.com
'''

import sys
import os
import httplib, urllib
import json
import re
import time
from yaml import load

from argparse import ArgumentParser
from argparse import RawDescriptionHelpFormatter
from argparse import REMAINDER

sys.path.insert( 1, "/nas/reg/devops-vigilante/vigilante/vigillib" )

from dbapi import VigDBMongo
from api import VigilanteApi

__all__ = []
__version__ = 0.22
__date__ = '2014-07-23'
__updated__ = '2014-09-17'

PUPPET_DB_HOST = "puppetdb.stubcorp.dev"
PUPPET_DB_PORT = 8080
connection = httplib.HTTPConnection( PUPPET_DB_HOST, PUPPET_DB_PORT )

class MongoDBHelper( VigDBMongo ):
    def __init__(self):
        super(MongoDBHelper, self).__init__()

db_helper = MongoDBHelper()

def get_nodes_facts( hostnames, fact_template ):
    connection.request( "GET", "/v3/facts" )
    response = connection.getresponse()
    nodes_facts = json.loads( response.read() )

    final_facts = {}
    for fact in nodes_facts :
        if fact['certname'] in hostnames :
            hostname = fact['certname']
            if hostname in final_facts :
                pass
            else :
                final_facts[ hostname ] = {}
                final_facts[ hostname ]['body'] = {}
                final_facts[ hostname ]['meta'] = { 'type' : 'phakgoDB', 'name' : fact_template["meta"]["type"], 'version' : fact_template["meta"]["version"] }
            if fact['name'] in fact_template["body"] :
                final_facts[ hostname ]['body'][ fact['name'] ] = fact['value']
    return final_facts

def get_nodes():
    connection.request( "GET", "/v3/nodes" )
    response = connection.getresponse()
    nodes = json.loads( response.read() )
    filtered_nodes = []
    for node in nodes:
        if ( not re.match( r".*\.stubcorp\..*", node['name'] ) 
                and not re.match( r".*\.slc.*", node['name'] ) ):
            filtered_nodes.append( node['name'] )
    return filtered_nodes

def get_facts_tempalte( fact_template ):
    api = VigilanteApi('devops.stubcorp.dev', 3000)
    result = api.get_template( fact_template )
    if result == "{}" :
        print( "Error: Template [%s] not found in the system." % fact_template )
        sys.exit(1)
    template_facts = load( result )

    return template_facts

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
    program_shortdesc = "phakgoDB - crontab to collect facts from puppetdb, and store into mongodb"

    try:
        # Setup argument parser
        parser = ArgumentParser(description=program_shortdesc,
            formatter_class=RawDescriptionHelpFormatter)
        parser.add_argument("-c", "--config", dest="template", default="generic",
            help="template content get from api", metavar="FILE")
        parser.add_argument('-v', '--version', action='version', help="print the version ",
            version=program_version_message)
        parser.add_argument('-D', '--debug', dest="debug",
            action='store_true', help="turn on DEBUG switch")

        args = parser.parse_args()

        if args.debug:
            DEBUG = True
    except KeyboardInterrupt:
        ### handle keyboard interrupt ###
        return 0

    template_facts = get_facts_tempalte( args.template )
    nodes = get_nodes()
    nodes_facts = get_nodes_facts( nodes, template_facts )

    collector_space = db_helper.login()

    for node_facts_key, node_facts in nodes_facts.iteritems() :
        db_helper.insert( collector_space, node_facts )
        print ".",

if __name__ == "__main__":
    main()
