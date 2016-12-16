#!/usr/bin/python

import re
import json
from screenparser import ScreenParser

class TopParser(ScreenParser):

    def handle_output(self, lines):
        results = []
        for line in lines:
            icmp_pattern = re.compile(".*icmp_seq=([^ ]+).*")
            ttl_pattern = re.compile(".*ttl=([^ ]+).*")
            time_pattern = re.compile(".*time=([^ ]+).*")
            icmp_m = icmp_pattern.match(line)
            ttl_m = ttl_pattern.match(line)
            time_m = time_pattern.match(line)
            if (icmp_m and ttl_m and time_m):
                result = {}
                result["icmp"] = icmp_m.group(1)
                result["ttl"] = ttl_m.group(1)
                result["time"] = time_m.group(1)
                results.append(result)
        print json.dumps(results)

c = TopParser()
c.execute(["ping", "8.8.8.8"], interval=0.5)
