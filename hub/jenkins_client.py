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
    def __init__( self, jenkins_url='http://jenkins.stubcorp.dev/reg' ):
        self.jenkins_username = 'minjzhang'
        jenkins_password = 'chinSk18w'
        self.jclient = jenkins.Jenkins( jenkins_url,
                username=self.jenkins_username, password=jenkins_password)

    # Trigger build for a job with optional parameters.
    def build_job( self, job_name, build_params=None ):
        # if ( self.jclient[ job_name ].is_queued_or_running() ):
        #     print "already running...."
        #     return 0

        next_build_number = self.jclient[ job_name ].get_next_build_number()
        self.jclient.build_job( job_name, params=build_params )
        time.sleep( 10 )
        build_ids = self.jclient[ job_name ].get_build_ids()
        last_id = self.jclient[ job_name ].get_last_buildnumber()

        # To get the right build number.
        for build_id in build_ids:
            if ( build_id >= next_build_number ):
                build = self.jclient[ job_name ].get_build( build_id )
                jenkins_build_actions = build.get_actions()
                jenkins_build_parameters = jenkins_build_actions[ 'parameters' ]
                jenkins_build_user = jenkins_build_actions[ 'causes' ][0][ 'userId' ]
                if ( jenkins_build_user == self.jenkins_username
                        and self._check_params( build_params, jenkins_build_parameters ) ):
                    return build_id
            else:
                break

        return 0

    # Check if the parameters are the same with the jenkins build.
    def _check_params( self, build_params, jenkins_params ):
        params_same = 1
        for param in jenkins_params:
            for build_param_key, build_param_value in build_params.items():
                if ( param[ 'name' ] == build_param_key ):
                    if ( param[ 'value' ] != build_param_value ):
                        params_same = 0
                        break

        return params_same

# Main.
def main():
    jclient = JenkinsClient( 'http://int.testing.stubcorp.dev/jenkins' )
    build_params = { 'pool': 'srwd73', 'site': 'UK' }
    build_number = jclient.build_job( "com.stubhub.devops.smoketest", build_params )
    print build_number

if __name__ == "__main__":
    main()
