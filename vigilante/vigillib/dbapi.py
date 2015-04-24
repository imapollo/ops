import uuid
import re
import json
import yaml
import os.path
import sys
import collections
from os import listdir
from datetime import datetime, timedelta
from pymongo import MongoClient
import settings

class DBUnimplementedError(Exception) : pass
class DBIDnotpresentError(Exception) : pass

class DbBaseAPI(object):
    """This is a Base or Abstract class and is not meant to be instantiated
or used directly.

The DbBaseAPI object defines a set of methods that can be
reused across different versions of the API. If querying for a
certain resource is done in an identical fashion across different versions
it will be implemented here and should be overridden in their respective
versions if they deviate. So currently the implementation supports the filesystem
based database for vigilante, but you could easily create classes for puppetdb and
mongo db back ends.


"""
    def __init__(self, host='localhost', timeout=10):
        """Initialises our BaseAPI object passing the parameters needed in
order to be able to create the connection strings """

        self.api_version = "v0.1"
        self.host = host
        self.timeout = timeout
        self.threads = {}

    @property
    def version(self):
        """The version of the API we're querying against.

:returns: Current API version.
:rtype: :obj:`string`"""
        return self.api_version

    def login(self, dbname):
        dbid = uuid.uuid1()
        self.threads[dbid] = dbname
        return dbid

    def insert(self,dbid, insert_dict):
        raise NotImplementedError

    def find_one(self, dbid, query_dict):
        raise NotImplementedError

    def find(self, dbid, query_dict):
        raise NotImplementedError

    def match(self, tdbid, template_dict, cdbid, data_dict):
        """
Match strategy: If the template value of a key is "None",
then any data value is a match. If the template value is a
scalar (not a list) then the value is interpreted as a string
and only an exact match is considered a match. If the template
value is a list, then the first element of the list is an
operator and the following arguments are the operands. Roles
templates match their body keys to collector data on a 1-to-1
basis. Env templates iterate through the keys in the body and
calls match on each role lookup found.
"""

        # Different processing for Roles and envs
        result_dict = {"meta" : template_dict['meta'].copy(), "body": {}, "summary" : "success" }

        if template_dict['meta']['type'] == "role":
            result_dict['meta']['type'] = "role-diff"
            for template_key, template_value in template_dict['body'].iteritems():
                if template_value == "None":
                    pass
                elif type(template_value) is list:
                    rval = self._match_operator( template_value, data_dict['body'][ template_key ] )
                    if rval :
                        result_dict['body'][template_key] = data_dict['body'][template_key]
                        result_dict['summary'] = 'fail'
                elif type(template_value) is str or type(template_value) is unicode :
                    if ( template_value != data_dict['body'][ template_key ] ):
                        result_dict['body'][template_key] = data_dict['body'][template_key]
                        result_dict['summary'] = 'fail'
                else:
                    raise NotImplementedError
            return result_dict
        elif template_dict['meta']['type'] == "env":
            result_dict['meta']['type'] = "env-diff"
            result_dict['template'] = {}  # env-diffs have a template dict added
            role_list = data_dict['body'].keys()
            for template_key, template_value in template_dict['body'].iteritems():

                role_matches = []
                for element in role_list:
                    if re.match(template_key, element):
                        role_matches.append(element)
                for matched_key in role_matches:    
                    result_dict['body'][matched_key] = []
                    if template_value == "None":
                        pass
                    elif type(template_value) is list:
                        pass
                    elif type(template_value) is str or type(template_value) is unicode :
                        # so the template value will be the name of a template to match the
                        # collector data to. Which means that we need to use this name to fetch
                        # the template to do a match with the provided collector data in
                        # data_dict['body'][template_key][0]['current']
                        role_match_template = self.find_one(tdbid, {"name" : template_value})
                        result_dict['template'][matched_key] = role_match_template
                        if matched_key in data_dict['body'] and data_dict['body'][matched_key] :
                            role_match = self.match( tdbid, role_match_template, 
                                            cdbid, data_dict['body'][matched_key][0]['current'] )
                            if role_match['summary'] == 'fail':
                                result_dict['summary'] = 'fail'
                            result_dict['body'][matched_key].append( role_match )
                    else:
                        raise NotImplementedError
            return result_dict
        else:
            raise NotImplementedError

    def _match_operator( self, operator_list, data_value ):
        operator = operator_list[0]
        if operator == ">":
            if not int(data_value) > int(operator_list[1]):
                return data_value
            else:
                return None
        elif operator == "<":
            if not int(data_value) < int(operator_list[1]):
                return data_value
            else:
                return None
        elif operator == "=":
            if not data_value == operator_list[1]:
                return data_value
            else:
                return None
        elif operator == "!=":
            if not data_value != operator_list[1]:
                return data_value
            else:
                return None
        elif operator == "~":
            if not re.match( r"%s" % operator_list[1], data_value ):
                return data_value
            else:
                return None
        else:
            raise NotImplementedError

    def _update(self,d, u):
        for k, v in u.iteritems():
            if isinstance(v, collections.Mapping):
                r = self._update(d.get(k, {}), v)
                d[k] = r
            else:
                d[k] = u[k]
        return d

    def _resolve_template(self,dbid,template_dict):
        super = template_dict["meta"]["super"]
        if not super or (super == "none") or (super == "None"):
            return template_dict
        else:
            next_template = self.find_one(dbid,{"name" : super})
            merged_template = self._resolve_template(dbid, next_template)
            return self._update(merged_template, template_dict)

class VigDBFS(DbBaseAPI):
    """ This is the current implementation that store data in the file system.
Don't call this implementation dependent class, use the generic wrapper instead.
"""

    def __init__(self,auditroot='/nas/reg/log/jiralab/vigilante/auditor'
                 , tlroot='/nas/reg/log/jiralab/vigilante/template_library'):
        self.auditroot_path = auditroot
        self.templib_path = tlroot
        super(VigDBFS,self).__init__()

    def login(self,space="collector"):
        """ There are currently two possible databases, the "collector" database which holds raw data
gathered from the Environments, and the "template_library" which contains JSON templates that
are used in matching operations
"""
        if space in ("collector", "template_library"):
            return super(VigDBFS,self).login(space)
        else :
            raise DBUnimplementedError

    def find_one(self, dbid, query_dict):
        if dbid not in self.threads :
            raise DBIDnotpresentError
        dbtype = self.threads[dbid]
        return_dict = {}
        if dbtype == "collector":
            name = query_dict["fqdn"]
            if "iso8601" not in query_dict:
                timestamp = "current"
            else:
                timestamp = query_dict["iso8601"]
            m = re.match( r"([^\.]+)\.([^\.]+)\.com", name )
            hostname = m.group( 1 )
            m = re.match( r"(^[A-z]+[0-9]{2})", hostname)
            envid = m.group(1)
            if timestamp == "current":
                result_path = "%s/%s/%s/current" % ( self.auditroot_path, envid, hostname)
                if ( os.path.isfile( result_path ) ):
                    return_dict = json.loads( open( result_path ).read() )
        elif dbtype == "template_library":
            name = query_dict["name"]
            result_path = "%s/%s.yaml" % (self.templib_path, name)
            if ( os.path.isfile( result_path ) ):
                return_dict = yaml.load(open( result_path ).read() )
                return_dict = self._resolve_template( dbid, return_dict )
        return return_dict

    def find(self, dbid, query_dict):
        if dbid not in self.threads :
            raise DBIDnotpresentError
        dbtype = self.threads[dbid]
        return_dict = {}
        if dbtype == "collector":
            return_dict = {'meta' : { 'type' : 'phaktor-bundle'}, 'body' : {}}
            if "iso8601" not in query_dict:
                timestamp = "current"
            else:
                timestamp = query_dict["iso8601"]
            envid = query_dict["domain"]
            m = re.match( r"(^[A-z]+[0-9]{2})", envid)
            return_dict['meta'][ 'envid' ] = envid
            result_set_path = "%s/%s" % ( self.auditroot_path, envid )
            env_role_paths = [ role_path for role_path in listdir( result_set_path ) 
                              if os.path.isdir( os.path.join( result_set_path, role_path ) ) ]
            for role_path in env_role_paths:
                file_dict = self._find_file_in_time( os.path.join( result_set_path, role_path ), timestamp )
                role_facter_in_time_range = []
                for file_key, file_value in file_dict.iteritems():
                    if ( os.path.isfile( file_value ) ):
                        role_facter_in_time_range.append( { file_key: json.loads( open( file_value ).read() ) } )
                return_dict['body'][ role_path ] = role_facter_in_time_range
        elif dbtype == "template_library":
            return_dict = {'meta' : { 'type' : 'template-bundle'}, 'body' : {}}
            tl_list = os.listdir(self.templib_path)
            for file in tl_list :
                result_path = "%s/%s" % (self.templib_path, file)
                return_dict['body'][os.path.splitext(file)[0]] = self._resolve_template( dbid, yaml.load( open( result_path ).read() ) )
        return return_dict

    # Find the files in the directory based on timestamp
    def _find_file_in_time(self, role_dir_path, timestamp):
        if timestamp == "current":
            return { "current" : os.path.join( role_dir_path, "current" ) }
        elif "starttime" in timestamp and "endtime" in timestamp:
            RANGE_TIME_FORMAT = '%Y-%m-%dT%H:%M:%SZ'
            FILE_TIME_FORMAT = '%Y%m%dT%H%M%S'
            range_start_time = datetime.strptime( timestamp[ "starttime"], RANGE_TIME_FORMAT )
            range_end_time = datetime.strptime( timestamp[ "endtime"], RANGE_TIME_FORMAT )
            historical_file_paths = [ hist_file for hist_file in listdir( role_dir_path ) ]
            file_dict = {}
            for hist_file in historical_file_paths:
                if not hist_file == "current":
                    m = re.match( r"[^\.]+\.([^\.]+)", hist_file )
                    file_timestamp = m.group( 1 )
                    file_time = datetime.strptime( file_timestamp, FILE_TIME_FORMAT )
                    if ( ( file_time - range_start_time ) > timedelta( seconds = 0 )
                            and ( range_end_time - file_time ) > timedelta( seconds = 0 ) ):
                        file_dict[ file_time.strftime( RANGE_TIME_FORMAT ) ] = os.path.join( role_dir_path, hist_file )
            return file_dict

class VigDBMongo(DbBaseAPI):
    """ This is the current implementation that store data in the file system.
Don't call this implementation dependent class, use the generic wrapper instead.
"""

    def __init__(self, dbname=settings.MONGODB_NAME, hostname=settings.MONGODB_HOST, port=settings.MONGODB_PORT ):
        self.db = MongoClient( hostname, port )[ dbname ]
        self.collector = 'facts_current'
        self.collector_history = 'facts_history'
        self.template = 'template'
        super(VigDBMongo,self).__init__( host=hostname )

    def login(self,space="collector"):
        """ This is collections in mongodb. """
        if space in ("collector", "template_library"):
            return super(VigDBMongo,self).login(space)
        else :
            raise DBUnimplementedError

    # upsert history and current collector for facts.
    def insert( self, dbid, insert_dict ):
        if dbid not in self.threads :
            raise DBIDnotpresentError
        dbtype = self.threads[dbid]
        if dbtype == "collector" :
            latest_dict = self.find_one( dbid, { "fqdn" : insert_dict['body']['fqdn'] } )
            db_collectors_current = self.db[ self.collector ]
            db_collectors_history = self.db[ self.collector_history ]
            if ( latest_dict ):
                current_diff = self._diff_current_with_latest( insert_dict, latest_dict )
                if ( current_diff ):
                    history_dict = { "timestamp" : datetime.utcnow(),
                        "diff" : current_diff,
                        "full" : insert_dict }
                    db_collectors_history.insert( history_dict )
                    db_collectors_current.update( { "body.fqdn" : insert_dict['body']['fqdn'] },
                        { "$set" : insert_dict } )
                else:
                    pass
            else:
                db_collectors_current.insert( insert_dict )

    def find_one( self, dbid, query_dict ):
        if dbid not in self.threads :
            raise DBIDnotpresentError
        dbtype = self.threads[dbid]
        if dbtype == "collector" :
            db_collectors_current = self.db[ self.collector ]
            return self._prepare_mongo_query_result( db_collectors_current.find_one( { "body.fqdn" : query_dict["fqdn"] } ) )
        elif dbtype == "template_library":
            db_collectors_template = self.db[ self.template ]
            template_name = query_dict["name"]
            return self._prepare_mongo_query_result( db_collectors_template.find_one( { "meta.name" : query_dict["name"] } ) )
        else :
            raise NotImplementedError

    def find(self, dbid, query_dict):
        if dbid not in self.threads :
            raise DBIDnotpresentError
        dbtype = self.threads[dbid]
        if dbtype == "collector" :
            db_collectors_current = self.db[ self.collector ]
            if "domain" in query_dict :
                fact_list = list( db_collectors_current.find( { "body.domain" : "%s.com" % query_dict["domain"] } ) )
                return self._restruct_fact_list( fact_list, "current", query_dict["domain"] )
            else :
                raise NotImplementedError
        elif dbtype == "template_library":
            db_collectors_template = self.db[ self.template ]
            return_dict = {'meta' : { 'type' : 'template-bundle'}, 'body' : {}}
            return self._restruct_template_list( list( db_collectors_template.find() ) )
        else :
            raise NotImplementedError

    def _prepare_mongo_query_result( self, query_result ):
        prepared_result = {}
        if query_result != None :
            for key, value in query_result.iteritems() :
                if key == "_id" :
                    pass
                else :
                    prepared_result[key] = value
        return prepared_result

    def _restruct_template_list( self, template_list ):
        restructed_template_dict = {}
        for template in template_list :
            template_name = template['meta']['name']
            restructed_template_dict[template_name] = self._prepare_mongo_query_result( template )
        return restructed_template_dict

    def _restruct_fact_list( self, fact_list, timestamp, envid ):
        restructed_fact_list = {}
        restructed_fact_list['body'] = {}
        restructed_fact_list['meta'] = { "envid" : envid, "type" : 'phaktor-bundle' }
        for fact in fact_list :
            hostname = fact[ "body" ][ "hostname" ]
            restructed_fact_list[ "body" ][ hostname ] = [ { timestamp : self._prepare_mongo_query_result( fact ) } ]
        return restructed_fact_list

    # Return diff dict between current and latest facts.
    # Return 0 otherwise.
    def _diff_current_with_latest( self, current_dict, latest_dict ):
        if "_id" in latest_dict :
            del latest_dict['_id']
        # current_dict['body']['sh_rolenum'] = '002'
        # current_dict['meta']['version'] = '0.2'
        body_diff = DictDiffer( current_dict['body'], latest_dict['body'] )
        meta_diff = DictDiffer( current_dict['meta'], latest_dict['meta'] )

        diff_dict = {}
        diff_dict['body'] = {}
        diff_dict['meta'] = {}
        for body_diff_item in body_diff.changed():
            diff_dict['body'][ body_diff_item ] = current_dict['body'][ body_diff_item ]
        for meta_diff_item in meta_diff.changed():
            diff_dict['meta'][ meta_diff_item ] = current_dict['meta'][ meta_diff_item ]

        if ( len( body_diff.changed() ) > 0 or len( meta_diff.changed() ) > 0 ):
            return diff_dict
        else:
            return 0

class DictDiffer(object):
    """
    Calculate the difference between two dictionaries as:
    (1) items added
    (2) items removed
    (3) keys same in both but changed values
    (4) keys same in both and unchanged values
    """
    def __init__(self, current_dict, past_dict):
        self.current_dict, self.past_dict = current_dict, past_dict
        self.set_current, self.set_past = set(current_dict.keys()), set(past_dict.keys())
        self.intersect = self.set_current.intersection(self.set_past)
    def added(self):
        return self.set_current - self.intersect 
    def removed(self):
        return self.set_past - self.intersect 
    def changed(self):
        return set(o for o in self.intersect if self.past_dict[o] != self.current_dict[o])
    def unchanged(self):
        return set(o for o in self.intersect if self.past_dict[o] == self.current_dict[o])

# This is the interface that you should use in your code
class VigDB(VigDBFS):
    def __init__(self):
        super(VigDB,self).__init__()

class VigMgDB(VigDBMongo):
    def __init__(self):
        super(VigMgDB,self).__init__()

if __name__ == "__main__" :
    # s = VigDB()
    s = VigMgDB()
    collector =  s.login()
    rs = s.find_one(collector, { "fqdn" : "srwd10agg001.srwd10.com" } )
    print "Result Set : ", rs
    print "============="
    rs = s.find(collector, {"domain" : "srwd66"} )
    print "Result Set : ", rs
    sys.exit()
    # print "Result Set : ", json.dumps( rs)
    # rs = s.find(collector, {"domain" : "srwd66", "iso8601" : { "starttime" : "2014-06-23T00:03:01Z", "endtime" : "2014-06-23T18:24:01Z" } } )
    # rs = s.find(collector, {"domain" : "srwd66"} )
    # print  json.dumps( rs)
    templates = s.login("template_library")
    # print "Result Set : ", json.dumps( rs)
    # rs = s.find(templates, {})
    # print "Result Set : ", json.dumps( rs )
    # rs = s.find_one(templates, {"name" : "generic"})
    # print "Result Set : ", json.dumps( rs )
    # spectpl = s.find_one(templates, {"name" : "operators"})
    env = s.find_one(templates, {"name" : "srwd66"})
    print "Result Set : ", json.dumps( env )
    # print "Result Set : ", json.dumps( spectpl )
    # rs = s.match( templates, spectpl, collector, rs )
    rs = s.match( templates, env, collector, rs )
    print json.dumps(rs, indent=4, sort_keys=True)
