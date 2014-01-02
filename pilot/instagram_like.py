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

    def __init__():
        access_token = "CHANGEME"
        client = InstagramAPI( access_token = access_token )
        return client

# Main.
def main():
    client = InstagramClient()
    searched_medias = client.tag_search( "vsco" , 100 )*
    for searched_media in searched_medias:
        # client.media_likes( searched_media )
        client.like_media( searched_media )

if __name__ == "__main__":
    main()
