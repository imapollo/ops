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
        access_token = "529078.1fb234f.ce9c7ff887c64add9b02b139253e64e0"
        self.api = InstagramAPI( access_token = access_token )

# Main.
def main():
    client = InstagramClient()
    searched_medias = client.api.tag_recent_media( 30, 999999999, "vsco" )
    for searched_media in searched_medias[0]:
        likes = client.api.media_likes( searched_media.id )
        if ( len(likes) > 2 ):
            commands.getoutput( '/bin/sleep 30' )
            print ("%s: %s" % ( datetime.datetime.now(), searched_media.id ) )
            try:
                client.api.like_media( searched_media.id )
            except Exception:
                pass

if __name__ == "__main__":
    main()
