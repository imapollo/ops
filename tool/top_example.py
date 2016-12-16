#!/usr/bin/python

import re
import json
from screenparser import ScreenParser

class TopParser(ScreenParser):

    def handle_output(self, lines):
        results = []
        for line in lines:
            line = re.sub("\s+", " ", line)
            line = re.sub("^ ", "", line)
            if line.startswith("top -") \
                or line.startswith("Tasks:") \
                or line.startswith("Cpu(s):") \
                or line.startswith("Mem:") \
                or line.startswith("Swap:") \
                or line.startswith("PID"):
                    continue
            elements = line.split(" ")
            if (len(elements) > 1):
                result = {}
                result["pid"] = elements[0]
                result["user"] = elements[1]
                results.append(result)
        print json.dumps(results)

c = TopParser()
c.execute(["top"])
