#! /bin/env python2.7
# compute_cosines_of_vectors.py

import sys, fileinput
from numpy.linalg import norm
from numpy import *
from getopt import getopt

def usage():
	print '\n'
	print 'Usage():\n\tcompute_cosines_of_vectors.py -t <file> -s <file> -d <dimension> (-p)'
	print ''
	print '\t-t <file>\t\tfile containing target vectors'
	print '\t-s <file>\t\tvector space of interest'
	print '\t-d <dimension>\t\tnumber of dimensions of vectors, default=300'
	print '\t-p\t\t\toption adds \"p.\" to target rownames in output'
	print '\t-h,--help\t\tprint this message'
	print ''
	sys.exit(0)

#--------------------------------------------------------

p = ''
d=300

## Read command line arguements
optlist, args = getopt(sys.argv[1:], 'hpt:s:d:', ['help'])

## Get user-specified options
for opt, value in optlist:
	if opt in ('-h', '--help'): usage()
	if opt in ('-t'): t = str(value)
	if opt in ('-s'): s = str(value)
	if opt in ('-d'): d = int(value)
	if opt in ('-p'): p = 'p.'

#--------------------------------------------------------

# funct to open file with check for errors
def open_file(filename):
	try: x = open(filename,'r')
	except NameError:
		sys.stderr.write("NameError: target filename not specified\n\n"); usage()
	except IOError as (errno, strerror):
		sys.stderr.write("I/O error({0}): {1} ".format(errno, strerror)+"\""+str(filename)+"\"\n"); sys.exit(1)
	except:
		sys.stderr.write("Unexpected error: "+str(sys.exc_info()[0]))+"\n"; sys.exit(1)
	else: return x

#--------------------------------------------------------

# use numpy to create d-dimensional vectors; use preallocation to improve speed
anV = zeros(d, float32)
rowV = zeros(d, float32)

tFile = open_file(t)
sFile = open_file(s)

for tLine in tFile:
	an = tLine.split()[0]
	anV = array(tLine.split()[1:], dtype=float32)
	sFile.seek(0)
	for sLine in sFile:
		row = sLine.split()[0]
		rowV = array(sLine.split()[1:], dtype=float32)
		c = dot(anV,rowV) / ( norm(anV) * norm(rowV) )
		print '%s%s\t%s\t%.5f' % (p, an, row, c)

tFile.close(); sFile.close()

#--------------------------------------------------------

# (eof)
