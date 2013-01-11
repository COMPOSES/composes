#! /bin/env python2.7
# compute_LogFq_from_pairs.py
# LAST MODIFIED FEBRUARY 21 2011

import sys, math, os, gzip, fileinput, zlib, re
from getopt import getopt

#--------------------------------------------------------------------------------------------------------

#-----------------------------------
# input:
# a file in format
# w1 w2 fq
#
# output:
# for each triple in cooc table:
# w1 w2 logfq
#-----------------------------------

def usage():
	print ''
	print 'This script inputs a file of cooccurrences and their raw frequencies, '
	print 'and outputs the log(frequency) for each cooccurrence.'
	print ''
	print 'Usage():'
	print ''
	print sys.argv[0]+' <cooc_file> <target_rows> <target_columns>'
	print ''
	print '\tcooc_file\ta file in format:\tw1  w2  fq'
	print '\ttarget_rows\tall rows for which to compute the LMI'
	print '\ttarget_columns\tall columns for which to compute the LMI'
	print '\t-h, --help\tprint this message'
	print ''
	sys.exit(0)

## Read command line arguements
optlist, args = getopt(sys.argv[1:], 'h', ['help'])

## get user-specified options
for opt, value in optlist:
	if opt in ('-h', '--help'): usage()
		
if len(sys.argv) < 4: usage()
cooc_filename=sys.argv[1]
rows_filename=sys.argv[2]
columns_filename=sys.argv[3]

target_rows={}
rows_file=open(rows_filename,'r')
for line in rows_file:
	target_rows[line.split()[0]]=1

rows_file.close()

target_columns={}
columns_file=open(columns_filename,'r')
for line in columns_file:
	target_columns[line.split()[0]]=1

columns_file.close()

sys.stderr.write('\nReading cooccurrences and calculating log(fqs) for target vocab...\n')	## Progress Report

logFreq=0.0
if cooc_filename[-3:] == ".gz": coocsFile = gzip.open(cooc_filename,'rb')
else: coocsFile = open(cooc_filename,'r')
for line in coocsFile:
	if target_rows.has_key(line.split()[0]) and target_columns.has_key(line.split()[1]):
		freq = float(line.split()[2])
		logFreq = math.log(freq)
		print line.split()[0]+'\t'+line.split()[1]+'\t'+str(logFreq)

sys.stderr.write('. done!\n\nCooccurrences statistics calculated successfully!\n\n')	## Progress Report

