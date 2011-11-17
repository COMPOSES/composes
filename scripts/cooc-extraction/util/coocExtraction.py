#! /bin/env python2.7
# coocExtraction.py
# LAST MODIFIED AUGUST 2 2011

import sys, re, string, os, shutil, gzip, fileinput, functions
from getopt import getopt
import subprocess as S

def usage():
	print '\n'
	print 'This scripts extracts adjective and noun cooccurrence information\nfrom an input corpus file.\nNOTE: this script is to be followed by coocScores.LogFq.py to calculate cooccurrence scores.'
	print ''
	print 'The script takes as input a corpus file in the (tab-delimited) format (piped in):'
	print '\ttoken\tlemma\tPOS-tag\tposition\thead\tdependency'
	print ''
	print 'The output of this script is:'
	print '\t1. a set of tuple files with word1-word2 info, tab-delimited'
	print '\t2. a set of element files with word data'
	print '\tNOTE: for debugging reasons a new file is started after every 500000000 words'
	print ''
	print 'Usage: cat [corpus_file] | python coocExtraction.py'
	print 'options:'
	print '\t-h, --help\tshow this help message and exit'
	print ''
	print '\n'
	sys.exit(0)


##############
##          ## 
##  main()  ##
##          ##
##############

## Initiate all variables
Elements={}; Tuples={}; pairDict={}
totalWordCount=0; totalTupleCount=0; x=0; i=1; totalElementCount=0
sentence=[]

## Initiate variables for command line options
n=100 ## n is the window in which to look for cooccurrences

## Read command line arguements
optlist, args = getopt(sys.argv[1:], 'h', ['help'])

## get user-specified options
for opt, value in optlist:
	if opt in ('-h', '--help'): usage()

## create (remove and create) directory for output files
d='cooc.output-jnvr'
#if os.path.isdir(d): shutil.rmtree(d)
#os.mkdir(d)
if not os.path.isdir(d): os.mkdir(d)
if not os.path.isdir(d+'/extracted-files'): os.mkdir(d+'/extracted-files')

## open all output files
elements = gzip.open(d+'/extracted-files/elements'+str(i)+'.gz','wb')
tuples = gzip.open(d+'/extracted-files/tuples'+str(i)+'.gz','wb')

sys.stderr.write('\nReading corpus file \n\nExtracting tuples......\n')	## Progress Report

#for line in fileinput.input():
for line in sys.stdin:
	if len(line.split()) == 6: ## if the line contains all necessary fields, see usage for fields
		sentence.append(line.strip())
		totalWordCount+=1
		x+=1

	elif line.split()[0] == '</s>':	## If end of sentence, extract all cooccurrences found in the sentence
		totalTupleCount += functions.extractData(sentence,elements,tuples,n)
		sentence=[]

		if x>=500000000:
			sys.stderr.write('\nFiles elements'+str(i)+'.gz and tuples'+str(i)+'.gz complete...\nTotal Word Count:\t'+str(totalWordCount)+'\n')	## Progress Report
			elements.close(); tuples.close(); i+=1; x=0
			elements = gzip.open(d+'/extracted-files/elements'+str(i)+'.gz','wb')
			tuples = gzip.open(d+'/extracted-files/tuples'+str(i)+'.gz','wb')

elements.close(); tuples.close(); 

other = open(d+'/other','w')
other.write('totalWordCount\t%s\ntotalTupleCount\t%s\n' % (totalWordCount,totalTupleCount))
#other.write('totalWordCount\t'+str(totalWordCount)+'\ntotalTupleCount\t'+str(totalTupleCount)+'\ngetLL\t'+str(getLL)+'\ngetPMI\t'+str(getPMI)+'\n')
other.close()

sys.stderr.write(' ...done with extraction!\n')	## Progress Report



