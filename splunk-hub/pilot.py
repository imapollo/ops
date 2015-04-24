#!/usr/local/bin/python
# -*- coding: utf-8 -*-

from pymongo import MongoClient

import commands
import json

class MongoDBClient:

    def __init__( self ):
        self.db = MongoClient( 'localhost', 27017 ).splunk

def main():
    curl_cmd = "/usr/bin/curl"
    username = "minjzhang"
    # FIXME
    password = "changeit"
    splunk_server = "https://splunk.stubcorp.dev:8089"
    saved_search = "srwd83_java_exception_log"

    search_id = commands.getoutput( "%s -k -u %s:%s -d \"search=savedsearch %s\" %s/services/search/jobs/ -d output_mode=json 2> /dev/null" %( curl_cmd, username, password, saved_search, splunk_server ) )
    search_id = json.loads( search_id )
    search_id = search_id[ "sid" ]
    # print search_id
    commands.getoutput( 'sleep 30' )
    results = commands.getoutput( "%s -k -u %s:%s %s/services/search/jobs/%s/results --get -d output_mode=json 2> /dev/null" %( curl_cmd, username, password, splunk_server, search_id ) )
    results = json.loads( results )

    mongodb = MongoDBClient()
    java_exceptions = mongodb.db.java_exceptions

    for result in results[ "results" ]:
        java_exception = {}
        java_exception[ "host" ] = result[ "host" ]
        java_exception[ "time" ] = result[ "_time"]
        java_exception[ "class" ] = result[ "stubhub_class" ]
        java_exception[ "exception_type" ] = result[ "exception_type" ]
        java_exception[ "exception_reason" ] = result[ "exception_reason" ]
        java_exception[ "message" ] = result[ "_raw" ]
        java_exceptions.insert( java_exception )

if __name__ == "__main__":
    main()
