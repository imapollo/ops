#!/usr/bin/python

import sys
import requests
import json

HISTOGRAPHY_URL = 'http://histography.io/php/mvps.php'

def _get_all_category():
    # return ['wars', 'riots', 'religion', 'politics', 'nationality', 'music', 'Literature', 'inventions', 'evolution', 'empires', 'discoveries', 'disasters', 'construction', 'assassinations', 'art', 'false']
    return ['false']

def _get_years_ranges(year_offset):
    year_ranges = []
    year_begin = -10000
    year_end = 2000
    year_current = year_begin
    while (year_current <= year_end - year_offset):
        year_range = []
        year_range.append(year_current)
        year_range.append(year_current + year_offset)
        year_ranges.append(year_range)
        year_current = year_current + year_offset
    return year_ranges

if __name__ == "__main__":
    categories = _get_all_category()
    offsets = [50, 100, 200, 500, 1000, 2000]
    for offset in offsets:
        year_ranges = _get_years_ranges(offset)
        for range in year_ranges:
            for category in categories:
                url_params = "from=%s&to=%s&category=%s" % (range[0], range[1], category)
                url = "%s?%s" % (HISTOGRAPHY_URL, url_params)
                results = requests.get(url, timeout=2).json()
                for result in results:
                    if result != None:
                        try:
                            print "%s,%s,%s,%s,%s" % (result["i"], result["title"].strip(), result["year"], result["rating"], result["category"])
                        except:
                            pass

