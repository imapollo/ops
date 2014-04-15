#!/usr/local/bin/python
# -*- coding: utf-8 -*-
#
# Jenkins Client
#

from jenkinsapi import jenkins
import time

jclient = jenkins.Jenkins("http://int.testing.stubcorp.dev/jenkins",
            username="minjzhang", password="chinSk18w")

job_name = "com.stubhub.devops.smoketest.3"
#print jclient.get_queue_url()
#print jclient.base_server_url()
build_params = { 'pool': 'srwd83', 'site': 'UK' }
next_build_number = jclient[ job_name ].get_next_build_number()
jclient.build_job( job_name, params=build_params )
time.sleep( 10 )
build_ids = jclient[ job_name ].get_build_ids()

for build_id in build_ids:
    if ( build_id >= next_build_number ):
        build = jclient[ job_name ].get_build( build_id )
        print build.get_result_url()
    else:
        break
