#! /bin/env python2.7
# combine_vectors_of_pairs.py
# last updated: OCTOBER 12, 2012

import sys, fileinput
from numpy import *
from getopt import getopt

def usage():
	print ''
	print 'Input: a file containing the semantic space, a file containing elements for the U and V vectors'
	print 'Output: the combined vectors (p) based on the specified model:'
	print '\tAdditive model: p = u + v'
	print '\tWeighted Additive model: p = Au + Bv'
	print '\tMultiplicative Model: p = u * v'
	print '\tDilation Model: p = (u . u )v + (lambda - 1)(u . v)u'
	print '\n'
	print 'Usage():\n\tcombine_vectors_of_pairs.py -s[semantic-space] -f[pair-file] (-[mdn]) (-o[an|na]) (-w[NuNv] -l[lambda])'
	print ''
	print '\t-s [file]\t\tfile containing semantic space'
	print '\t-f [file]\t\tfile containing pairs of elements to combine, format: e1\te2'
	print '\t-[md]\t\t\tspecify to combine vectors using Multiplication (-m) or Dilation (-d), default Addition'
	print '\t-w [NuNv]\t\tspecifiy weights for U and V vectors for Addition or Multiplication, default none'
	print '\t-l [lambda]\t\tspecifiy lambda parameter for Dilation, default 16.7'
	print '\t-o [an|na]\t\tfor Dilation, specify which elements are U and V vectors, default \"an\"'
	print '\t\t\t\tan : e1 is U (adjective); e2 is V (noun)'
	print '\t\t\t\tna : e1 is V (adjective); e2 is U (noun)'
	print '\t-n\t\t\toption to use normalized U and V vectors'
	print '\t-h,--help\t\tprint this message'
	print ''
	sys.exit(0)

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

# funct to normalize vectors
def norm(x):
	return x/sqrt(sum(dot(x,x)))

#--------------------------------------------------------

# M&L equation (23):
# v' = ((lambda -1) ((u \dot v)/(u \dot u)) u) + v
def dilate(u,v,l):
	return ((float(l) - 1.0) * ((dot(u,v)/dot(u,u)) * u)) + v

#--------------------------------------------------------

## Set Defaults Values
model='a'
order='an'
wU=1.0; wV=1.0; l=16.7
normalize=False

## Read command line arguements
optlist, args = getopt(sys.argv[1:], 'hmdns:f:w:p:l:o:', ['help'])
if len(optlist) < 2: usage()

## Get user-specified options
for opt, value in optlist:
	if opt in ('-h', '--help'): usage()
	if opt in ('-m'): model='m'
	if opt in ('-d'): model='d'
	if opt in ('-s'): s = value
	if opt in ('-o'): order = value
	if opt in ('-f'): pairFileName = value
	if opt in ('-w','-p'): 
		wU = 0.1*int(value[0])
		wV = 0.1*int(value[2])
	if opt in ('-l'): l = value
	if opt in ('-n'): normalize=True

#--------------------------------------------------------
ss_dict={}
ss=open(s,'r')
for line in ss:
    arr = line.split()[:]
    ss_dict[arr[0]]=array(arr[1:], dtype=float32)

ss.close()
ss_keys = ss_dict.keys()

pairFile = open(pairFileName,'r')

for line in pairFile:
	uName = line.split()[0]
	vName = line.split()[1]
	if ss_dict.has_key(uName) and ss_dict.has_key(vName):
		u = ss_dict[uName]
		v = ss_dict[vName]
		if (model == 'd') and (order == 'na'):
			u = ss_dict[vName]
			v = ss_dict[uName]
		if normalize == True: 
			u = norm(u)
			v = norm(v)
		if model == 'a': V = float(wU)*u + float(wV)*v
		elif model == 'm': V = float(wU)*u * float(wV)*v
		elif model == 'd': V = dilate(u,v,l)
		print uName+'_'+vName,
		for i in V.tolist(): print '\t'+'%.10f'%(i),
		print ''
	else:
		sys.stderr.write("Unexpected error: \""+uName+"\" or \""+vName+"\" not found in semantic space.\n")
		sys.exit(1)


pairFile.close()


#--------------------------------------------------------

# (eof)
