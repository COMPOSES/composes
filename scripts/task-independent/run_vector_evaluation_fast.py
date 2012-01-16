#!/usr/bin/env python2.7

import sys, fileinput, string, glob, os, shutil, heapq
from numpy.linalg import norm
from numpy import *
import time
from getopt import getopt
from operator import itemgetter

def usage():
	print ''
	print 'Usage():\n\tcompute_cosines_of_vectors.py -o <dir_path> -d <data_path> -m <model> -s <space> -p <param> (-u)'
	print ''
	print '\t-o <dir_path>\t\toutput directory where to find adjective-j directories'
	print '\t-o <data_path>\t\tdirectory containing semantic spaces'
	print '\t-m <model>\t\tmodel (add|mult|dl|lm|alm)'
	print '\t-s <space>\t\tvector space of interest (full|reduced)'
	print '\t-p <param>\t\tmodel parameters (if any)'
	print '\t-u \t\t\tpass this argument for plausibility experiments (ie, unattested ANs)'
	print '\t-h,--help\t\tprint this message'
	print ''
	sys.exit(0)

#--------------------------------------------------------

s = 'reduced'
p = ''
u = 0

## Read command line arguments
optlist, args = getopt(sys.argv[1:], 'hus:m:p:o:d:', ['help'])

## Get user-specified options
for opt, value in optlist:
	if opt in ('-h', '--help'): usage()
	if opt in ('-o'): o = str(value)
	if opt in ('-m'): m = str(value)
	if opt in ('-s'): s = str(value)
	if opt in ('-p'): p = str(value)
	if opt in ('-d'): d = str(value)
	if opt in ('-u'): u = 1

try: m
except NameError: 
	sys.stderr.write("NameError: model not specified"); usage()

if p=='_': p=''
if o[-1]!='/': o+='/'
if d[-1]!='/': d+='/'

#--------------------------------------------------------

#--------------------------------------------------------

start_time = time.time()
ss_dict={}
ss_norms = {}
ss=open(d+s+'.matrix','r')
for line in ss:
    arr = line.split()[:]
    ss_dict[arr[0]]=array(arr[1:], dtype=float32)
    ss_norms[arr[0]] = norm(ss_dict[arr[0]])

ss.close()

print 'matrix in memory:\t', time.time() - start_time, "seconds"

partial_time = time.time()
ss_keys = ss_dict.keys()
# get the rank-of-observed-equivalent if the AN vectors are for attested ANs
# and get the distance-from-component-n as well as the nearest neighbor to predicted AN
# if the AN vectors are for unattested ANs (Plausibility Experiments)
if u == 0:
	rank_file = open(o+'eval/'+m+'-'+s+p+'.rank_of_observed_equivalent.txt','w')
else:
	vector_length_file = open(o+'eval/'+m+'-'+s+p+'.vector_length.txt','w')
	distance_from_n_file = open(o+'eval/'+m+'-'+s+p+'.distance_from_component_n.txt','w')
	nearest_neighbor_file = open(o+'eval/'+m+'-'+s+p+'.nearest_neighbor.txt','w')
	average_neighbors_file = open(o+'eval/'+m+'-'+s+p+'.average_of_nearest_neighbors.txt','w')
neighbor_file = open(o+'eval/'+m+'-'+s+p+'.top-ten-neighbors.txt','w')
norm_p_anV = 0
count = 1
for file_path in glob.glob(os.path.join(o,'*-j/models/',m+'_an-'+s+p+'.mat')):
    tFile = open(file_path, "r")
    p_dict = {}    
    for tLine in tFile:
	rank_counter = 0; tmp_counter = 1
	tArr = tLine.split()[:]
        p_an = tArr[0]
        p_anV = array(tArr[1:], dtype=float32)
	norm_p_anV = norm(p_anV)
	# get the cosine(predictedAN,observedAN) if attested
	if u == 0: c = dot(p_anV,ss_dict[p_an]) / (norm_p_anV * ss_norms[p_an])
	# else, get vector_length and cosine(predictedAN,observedN) if unattested
	else:
		length = sqrt(vdot(p_anV,p_anV))
		vector_length_file.write(p_an+'\t'+str(length)+'\n')
		noun = p_an.split('_')[1]
		if noun in ss_keys: noun_c = dot(p_anV,ss_dict[noun]) / (norm_p_anV * ss_norms[noun])
		distance_from_n_file.write(p_an+'\t'+str(noun_c)+'\n')
        neighbors = {}
        min_val = 0.0
        for row in ss_keys:
            new_c = dot(p_anV,ss_dict[row]) / (norm_p_anV * ss_norms[row])
	    if u == 0:
		    if new_c > c:
			    rank_counter+=1
	    if len(neighbors.keys()) == 10:
		min_val = min(neighbors.keys())
	    if len(neighbors.keys()) < 10:
                neighbors.update({new_c: row})
                tmp_counter+=1
            elif new_c > min_val:
		if neighbors.has_key(new_c):
		    neighbors.update({new_c: row})
		    neighbors
		elif not neighbors.has_key(new_c):
		    neighbors.update({new_c: row})
                    neighbors.pop(min_val)
                    min_val = min(neighbors.keys())
		    
        if u == 0:
		rank_file.write(p_an+'\t'+str(rank_counter)+'\n')
	else:
		nearest_neighbor_file.write(p_an+'\t'+str(max(neighbors.keys()))+'\n')
		average_neighbors = sum(neighbors.keys())/len(neighbors.keys())
		average_neighbors_file.write(p_an+'\t'+str(average_neighbors)+'\n')
	for x in sorted(neighbors.iteritems(),reverse=True):
            neighbor_file.write(p_an+'\t'+x[1]+'\t'+str(x[0])+'\n')
    tFile.close()
#    print 'file ' + str(count) + ' processed in ', time.time() - partial_time, "seconds"
#    partial_time = time.time()
    count += 1

print 'total time:\t', time.time() - start_time, "seconds"

if u == 0: rank_file.close()
else: distance_from_n_file.close(); nearest_neighbor_file.close(); vector_length_file; average_neighbors_file.close()
neighbor_file.close()
