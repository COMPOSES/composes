#! /bin/env python2.7

import sys, string, glob, os, shutil, heapq
from numpy.linalg import norm
from numpy import *
from getopt import getopt

def usage():
	print ''
	print 'Usage():'
	print ''
	print os.path.basename(sys.argv[0])+' [sem-space] [pair-file] [betas-path] [dims] (-h)'
	print ''
	print '\tpair_file\ta file in format:\te1\te2'
	print '\t-h, --help\tprint this message'
	print ''
	sys.exit(0)

def norm(x):
	return x/sqrt(sum(dot(x,x)))
	
if len(sys.argv) < 5: usage()

optlist, args = getopt(sys.argv[1:], 'h', ['help'])
## Get user-specified options
for opt, value in optlist:
	if opt in ('-h', '--help'): usage()

s=sys.argv[1]
sys.stderr.write("sem space dir: "+s+"\n")
pairfile=open(sys.argv[2],'r')
sys.stderr.write("pairfile: "+str(pairfile)+"\n")
betasPath=sys.argv[3]
dims=sys.argv[4]
sys.stderr.write("dims: "+dims+"\n")

if betasPath[-1]!='/':
	betasPath=betasPath+'/'

sys.stderr.write("path to betas: "+betasPath+"\n")

ss_dict={}
ss=open(s,'r')
for line in ss:
    arr = line.split()[:]
    ss_dict[arr[0]]=array(arr[1:], dtype=float32)

ss.close()
ss_keys = ss_dict.keys()

pairfile.seek(0)
output={}
for line in pairfile:
	line=line.strip()
	a=line.split()[0]
	n=line.split()[1]
	an=a+'_'+n
	try:
		a_betas=genfromtxt(betasPath+a+'.'+dims+'.rr-gcv.betas')
	except: 
		sys.stderr.write("Error: no betas file for \""+a+"\"\n")
		continue
	n_vec=append(norm(ss_dict[n]),[1],0)
	an_vec=matrix(n_vec)*a_betas
	output[an]=resize(array(an_vec.T),[int(dims),])

for k,v in output.iteritems():
	print k,
	for i in v.tolist(): print '\t'+'%.10f'%(i),
	print ''
