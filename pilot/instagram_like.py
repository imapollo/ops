#!/usr/bin/python
# -*- coding: utf-8 -*-
#
# cronjob to like instagram medias routinely.
#
# author: ze.apollo@gmail.com
#

from instagram.client import InstagramAPI

# Client for instagram REST API.
class InstagramClient():

    def __init__( self ):
        access_token = "CHANGEME"
        self.api = InstagramAPI( access_token = access_token )

# Main.
def main():
    client = InstagramClient()
    searched_medias = client.api.tag_search( "vsco" , 10 )
    for searched_media in searched_medias:
        # TODO sleep 2 seconds
        # TODO install python-instagram
        # client.media_likes( searched_media )
        client.api.like_media( searched_media )

if __name__ == "__main__":
    main()
