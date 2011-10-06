#! /bin/env python2.7
# combine_vectors.py

import sys, fileinput
from numpy import *
from getopt import getopt

def usage():
	print '\n'
	print 'Usage():\n\tcombine_vectors.py -u[file] -v[file] (-[mdn]) (-w[NuNv] -l[lambda])'
	print ''
	print '\t-u [file]\t\tfile containing U vectors'
	print '\t-v [file]\t\tfile containing V vectors'
	print '\t-[md]\t\t\tspecify to combine vectors using Multiplication (-m) or Dilation (-d), default Addition'
	print '\t-w [NuNv]\t\tspecifiy weights for U and V vectors for Addition or Multiplication, default none'
	print '\t-l [lambda]\t\tspecifiy lambda parameter for Dilation, default 16.7'
	print '\t-n\t\t\toption to use normalized U and V vectors'
	print '\t-h,--help\t\tprint this message'
	print ''
	sys.exit(0)

#--------------------------------------------------------

## Set Defaults Values
model='a'
wU=1; wV=1; l=16.7
normalize=False

## Read command line arguements
optlist, args = getopt(sys.argv[1:], 'hmdnu:v:w:p:l:', ['help'])
if len(optlist) < 2: usage()

## Get user-specified options
for opt, value in optlist:
	if opt in ('-h', '--help'): usage()
	if opt in ('-m'): model='m'
	if opt in ('-d'): model='d'
	if opt in ('-u'): uFileName = value
	if opt in ('-v'): vFileName = value
	if opt in ('-w'): 
		wU = value.split(',')[0]
		wV = value.split(',')[1]
	# also include pipeline-specified weight format
	if opt in ('-p'):
		wU = 0.1*int(value[0])
		wV = 0.1*int(value[2])
	if opt in ('-l'): l = value
	if opt in ('-n'): normalize = True

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

# funct to normalize vectors
def norm(x):
	return x/sqrt(sum(dot(x,x)))

# M&L equation (23):
# v' = ((lambda -1) ((u \dot v)/(u \dot u)) u) + v
def dilate(u,v,l):
	return ((float(l) - 1.0) * ((dot(u,v)/dot(u,u)) * u)) + v

#--------------------------------------------------------
uFile = open_file(uFileName)
vFile = open_file(vFileName)

for uLine in uFile:
	uName = uLine.split()[0]
	u = array(map(float, uLine.split()[1:]), float)
	if normalize == True: u = norm(u)

	vFile.seek(0)
	for vLine in vFile:
		vName = vLine.split()[0]
		v = array(map(float, vLine.split()[1:]), float)
		if normalize == True: v = norm(v)

		if model == 'a': V = float(wU)*u + float(wV)*v
		elif model == 'm': V = float(wU)*u * float(wV)*v
		elif model == 'd': V = dilate(u,v,l)

		print uName+'\t'+vName,
		for i in V.tolist(): print '\t'+'%.10f'%(i),
		print ''


uFile.close(); vFile.close()


#--------------------------------------------------------

# (eof)
