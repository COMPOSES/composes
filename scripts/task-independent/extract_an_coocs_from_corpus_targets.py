#! /bin/env python2.7
# coocExtraction.py
# LAST MODIFIED SEPT 6 2012

import sys, re, string, os, shutil, gzip, fileinput
from getopt import getopt

def usage():
	print '\n'
	print 'This scripts extracts adjective and noun cooccurrence information from an input corpus file.'
	print ''
	print 'Input:' 
	print '\ta corpus file in the (tab-delimited) format (piped in):'
	print '\t\ttoken\tlemma\tPOS-tag\tposition\thead\tdependency'
	print '\tfile containing target adjectives for AN cooccurrences (format: adjective-j)'
	print '\tfile containing target dimensions for cooccurrences (format: word-pos)'
	print 'Output:'
	print '\t1. a set of tuple files with word1-word2 info, tab-delimited'
	print '\t2. a set of element files with word data'
	print '\tNB:  * this script only extracts cooccurrences with adjectives, nouns, verbs and adverbs'
	print ''
	print 'Usage: cat <corpus_file> | python coocExtraction.py <output-directory> <window> <target-adjs-file> <target-dims-file>'
	print ''
	print '\t-h, --help\tshow this help message and exit'
	print ''
	print '    NB: if window size is not specified, the default window is 100'
	print '\n'
	sys.exit(0)


##############
##          ## 
##  main()  ##
##          ##
##############

## Initiate all variables
totalWordCount=0; x=0; totalElementCount=0
sentence=[]
n=100 ## n is the window in which to look for cooccurrences (default: 100)

## get user-specified options
optlist, args = getopt(sys.argv[1:], 'h', ['help'])
for opt, value in optlist:
	if opt in ('-h', '--help'): usage()

if len(sys.argv) < 4: usage()
d=sys.argv[1]
n=int(sys.argv[2])
t=sys.argv[3]
dims=sys.argv[4]

## create (remove and create) directory for output files
if not os.path.isdir(d): os.mkdir(d)
if not os.path.isdir(d+'/extracted-files'): os.mkdir(d+'/extracted-files')

## Get the target adjectives for which to build ANs
targets={}
targetFile = open(t, 'r')
for line in targetFile:
	targets[line.strip()]=0

targetFile.close()

## Get the dimensions for cooccurrences
dimensions={}
dimsFile = open(dims, 'r')
for line in dimsFile:
	dimensions[line.strip()]=0

dimsFile.close()

## Filter applied to extract only words containing...
## - alphabetical characters
## - non-initial, non-final, non-adjacent dashes
## - optionally a single apostrophe at the end
regex = re.compile(  '^[a-zA-Z]+([\-][a-zA-Z]+)*(\')?$'  )

## open output files
elements = gzip.open(d+'/extracted-files/elements.gz','wb')
tuples = gzip.open(d+'/extracted-files/tuples.gz','wb')

sys.stderr.write('\nReading corpus file \n\nExtracting tuples......\n')	## Progress Report
for line in sys.stdin:
	if len(line.split()) == 6: ## if the line contains all necessary fields, see usage for fields
		sentence.append(line.strip())
		totalWordCount+=1
		x+=1

	elif line.split()[0] == '</s>':	## If end of sentence, extract all cooccurrences found in the sentence

		for w in range(len(sentence)):
	
			if regex.match(sentence[w].split()[1]): 			
				current = sentence[w].split()[1]+'-'+sentence[w].split()[2][0].lower()

	       			if (sentence[w].split()[2][:2] == 'JJ') and (targets.has_key(current)) and (sentence[w].split()[5] in ('NMOD','COORD')) and (sentence[w+1].split()[2][:2] not in ('DT','IN')):
	
					head = sentence[w].split()[4]
					# if part of a conj, the head is the head of the coordination
					if sentence[w].split()[5] == 'COORD':	
						head = sentence[int(head)-1].split()[4]
				
					i = 1
					while (w+i in range(len(sentence))):

						## Build Adjective-j_Noun-n pair
						if (sentence[w+i].split()[2][:2] == 'NN') and (head == sentence[w+i].split()[3]) and (regex.match(sentence[w+i].split()[1])):
							nextWord = sentence[w+i].split()[1]+'-'+sentence[w+i].split()[2][0].lower()
							currentPair = current+'_'+nextWord
							elements.write(currentPair+'\n')

	                                                ## Get coocs [A_N,w] for each A_N and for w to the RIGHT of A_N
							q=1
							while ((i+q)<=n) and (w+i+q in range(len(sentence))):
								if (sentence[w+i+q].split()[2][:2] in ('NN','JJ','VV','RB')) and (regex.match(sentence[w+i+q].split()[1])):
									nextPos = sentence[w+i+q].split()[2][:2].lower()
									nextWord = sentence[w+i+q].split()[1]+'-'+nextPos[0]
									if dimensions.has_key(nextWord):
										tuples.write('%s\t%s\n' % (currentPair,nextWord))
								q+=1

				       			## Get coocs [A_N,w] for each A_N and for w to the LEFT of A_N
							q=1
							while (q<=n) and (w-q>=0):
								if (sentence[w-q].split()[2][:2] in ('NN','JJ','VV','RB')) and (regex.match(sentence[w-q].split()[1])):
									prevPos = sentence[w-q].split()[2][:2].lower()
									prevWord = sentence[w-q].split()[1]+'-'+prevPos[0]
									if dimensions.has_key(prevWord):
										tuples.write('%s\t%s\n' % (currentPair,prevWord))
								q+=1
						i+=1

		# re-initiate sentence after processing
		sentence=[]	

sys.stderr.write('\nTotal Word Count:\t'+str(totalWordCount)+'\n')

elements.close()
tuples.close()

sys.stderr.write(' ...done with extraction!\n')	## Progress Report



