#!/usr/bin/python

if __name__ == "__main__":
    with open("years.lst", "r") as data_file:
        for line in data_file:
            year = int(line)
            if year < -4600000000:
                print "%s\t%s\t%s" % (year, '-4600000000', 'The Beginning')
            elif year >= -4600000000 and year < -2500000000:
                print "%s\t%s\t%s" % (year, '-2500000000', 'Earth Formation')
            elif year >= -2500000000 and year < -542000000:
                print "%s\t%s\t%s" % (year, '-542000000', 'Seeds of Life')
            elif year >= -542000000 and year < -251000000:
                print "%s\t%s\t%s" % (year, '-251000000', 'Age of Fish')
            elif year >= -251000000 and year < -65000000:
                print "%s\t%s\t%s" % (year, '-65000000', 'Age of Reptiles')
            elif year >= -65000000 and year < -3000000:
                print "%s\t%s\t%s" % (year, '-3000000', 'Age of Mammals')
            elif year >= -3000000 and year < -50000:
                print "%s\t%s\t%s" % (year, '-50000', 'Stone Age')
            elif year >= -50000 and year < -2500:
                print "%s\t%s\t%s" % (year, '-2500', 'Bronze Age')
            elif year >= -2500 and year < 700:
                print "%s\t%s\t%s" % (year, '700', 'Iron Age')
            elif year >= 700 and year < 1400:
                print "%s\t%s\t%s" % (year, '1400', 'Middle Ages')
            elif year >= 1400 and year < 1750:
                print "%s\t%s\t%s" % (year, '1750', 'Renaissance')
            elif year >= 1750 and year < 1950:
                print "%s\t%s\t%s" % (year, '1950', 'Industrial Age')
            elif year >= 1950:
                print "%s\t%s\t%s" % (year, '2000', 'Information Age')

