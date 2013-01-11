#!/usr/bin/python

import sys, string, glob, os, shutil, heapq
from numpy.linalg import norm
from numpy import *
import time
from getopt import getopt
from operator import itemgetter

def usage():
	print ''
	print 'Usage():\n\t'+os.path.basename(sys.argv[0])+' <input_vector_file> <matrix_file> <output_prefix> (-u)'
	print ''
	print '\t<input_vector>\t\tfile containing vectors to be analyzed'
	print '\t<matrix_file>\t\tfile containing semantic space'
	print '\t<output_prefix>\t\tprefix (with path) of output files'
	print '\t-u \t\t\tpass this argument for plausibility experiments (ie, unattested ANs)'
	print '\t-h,--help\t\tprint this message'
	print ''
	sys.exit(0)

#--------------------------------------------------------

def loadVectorsToDict(filename):
	vdict={}
	vfile=open(filename,'r')
	for line in vfile:
    	arr = line.split()[:]
	    vdict[arr[0]]=array(arr[1:], dtype=float32)

	vfile.close()
	vkeys = vdict.keys()
	return ( vdict, vkeys )

#--------------------------------------------------------

# Initiate global parameters
topNN = 10	# how many nearest neighbors to return
u = 0		# =1 if working with unattested vectors

## Read command line arguments
if len(sys.argv) < 4:
	usage()
else:
	print '\n[begin] '+os.path.basename(sys.argv[0])
	input_file = sys.argv[1]
	ss_file = sys.argv[2]
	oprefix = sys.argv[3]

## Get user-specified options
optlist, args = getopt(sys.argv[4:], 'hu', ['help'])
for opt, value in optlist:
	if opt in ('-h', '--help'): usage()
	if opt in ('-u'): u = 1

#--------------------------------------------------------

start_time = time.time()

# Read in semantic space
(ss_dict, ss_keys) = loadVectorsToDict(ss_file)

print 'matrix in memory:\t', time.time() - start_time, 'seconds'

partial_time = time.time()

# Read in all predicted vectors
(p_dict, p_keys) = loadVectorsToDict(input_file)

print 'predicted vectors in memory:\t', time.time() - partial_time, 'seconds'

# get the rank-of-observed-equivalent if the AN vectors are for attested ANs
# and get the distance-from-component-n as well as the nearest neighbor to predicted AN
# if the AN vectors are for unattested ANs (Plausibility Experiments)
neighbor_file = open(oprefix+'.top-ten-neighbors.txt','w')
if u == 0:
	rank_file = open(oprefix+'.rank_of_observed_equivalent.txt','w')
else:
	vector_length_file = open(oprefix+'.vector_length.txt','w')
	cosine_from_n_file = open(oprefix+'.cosine_from_component_n.txt','w')
	average_neighbors_file = open(oprefix+'.average_of_nearest_neighbors.txt','w')

partial_time = time.time()

# Compute evaluation of vectors
sys.stderr.write('Running evaluation...\n')
for an in p_keys:
	rank_counter = 1
	# get the cosine(predictedAN,observedAN) if attested
	if u == 0: 
		c = dot(p_dict[an],ss_dict[an]) / (norm(p_dict[an]) * norm(ss_dict[an]))
	# else, get vector_length and cosine(predictedAN,observedN) if unattested
	else:
		length = sqrt(vdot(p_dict[an],p_dict[an]))
		vector_length_file.write('%s\t%.5f\n'%(an,length))
		noun = an.split('_')[1]
		if ss_dict.has_key(noun): 
			noun_c = dot(p_dict[an],ss_dict[noun]) / (norm(p_dict[an]) * norm(ss_dict[noun]))
			cosine_from_n_file.write('%s\t%.5f\n'%(an,noun_c))
	neighbors = {}
	min_val = 0.0
	for row in ss_keys:
		new_c = dot(p_dict[an],ss_dict[row]) / (norm(p_dict[an]) * norm(ss_dict[row]))
	    if u == 0:
	       	if new_c > c:
		   		rank_counter+=1
		if len(neighbors.keys()) == topNN:
			min_val = min(neighbors.keys())
		if len(neighbors.keys()) < topNN:
			neighbors.update({new_c: row})
		elif new_c > min_val:
			if neighbors.has_key(new_c):
		    	neighbors.update({new_c: row})
			elif not neighbors.has_key(new_c):
		    	neighbors.update({new_c: row})
				neighbors.pop(min_val)
				min_val = min(neighbors.keys())	    
	if u == 0:
		rank_file.write('%s\t%d\n'%(an,rank_counter))
	else:
		average_neighbors = sum(neighbors.keys())/len(neighbors.keys())
	    average_neighbors_file.write('%s\t%.5f\n'%(an,average_neighbors))
	for x in sorted(neighbors.iteritems(),reverse=True):
	   	neighbor_file.write('%s\t%s\t%.5f\n'%(an,x[1],x[0]))

print '\nTotal time:\t', time.time() - start_time, "seconds"

if u == 0: rank_file.close()
else: cosine_from_n_file.close(); vector_length_file; average_neighbors_file.close()
neighbor_file.close()

print '[end] '+os.path.basename(sys.argv[0])+'\n'


