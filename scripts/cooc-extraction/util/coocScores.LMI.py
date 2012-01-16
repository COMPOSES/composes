#! /bin/env python2.7
# LAST MODIFIED JANUARY 16 2012

import sys, math, os, gzip, fileinput, zlib, re

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
	print 'Usage():\n\t'+sys.argv[0]+' [cooc_file] [core_dir]'
	print '\t[cooc_file]\ta file in format:\tw1  w2  fq'
	print '\t[core_dir]\toutput directory to print core matrix counts'
	print ''
	sys.exit(0)

if len(sys.argv) < 2: usage()
filename=sys.argv[1]
outDir=sys.argv[2]
w1_freqs = {}
w2_freqs = {}
N = 0.0
an = re.compile('\-j\_.*\-n')

sys.stderr.write('\nCollecting frequencies of w1, w2 and elements...')	## Progress Report

if filename[-3:] == ".gz": coocsFile = gzip.open(filename,'rb')
else: coocsFile = open(filename,'r')

for line in coocsFile:
	w1 = line.split()[0]
	w2 = line.split()[1]
	f = float(line.split()[2])
	try: w1_freqs[w1] += f
	except KeyError:
		w1_freqs[w1] = f
	if ( w1[-2:] in ("-j","-n") ) and ( not an.search(w1) ):
		try: w2_freqs[w2] += f
		except KeyError:
			w2_freqs[w2] = f
		N += f

sys.stderr.write('done\n\nCalculating Local Mutual Information of cooccurrences...')	## Progress Report

coocsFile.seek(0)
for line in coocsFile:
	w1 = line.split()[0]
	w2 = line.split()[1]
	obs_fq = float(line.split()[2])
	w1_fq = float(w1_freqs[w1])
	w2_fq = float(w2_freqs[w2])
	local_mi = obs_fq * ( math.log( (obs_fq * N) / (w1_fq * w2_fq) ) )
	print '%s\t%s\t%.4f' % (w1, w2, local_mi)

coocsFile.close()

sys.stderr.write('done\n\nPrinting core matrix counts to files\n'+d+'/core_N.txt\n'+d+'/core_Cw2.gz\n...')	## Progress Report

core_Cw2_file = gzip.open(d+'/core_Cw2.gz','wb')
for k, v in w2_freqs.iteritems():
	core_Cw2_file.write(k+'\t'+str(v)+'\n')

core_Cw2_file.close()

core_N_file = open(d+'/core_N.txt','w')
core_N_file.write(str(N)+'\n')
core_N_file.close()

sys.stderr.write('done\n\n')	## Progress Report

