#!/usr/bin/python

import json

if __name__ == "__main__":
    with open("histography.json", "r") as data_file:
        data = json.load(data_file)
        for event in data:
            try:
                print "%s,%s,%s,%s,%s" % (event["i"], event["title"].strip(), event["year"], event["rating"], event["category"])
            except:
                pass

