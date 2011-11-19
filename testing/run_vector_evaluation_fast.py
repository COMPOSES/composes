#!/usr/bin/env python

import sys, fileinput, string, glob, os, shutil, heapq
from numpy.linalg import norm
from numpy import *
import time

# use numpy to create d-dimensional vectors; use preallocation to improve speed
d=300
dir_path='/home/elia.bruni/eva-test/testing/' # to be filled with outDir in pipeline
model_name='' # to be filled with file name info in pipeline
p_an = ''
p_anV = zeros(d, float32)
rowV = zeros(d, float32)

#--------------------------------------------------------
start_time = time.time()
ss_dict={}
ss=open('/mnt/8tera/shareZBV/data/an-vector-pipeline/data/full.matrix','r')
ss_norms = {}
for line in ss:
    arr = line.split()[:]
    ss_dict[arr[0]]=array(arr[1:], dtype=float32)
    ss_norms[arr[0]] = norm(ss_dict[arr[0]])

ss.close()

print 'reduce.matrix in memory'
print time.time() - start_time, "seconds"
partial_time = time.time()
ss_keys=ss_dict.keys()
rank_file=open('rank_of_observed_equivalent.txt','w')
neighbor_file=open('top-ten-neighbors.txt','w')
min_val = 0 
norm_p_anV = 0
count = 1
for file_path in glob.glob(os.path.join('/home/elia.bruni/eva-test/testing/','*-j-add_an-full.matrix.mat')):
    tFile = open(file_path, "r")
    p_dict={}
    for tLine in tFile:
	tArr = tLine.split()[:]
        p_an = tArr[0]
        p_anV = array(tArr[1:], dtype=float32)
	norm_p_anV = norm(p_anV)
        c=dot(p_anV,ss_dict[p_an]) / (norm_p_anV * ss_norms[p_an])
        rank_counter=1; tmp_counter=1
        neighbors={}
        neighbors[c]=p_an
        for row in ss_keys:
            new_c=dot(p_anV,ss_dict[row]) / (norm_p_anV * ss_norms[row])
            if new_c > c: rank_counter+=1
            if tmp_counter<10:
                neighbors.update({new_c: row})
		min_val = min(neighbors.keys())
                tmp_counter+=1
            else:
                if new_c > min_val:
                    neighbors.update({new_c: row})
                    neighbors.pop(min_val)
		    min_val = min(neighbors.keys())
        rank_file.write(p_an+'\t'+str(rank_counter)+'\n')
        for k,v in neighbors.iteritems():
            neighbor_file.write(p_an+'\t'+v+'\t'+str(k)+'\n')
    tFile.close()
    print 'file ' + str(count) + ' processed in '
    print time.time() - partial_time, "seconds"
    partial_time = time.time()
    print 'total time'	
    print time.time() - start_time, "seconds"
    count += 1

rank_file.close(); neighbor_file.close()
