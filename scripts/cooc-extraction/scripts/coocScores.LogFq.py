#! /bin/env python2.7
# coocScores.LogFq.py
# LAST MODIFIED JULY 21 2011

import sys, math, string, os, gzip, fileinput, zlib, functions

#--------------------------------------------------------------------------------------------------------

##############
##          ## 
##  main()  ##
##          ##
##############

logFreq=0.0

d='cooc.output.w-adverbs/'

sys.stderr.write('\nPreparing output file and calculating the scores...')	## Progress Report

outFile = gzip.open(d+'logfq.all.gz','wb');

for line in fileinput.input():

	freq = float(line.split()[2])

	if (freq > 1.0):
		logFreq = math.log(freq)
		outFile.write(line.split()[0]+'\t'+line.split()[1]+'\t'+str(logFreq)+'\n')

outFile.close()

sys.stderr.write('. done!\n\nCooccurrences statistics calculated successfully!\n\n')	## Progress Report

