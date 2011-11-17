#! /bin/env python2.7
# element_frequencies.py
# LAST MODIFIED APRIL 15 2011

import sys, math, string, os, gzip, fileinput, zlib


#--------------------------------------------------------------------------------------------------------

##############
##          ## 
##  main()  ##
##          ##
##############

elements={}; tmp=[]; current=''

sys.stderr.write('\nReading file...')	## Progress Report

for line in fileinput.input():
	current = line.split()[0]
	if elements.has_key(current): elements[current] += 1
	else: elements[current] = 1

d='cooc.output-all.w-adverbs/'

element_outfile = gzip.open(d+'/elements.fqs.gz','wb')

for element,count in elements.iteritems():
	element_outfile.write(element+'\t'+str(count)+'\n')
element_outfile.close()
elements={}

sys.stderr.write('. done!\n\nFrequencies extracted successfully!\n\n')	## Progress Report

