#! /bin/env python2.7
# functions.py
# LAST MODIFIED AUGUST 2 2011

import sys, math, re, os, shutil, gzip
from getopt import getopt
import subprocess as S

#--------------------------------------------------------------------------------------------------------

## NOTES:

# Terminology: 
#	- "elements" refers to the content words which are extracted
# 	- "coocs" refers to the cooccurrences of the adjectives, nouns
#	   and ANs in the corpus which occur in the specified window length

# Updates:
#	- Head-Based Strategy [Apr-18-2011] for extractData() funct : 
#	  Adjectives are concatenated with all HEAD Nouns to created AN pairs (based on dependency annots)
#
#	- NOTE: this version extracts only elements and cooccurrences for the following POS: {NN, VV, JJ, RB}
#		Does not extract counts or cooccurrences for determiners, proper nouns, etc.

#--------------------------------------------------------------------------------------------------------

## function that extracts the data (content words and their coocs) from the 
## corpus based on the specified window length
def extractData(sentence,elements,coocs,window):

	coocCount=0; w=0; n=window

	## Filter applied to extract only words containing...
	## - alphabetical characters
	## - non-initial, non-final dashes 
	regex = re.compile('^[a-zA-Z]+[a-zA-Z\-]*(\_[a-zA-Z]+[a-zA-Z\-]*)?[a-zA-Z]$')

	for w in range(len(sentence)):

		if not regex.match(sentence[w].split()[1]): w+=1; continue	# point where filter is applied
		
		current = sentence[w].split()[1]+'-'+sentence[w].split()[2][0].lower()
		pos = sentence[w].split()[2][:2].lower()
		if sentence[w].split()[2][:2] in ('NN','JJ','VV','RB'):
			elements.write('%s\n' % (current))

		## Continue to extract the tuple information if the current word is a noun or adjective
		if sentence[w].split()[2][:2] in ('NN','JJ'):

			i=1
			while (i<=n) and (w+i in range(len(sentence))):
				if (sentence[w+i].split()[2][:2] not in ('NN','JJ','VV','RB')) or (not regex.match(sentence[w+i].split()[1])):
					i+=1; continue
				nextPos = sentence[w+i].split()[2][:2].lower()
       				nextWord = sentence[w+i].split()[1]+'-'+nextPos[0]
				coocs.write('%s\t%s\t%s_%s\n' % (current,nextWord,pos,nextPos))
				coocCount += 1
				i+=1

			i=1
			while (i<=n) and (w-i>=0):
       				if (sentence[w-i].split()[2][:2] not in ('NN','JJ','VV','RB')) or (not regex.match(sentence[w-i].split()[1])):
       					i+=1; continue
       				prevPos = sentence[w-i].split()[2][:2].lower()
     	       			prevWord = sentence[w-i].split()[1]+'-'+prevPos[0]
	       			coocs.write('%s\t%s\t%s_%s\n' % (current,prevWord,pos,prevPos))
	       			coocCount += 1
				i+=1
				
			i=1
       			if sentence[w].split()[2][:2] in ('JJ'):
				compoundCheck=True

				head = sentence[w].split()[4]
				if sentence[w].split()[5] in ('COORD'):	# if part of a conj, the head is the head of the coordination
					head = sentence[int(head)-1].split()[4]

				while (compoundCheck==True) and (i<=n) and (w+i in range(len(sentence))):
				       	if sentence[w+i].split()[2][:2] in ('JJ','CC',','):
				       		i+=1; continue
					elif (sentence[w+i].split()[2][:2] in ('NN')) and (regex.match(sentence[w+i].split()[1])):
						if head > sentence[w+i].split()[3]: i+=1; continue
						elif head == sentence[w+i].split()[3]:
						       	pos = 'jn'
						       	nextWord = sentence[w+i].split()[1]+'-'+sentence[w+i].split()[2][0].lower()
						       	currentPair = current+'_'+nextWord
				       			elements.write(currentPair+'\n') 

				       			## Get coocs [A_N,w] for each A_N and for w to the RIGHT of A_N
				       			q=1
				       			while ((i+q)<=n) and (w+i+q in range(len(sentence))):
				       				if (sentence[w+i+q].split()[2][:2] not in ('NN','JJ','VV','RB')) or (not regex.match(sentence[w+i+q].split()[1])):
				       					q+=1; continue
				       				nextPos = sentence[w+i+q].split()[2][:2].lower()
				       				nextWord = sentence[w+i+q].split()[1]+'-'+nextPos[0]
				       				coocs.write('%s\t%s\t%s_%s\n' % (currentPair,nextWord,pos,nextPos))
				       				coocCount += 1
				       				q+=1

				       			## Get coocs [A_N,w] for each A_N and for w to the LEFT of A_N
				       			q=1
				       			while (q<=n) and (w-q>=0):
				       				if (sentence[w-q].split()[2][:2] not in ('NN','JJ','VV','RB')) or (not regex.match(sentence[w-q].split()[1])):
				       					q+=1; continue
				       				prevPos = sentence[w-q].split()[2][:2].lower()
				       				prevWord = sentence[w-q].split()[1]+'-'+prevPos[0]
				       				coocs.write('%s\t%s\t%s_%s\n' % (currentPair,prevWord,pos,prevPos))
				       				coocCount += 1
				       				q+=1
					else: compoundCheck=False	
					i+=1
		w+=1

	return coocCount


#--------------------------------------------------------------------------------------------------------

## function to calculate the Log Likelihood of a bigram
##		 
## 	G = 2 * E (Oi * ln( Oi/Ei ))
##		 i
def LogLikelihood(count, w1_fq, w2_fq, totBi):
	## first calculate 2x2 contingency table for the bigram	       w2  	^w2	total
	##							 w1 [ o11	o12   		]
	##							^w1 [ o21	o22 		]
	##						       total[ 		 	N	]

	## observed values
	N = float(totBi)
	o11 = float(count)
	o12 = w1_fq - o11
	o21 = w2_fq - o11
	o22 = N - w1_fq - w2_fq + o11

	## expected values
	e11 = (w1_fq * w2_fq) / N
	e12 = (w1_fq * (N - w2_fq)) / N
	e21 = (w2_fq * (N - w1_fq)) / N
	e22 = ((N - w1_fq) * (N - w2_fq)) / N

	## control in the case of negatives
	sign = 1
	if o11<e11: sign = -1
	
	term11 = o11 * (math.log(o11) - math.log(e11))
	
	term12 = 0.0
	if o12 != 0.0: term12 = o12 * (math.log(o12) - math.log(e12))

	term21 = 0.0
	if o21 != 0.0: term21 = o21 * (math.log(o21) - math.log(e21))

	term22 = 0.0
	if o22 != 0.0: term22 = o22 * (math.log(o22) - math.log(e22))

	score = sign * 2 * (term11 + term12 + term21 + term22)

	return score

#--------------------------------------------------------------------------------------------------------

## function to calculate Pointwise Mutual Information of a bigram
## 	PMI(w1,w2) = log[p(an)/p(a)p(n)]
def PMI(word1, word2, count, totalCount):	
	p_w1_w2 = float(count)/float(totalCount)
	p_w1 = float(word1)/float(totalCount)
	p_w2 = float(word2)/float(totalCount)

	pre_score = p_w1_w2/(p_w1*p_w2)
	score = math.log(pre_score)

	return score

#--------------------------------------------------------------------------------------------------------

#--------------------------------------------------------------------------------------------------------
