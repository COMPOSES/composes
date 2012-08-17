#! /bin/env python2.7
# LAST MODIFIED JANUARY 16 2012

import sys, math, os, gzip, fileinput, zlib, re
from getopt import getopt

#-----------------------------------
# input:
# a file in format
# w1 w2 fq
#
# output:
# for each triple in cooc table:
# w1 w2 localmi
#-----------------------------------

def usage():
	print ''
	print 'This script inputs a file of cooccurrences and their raw frequencies, '
	print 'and outputs the Local Mutual Information (LMI) for each cooccurrence.'
	print ''
	print '\tLMI = C(r,c) * log( ( C(r,c)C(*,*) ) / ( C(r,*)C(*,c) ) )'
	print ''
	print 'Note: this script calculates the LMI based on a core matrix of nouns and adjectives'
	print '      the core matrix is output to a directory specified by the user.'
	print ''
	print ''
	print 'Usage():'
	print ''
	print sys.argv[0]+' <cooc_file> <core_matrix_dir> <core_elements> <target_rows> <target_columns>'
	print ''
	print '\tcooc_file\ta file in format:\tw1  w2  fq'
	print '\tcore_matrix_dir\toutput directory to print core matrix counts (full path)'
	print '\tcore_elements\telements to use to compute the core matrix LMIs'
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
		
if len(sys.argv) < 6: usage()
cooc_filename=sys.argv[1]
outDir=sys.argv[2]
core_filename=sys.argv[3]
rows_filename=sys.argv[4]
columns_filename=sys.argv[5]
w1_freqs = {}
w2_freqs = {}
N = 0.0

core_elements={}
core_file = open(core_filename,'r')
for line in core_file:
	core_elements[line.split()[0]]=1

core_file.close()

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

#an = re.compile('\-j\_.*\-n')

sys.stderr.write('\nCollecting frequencies of w1, w2 and elements...')	## Progress Report

if cooc_filename[-3:] == ".gz": coocsFile = gzip.open(cooc_filename,'rb')
else: coocsFile = open(cooc_filename,'r')

for line in coocsFile:
	w1 = line.split()[0]
	w2 = line.split()[1]
	if target_rows.has_key(w1):
		f = float(line.split()[2])
		try: w1_freqs[w1] += f
		except KeyError:
			w1_freqs[w1] = f
		if core_elements.has_key(w1):
			try: w2_freqs[w2] += f
			except KeyError:
				w2_freqs[w2] = f
			N += f

sys.stderr.write('done\n\nCalculating Local Mutual Information of cooccurrences...')	## Progress Report

coocsFile.seek(0)
for line in coocsFile:
	w1 = line.split()[0]
	w2 = line.split()[1]
	if target_rows.has_key(w1) and target_columns.has_key(w2):
		obs_fq = float(line.split()[2])
		w1_fq = float(w1_freqs[w1])
		w2_fq = float(w2_freqs[w2])
		local_mi = obs_fq * ( math.log( (obs_fq * N) / (w1_fq * w2_fq) ) )
		#if local_mi < 0.0:
		#	local_mi = 0.0
		#	print '%s\t%s\t%.4f' % (w1, w2, local_mi)
		if local_mi > 0.0:
			print '%s\t%s\t%.4f' % (w1, w2, local_mi)

coocsFile.close()

sys.stderr.write('done\n\nPrinting core matrix counts to files\n'+outDir+'/core_N.txt\n'+outDir+'/core_Cw2.gz\n...')	## Progress Report

core_Cw2_file = gzip.open(outDir+'/core_Cw2.gz','wb')
for k, v in w2_freqs.iteritems():
	core_Cw2_file.write(k+'\t'+str(v)+'\n')

core_Cw2_file.close()

core_N_file = open(outDir+'/core_N.txt','w')
core_N_file.write(str(N)+'\n')
core_N_file.close()

sys.stderr.write('done\n\n')	## Progress Report

