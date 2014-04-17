#!/usr/local/bin/python
# -*- coding: utf-8 -*-
#
# Jenkins Client
#

from jenkinsapi import jenkins
import time

#
# Jenkins Client
#
class JenkinsClient:

    # Initiate the client.
    def __init__( self, jenkins_url ):
        self.jenkins_username = 'minjzhang'
        jenkins_password = 'chinSk18w'
        self.jclient = jenkins.Jenkins( jenkins_url,
                username=self.jenkins_username, password=jenkins_password)

    # Trigger build for a job with optional parameters.
    def build_job( self, job_name, build_params ):
        next_build_number = self.jclient[ job_name ].get_next_build_number()
        self.jclient.build_job( job_name, params=build_params )
        time.sleep( 10 )
        build_ids = self.jclient[ job_name ].get_build_ids()

        for build_id in build_ids:
            if ( build_id >= next_build_number ):
                build = self.jclient[ job_name ].get_build( build_id )
                build_actions = build.get_actions()
                build_parameters = build_actions[ 'parameters' ]
                build_user = build_actions[ 'causes' ][0][ 'userId' ]
                if ( build_user == self.jenkins_username ):
                    return build_id
            else:
                break

        return 0

# Main.
def main():
    jclient = JenkinsClient( 'http://int.testing.stubcorp.dev/jenkins' )
    build_params = { 'pool': 'srwd83', 'site': 'UK' }
    build_number = jclient.build_job( "com.stubhub.devops.smoketest", build_params )
    print build_number

if __name__ == "__main__":
    main()
