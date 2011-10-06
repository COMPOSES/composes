#! /bin/env python2.7
# simple.filter.py

import sys, math, string, fileinput
from getopt import getopt

# Script that filters certain elements from ANs
# This script is useful for preprocessing data for various tasks in
# the adj-noun compositionality pipeline 
# Usage:
# Input is a file of ANs, of the format: ADJECTIVE-j_NOUN-n 
# Output is the element(s) specified as an argument in the command line
#    -a: return a list of component adjs. Format: ADJECTIVE-j
#    -n: return a list of component nouns. Format: NOUN-n
#    -b: return a tab-delimited list of the ANs. Format: ADJECTIVE-j \t NOUN-n
#    -r: return a reversed tab-delimited list of the ANs. Format: NOUN-n \t ADJECTIVE-j


an=''; toPrint=''; filename=''
## Read command line arguements
optlist, args = getopt(sys.argv[1:], 'hanbrf:', ['help'])
## get user-specified options
for opt, value in optlist:
	if opt in ('-h', '--help'): usage()
	if opt in ('-f'): 
		filename=value
	if opt in ('-a'): toPrint='adj'
	if opt in ('-n'): toPrint='noun'
	if opt in ('-b'): toPrint='both'
	if opt in ('-r'): toPrint='rev'

def usage():
	print '\n'
	print 'Usage():\n\tsimple.filter.py -anbr -f <file>'
	print ''
	print '\t-f <file>\t\tpath to AN file to be filtered'
	print '\t-a\t\tprint the Adjective from the AN pair'
	print '\t-n\t\tprint the Noun from the AN pair'
	print '\t-b\t\tprint \"Adj (tab) Noun\" from the AN pair'
	print '\t-r\t\tprint \"Noun (tab) Adj\" from the AN pair'
	print '\t-h\t\tprint this message'
	print ''
	sys.exit(0)


############
#  main()  #
############

inputFile = open(filename,'r');

for line in inputFile.readlines():

	an = line.split()[0]
	adj = an.split('_')[0]
	noun = an.split('_')[1]

	if (toPrint == 'adj'):
		print adj
	elif (toPrint == 'noun'):
		print noun
	elif (toPrint == 'both'):
		print adj+'\t'+noun
	elif (toPrint == 'rev'):
		print noun+'\t'+adj

