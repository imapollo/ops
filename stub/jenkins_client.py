#!/usr/local/bin/python
# -*- coding: utf-8 -*-

'''
jenkins_client - Jenkins client

@author:    Minjie Zhang
@contact:   minjzhang@ebay.com
'''

from jenkinsapi import jenkins
import time

__all__ = []
__version__ = 0.1
__date__ = '2014-04-17'
__updated__ = '2014-04-17'

#
# Jenkins Client
#
class JenkinsClient:

    # Initiate the client.
    def __init__( self, jenkins_url='http://jenkins.stubcorp.dev/reg' ):
        self.jenkins_username = 'minjzhang'
        jenkins_password = ''
        self.jclient = jenkins.Jenkins( jenkins_url,
                username=self.jenkins_username, password=jenkins_password)

    # Trigger build for a job with optional parameters.
    def build_job( self, job_name, build_params=None, timeout=3600, inqueue_timeout=30 ):
        next_build_number = self.jclient[ job_name ].get_next_build_number()
        job_is_running = self.jclient[ job_name ].is_running()

        self.jclient.build_job( job_name, params=build_params )
        time.sleep( 10 )

        build_number = self._get_build_number( job_name, build_params, job_is_running, next_build_number, inqueue_timeout )
        sleep_time = 0
        check_status_interval = 10
        while ( timeout >= sleep_time ):
            if ( self._get_build_status( job_name, build_number ) ):
                print self._get_build_log_url( job_name, build_number )
                print self._get_build_status( job_name, build_number )
                break
            else:
                time.sleep( check_status_interval )
                sleep_time += check_status_interval

    def _get_build_status( self, job_name, build_number ):
        build = self.jclient[ job_name ].get_build( build_number )
        return build.get_status()

    def _get_build_log_url( self, job_name, build_number ):
        build = self.jclient[ job_name ].get_build( build_number )
        return "%s/consoleText" % build.baseurl

    def _get_build_log( self, job_name, build_number ):
        build = self.jclient[ job_name ].get_build( build_number )
        return build.get_console()

    # Get the build number for the triggered job.
    def _get_build_number( self, job_name, build_params, is_running_before_trigger, next_build_number, timeout ):

        if not is_running_before_trigger:
            return self._get_the_build_number( job_name, build_params, next_build_number )
        else:
            sleep_time = 0
            check_interval = 10
            while self.jclient[ job_name ].is_queued_or_running:
                if ( self._get_the_build_number( job_name, build_params, next_build_number ) ):
                    return self._get_the_build_number( job_name, build_params, next_build_number )
                else:
                    if ( sleep_time >= timeout ):
                        print "in queue timeout ..."
                        break
                    time.sleep( check_interval )
                    sleep_time += check_interval

        return 0

    def _get_the_build_number( self, job_name, build_params, next_build_number ):
        build_ids = self.jclient[ job_name ].get_build_ids()
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
    jclient.build_job( "com.stubhub.devops.smoketest", build_params )

if __name__ == "__main__":
    main()
