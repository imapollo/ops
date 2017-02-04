#!/usr/bin/python

import re

if __name__ == "__main__":
    word_map = {}
    valid_word = re.compile("[a-z]+")

    with open("content.lst", "r") as content:
        for line in content:
            words = line.strip().split(' ')
            for word in words:
                word = word.lower()
                word = word.replace('"', '')
                if valid_word.match(word):
                    if word in word_map:
                        word_map[word] = word_map[word] + 1
                    else:
                        word_map[word] = 1
    for word in word_map:
        print "%s\t%s" % (word_map[word], word)
