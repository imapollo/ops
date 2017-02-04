#!/usr/bin/python

import re

def get_location():
    location_map = {}
    with open("locations.map", "r") as locations:
        for location in locations:
            location_array = location.strip().split(",")
            location_map[location_array[0]] = location_array[1]
    return location_map

if __name__ == "__main__":
    valid_word = re.compile("[a-z]+")
    location_map = get_location()

    with open("content.lst", "r") as content:
        for line in content:
            words = line.strip().split(' ')
            match = False
            for word in words:
                word = word.lower()
                word = word.replace('"', '')
                if valid_word.match(word) and word in location_map:
                    print "%s\t%s" % (line.strip(), location_map[word])
                    match = True
                    break
            if not match:
                print line.strip()
                    
