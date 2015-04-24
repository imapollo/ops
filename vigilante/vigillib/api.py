#!/usr/bin/env python

import httplib      # basic HTTP library for HTTPS connections
import urllib       # used for url-encoding during login request
import sys          # reads command-line args
import json

class VigApiHelper: 
    '''Helper class to do basic login, cookie management, and provide base 
    methods to send HTTP requests.'''

    def __init__(self, host, port_number): 
        self.httpcon = httplib.HTTPConnection(host, port=port_number)

    def request(self, method, url, body, content_type="application/json"):
        #self.httpcon.debuglevel=1  ### set level for debug output
        headers = { "Content-Type" : content_type }
        self.httpcon.request(method, url, body, headers)
        response = self.httpcon.getresponse()
#        self.cookie = response.getheader("Set-Cookie", self.cookie)
        status = response.status
        if status != httplib.OK and status != httplib.CREATED and status != httplib.NO_CONTENT:
            print "%s to %s got unexpected response code: %d (content = '%s')" \
            % (method,url, response.status, response.read())
            return None
        return response.read()

    def ws_get(self,url):
        return self.request("GET",url,"")

    def ws_put(self,url,body):
        return self.request("PUT",url,body)

    def ws_post(self,url,body):
        return self.request("POST",url,body)

    def ws_delete(self,url):
        return self.request("DELETE",url,"")   


class VigilanteApi(VigApiHelper):
    '''Object that represents perform API calls and more'''

    def __init__(self, host, port=3000):
        VigApiHelper.__init__( self, host, port ) #inherit from VigApiHelper

    def get_api_version(self):
        return self.ws_get("/vigilante/api/v0.1/version")

    def get_collector_role_data_current(self,role):
        return self.ws_get("/vigilante/api/v0.1/collector/role/current/%s" % role)

    def get_collector_role_data_historic(self, role, iso8601):
        return self.ws_get("/vigilante/api/v0.1/collector/role/%s/%s" %
                           iso8601, role) 

    def get_collector_env_data_current(self, envid):
        return self.ws_get("/vigilante/api/v0.1/collector/env/current/%s" % envid) 

    def get_collector_env_data_historic(self, envid, iso8601):
        return self.ws_get("/vigilante/api/v0.1/collector/env/%s/%s" %
                           iso8601, role) 

    def get_templates_list(self):
        return self.ws_get("/vigilante/api/v0.1/templates/list"
                   ) 
    def get_template(self,tplt):
        return self.ws_get("/vigilante/api/v0.1/templates/get/%s" % tplt)

    def query_current_role_with_template(self,tmplt,role):
        return self.ws_get("/vigilante/api/v0.1/query/template/%s/collector/role/current/%s" %
                           (tmplt,role))
    
    def query_current_env_with_template(self,tmplt,envid):
        return self.ws_get("/vigilante/api/v0.1/query/template/%s/collector/env/current/%s" %
                           (tmplt,envid))

    def query_historic_role_with_template(self, tmplt, role, iso8601):
        return self.ws_get("/vigilante/api/v0.1/query/template/%s/collector/role/%s/%s" %
                           (tmplt, iso8601, role))
    
    def query_historic_env_with_template(self, tmplt, envid, iso8601):
        return self.ws_get("/vigilante/api/v0.1/query/template/%s/collector/env/%s/%s" %
                           (tmplt, iso8601, envid))

# These are non-API helper functions
    
    def pretty_print(self,obj, ofd=sys.stdout): #TBD: this should be removed from the list of functions available to the user
        simplejson.dump(obj,ofd, sort_keys=True, indent=4)
        ofd.flush()
        
    def pretty_prints(self,str, ofd=sys.stdout):
        ofd.write("'")
        simplejson.dump(simplejson.loads(str),ofd, sort_keys=True, indent=4)
        ofd.write("'")
        ofd.flush()
 
    def std_prints(self,str, ofd=sys.stdout):
        ofd.write("'")
        simplejson.dump(simplejson.loads(str),ofd)
        ofd.write("'")
        ofd.flush()
           
