#!/usr/bin/python
# -*- coding: utf-8 -*-
#
# cronjob to like instagram medias routinely.
#
# author: ze.apollo@gmail.com
#

from instagram.client import InstagramAPI
import commands
import datetime

# Client for instagram REST API.
class InstagramClient():

    def __init__( self ):
        access_token = "CHANGEME"
        self.api = InstagramAPI( access_token = access_token )

# Main.
def main():
    client = InstagramClient()
    searched_medias = client.api.tag_recent_media( 20, 999999999, "vsco" )
    for searched_media in searched_medias[0]:
        commands.getoutput( '/bin/sleep 10' )
        # likes = client.api.media_likes( searched_media.id )
        # if ( len(likes) > 1 ):
        print ("%s: %s" % ( datetime.datetime.now(), searched_media.id ) )
        client.api.like_media( searched_media.id )

if __name__ == "__main__":
    main()
