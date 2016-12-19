#!/usr/bin/python

import re
import json
from screenparser import ScreenParser

class LsParser(ScreenParser):

    def handle_output(self, lines):
        content = []
        for line in lines:
            if line == '': continue
            content.append(line)
        result = { "dir" : content }
        results = []
        results.append(result)
        print json.dumps(results)

c = LsParser()
c.repeat(["ls", "/"], interval=0.5)
