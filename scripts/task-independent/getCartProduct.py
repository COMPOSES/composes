#! /bin/env python2.7
# build_CartesianProduct_topAN_Tuples.py

import sys, math, string, re, os, shutil
from getopt import getopt

def usage():
	print ''
	print 'This script is used to construct Adjective-Noun tuples by calculating the Cartesian Product of'
	print 'a defined set of adjectives and a defined set of nouns.'
	print ''
	print 'The script requires an input file of Adjectives and an input file of Nouns'
	print ''
	print 'Usage: getCartProduct.py [-h] <adjectiveFile> <nounFile>'
	print 'options:'
	print '\t-h, --help\tshow this help message and exit'
	print '\n'
	sys.exit(0)

############
#  main()  #
############

## initiate all variables
adjs=[]; nns=[]; temp=[]
an=''

## Read command line arguements
if len(sys.argv)==1: usage()
optlist, args = getopt(sys.argv[1:], 'h', ['help'])

## open user-specified input file for reading, ref var = corpusFile
try: adjFilename=args[0]; adjFile = open(adjFilename, 'r')
except: usage()
try: nounFilename=args[1]; nounFile = open(nounFilename, 'r')
except: usage()

## get user-specified options from cmd line
for opt, value in optlist:
	if opt in ('-h', '--help'): usage()

for line in adjFile:
	adjs.append(line.split()[0])

for line in nounFile:
	nns.append(line.split()[0])

## get the Cartesian Product of the sets adjs and nns
for adj in adjs:
	for noun in nns:
		print '%s_%s' % (adj,noun)

