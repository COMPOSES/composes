#! /bin/env python2.7
# coocExtraction.py
# LAST MODIFIED OCTOBER 8 2012

import sys, re, string, os, shutil, gzip, fileinput
from getopt import getopt

def usage():
	print '\n'
	print 'This scripts extracts adjective and noun cooccurrence information from an input corpus file.'
	print ''
	print 'Input: a corpus file in the (tab-delimited) format (piped in):'
	print '\ttoken\tlemma\tPOS-tag\tposition\thead\tdependency'
	print 'Output:'
	print '\t1. a set of tuple files with word1-word2 info, tab-delimited'
	print '\t2. a set of element files with word data'
	print '\tNOTE: for debugging reasons a new file is started after every 500000000 words'
	print '\n'
	print 'Usage: cat <corpus_file> | python coocExtraction.py <output-directory> <window>'
	print ''
	print '\t-h, --help\tshow this help message and exit'
	print ''
	print '    NB: if window size is not specified, the default window is 100'
	print ''
	print '\n'
	sys.exit(0)


##############
##          ## 
##  main()  ##
##          ##
##############

## Initiate all variables
totalWordCount=0; x=0; f=1; totalElementCount=0
sentence=[]
n=100 ## n is the window in which to look for cooccurrences (default: 100)

## get user-specified options
optlist, args = getopt(sys.argv[1:], 'h', ['help'])
for opt, value in optlist:
	if opt in ('-h', '--help'): usage()

if len(sys.argv) < 2: usage()
d=sys.argv[1]
n=int(sys.argv[2])

## create (remove and create) directory for output files
if not os.path.isdir(d): os.mkdir(d)
if not os.path.isdir(d+'/extracted-files'): os.mkdir(d+'/extracted-files')

## Filter applied to extract only words containing...
## - alphabetical characters
## - non-initial, non-final, non-adjacent dashes
## - optionally a single apostrophe at the end
regex = re.compile(  '^[a-zA-Z]+([\-][a-zA-Z]+)*(\')?$'  )
		
## open all output files
elements = gzip.open(d+'/extracted-files/elements'+str(f)+'.gz','wb')
tuples = gzip.open(d+'/extracted-files/tuples'+str(f)+'.gz','wb')

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
				if sentence[w].split()[2][:2] not in ('NN','JJ','VV','RB'):
					current = sentence[w].split()[1]+'-'+sentence[w].split()[2][:2].lower()
				elements.write('%s\n' % (current))

				## Continue to extract the tuple information if the current word is a noun or adjective
				if sentence[w].split()[2][:2] in ('NN','JJ'):
	
					i=1
					while (i<=n) and (w+i in range(len(sentence))):
						if regex.match(sentence[w+i].split()[1]):
							nextPos = sentence[w+i].split()[2][:2].lower()
							nextWord = sentence[w+i].split()[1]+'-'+nextPos[0]
							if (sentence[w+i].split()[2][:2] not in ('NN','JJ','VV','RB')):
								nextWord = sentence[w+i].split()[1]+'-'+nextPos[:2]
							tuples.write('%s\t%s\n' % (current,nextWord))
						i+=1

					i=1
					while (i<=n) and (w-i>=0):
						if regex.match(sentence[w-i].split()[1]):
							prevPos = sentence[w-i].split()[2][:2].lower()
							prevWord = sentence[w-i].split()[1]+'-'+prevPos[0]
							if (sentence[w-i].split()[2][:2] not in ('NN','JJ','VV','RB')):
								prevWord = sentence[w-i].split()[1]+'-'+prevPos[:2]
							tuples.write('%s\t%s\n' % (current,prevWord))
						i+=1
				
					if (sentence[w].split()[2][:2] == 'JJ') and (sentence[w].split()[5] in ('NMOD','COORD')) and sentence[w+1].split()[2][:2] not in ('DT','IN'):
	
						head = sentence[w].split()[4]
						# if part of a conj, the head is the head of the coordination
						if sentence[w].split()[5] == 'COORD':	
							head = sentence[int(head)-1].split()[4]
				
						i = 1
						while (w+i in range(len(sentence))):
							if (sentence[w+i].split()[2][:2] == 'NN') and (head == sentence[w+i].split()[3]) and (regex.match(sentence[w+i].split()[1])):
								nextWord = sentence[w+i].split()[1]+'-'+sentence[w+i].split()[2][0].lower()
								currentPair = current+'_'+nextWord
								elements.write(currentPair+'\n')

								## Get coocs [A_N,w] for each A_N and for w to the RIGHT of A_N
								q=1
								while ((i+q)<=n) and (w+i+q in range(len(sentence))):
									if regex.match(sentence[w+i+q].split()[1]):
										nextPos = sentence[w+i+q].split()[2][:2].lower()
										nextWord = sentence[w+i+q].split()[1]+'-'+nextPos[0]
										if (sentence[w+i+q].split()[2][:2] not in ('NN','JJ','VV','RB')):
											nextWord = sentence[w+i+q].split()[1]+'-'+nextPos[:2]
										tuples.write('%s\t%s\n' % (currentPair,nextWord))
									q+=1

								## Get coocs [A_N,w] for each A_N and for w to the LEFT of A_N
								q=1
								while (q<=n) and (w-q>=0):
									if regex.match(sentence[w-q].split()[1]):
										prevPos = sentence[w-q].split()[2][:2].lower()
										prevWord = sentence[w-q].split()[1]+'-'+prevPos[0]
										if (sentence[w-q].split()[2][:2] not in ('NN','JJ','VV','RB')):
											prevWord = sentence[w-q].split()[1]+'-'+prevPos[:2]
										tuples.write('%s\t%s\n' % (currentPair,prevWord))
									q+=1
							i+=1

		# re-initiate sentence after processing
		sentence=[]	

		# if script has seen over 500M tokens, close current output files and open new outfiles
		if x>=500000000:
			sys.stderr.write('\nFiles elements'+str(f)+'.gz and tuples'+str(f)+'.gz complete...\nTotal Word Count:\t'+str(totalWordCount)+'\n')	## Progress Report
			elements.close(); tuples.close(); f+=1; x=0
			elements = gzip.open(d+'/extracted-files/elements'+str(f)+'.gz','wb')
			tuples = gzip.open(d+'/extracted-files/tuples'+str(f)+'.gz','wb')

elements.close(); tuples.close(); 

sys.stderr.write(' ...done with extraction!\n')	## Progress Report



