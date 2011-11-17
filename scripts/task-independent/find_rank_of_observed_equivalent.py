#! /bin/env python2.7
# find_rank_of_observed_equivalent.py

import sys, fileinput
from getopt import getopt

def usage():
	print ''
	print 'Usage():\n\tfind_rank_of_observed_equivalent.py -i <ifile> -o <ofile-prefix> -r <rowNum> (-t)'
	print ''
	print '\t-i <ifile>\t\tfile cosines of pairs in tab-delimited format: target word score'
	print '\t-o <ofile-prefix>\t\tprefix for output file'
	print '\t-r <rowNum>\t\tthe number of rows, ie, number of pairs per target'
	print '\t-t\t\t\tinclude this option to print the top ten nearest neighbors'
	print '\t-h,--help\t\tprint this message'
	print ''
	sys.exit(0)

#--------------------------------------------------------

topTen=False

## Read command line arguements
optlist, args = getopt(sys.argv[1:], 'hti:o:r:', ['help'])

if len(optlist) < 3: usage()

## Get user-specified options
for opt, value in optlist:
	if opt in ('-h', '--help'): usage()
	if opt in ('-i'): i = str(value)
	if opt in ('-o'): o = str(value)
	if opt in ('-r'): rows = int(value)
	if opt in ('-t'): topTen=True

#--------------------------------------------------------

f = open(i,'r')
o_rank = open(o+'.rank_of_observed_equivalent','w')
if topTen==True: o_topTen = open(o+'.top-ten-neighbors','w')
a = []; b= []

for line in f.readlines():
	if len(a) == 1:
		ref = line.split()[0][2:]
	if len(a) < rows:
		a.append(line.split())
	if len(a) == rows:
		b = sorted(a, key=lambda score: score[2], reverse=True)
		if topTen == True:
			for i in range(10):
				o_topTen.write(b[i][0]+'\t'+b[i][1]+'\t'+b[i][2]+'\n')
		for x,y,z in b:
			if x == 'p.'+ref and y == ref:
				rank = b.index([x,y,z])+1
				o_rank.write(x+'\t'+str(rank)+'\n')
		a = []


o_rank.close()
if topTen==True: o_topTen.close()

