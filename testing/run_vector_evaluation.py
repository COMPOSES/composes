#!/usr/bin/env python

import sys, fileinput, string, glob, os, shutil, heapq
from numpy.linalg import norm
from numpy import *

# use numpy to create d-dimensional vectors; use preallocation to improve speed
d=300
dir_path='' # to be filled with outDir in pipeline
model_name='' # to be filled with file name info in pipeline
p_anV = zeros(d, float32)
rowV = zeros(d, float32)

#--------------------------------------------------------

ss_dict={}
ss=open('reduced.matrix','r')
for line in ss:
    ss_dict[line.split()[0]]=array(line.split()[1:], dtype=float32)

ss.close()
ss_keys=ss_dict.keys()
rank_file=open('rank_of_observed_equivalent.txt','w')
neighbor_file=open('top-ten-neighbors.txt','w')
    
for file_path in glob.glob(os.path.join(dir_path,'*-j-add_an-reduced.matrix.mat',model_name)):
    tFile = open(file_path, "r")
    p_dict={}
    for tLine in tFile:
        p_an = tLine.split()[0]
        p_anV = array(tLine.split()[1:], dtype=float32)
        c=dot(p_anV,ss_dict[p_an]) / ( norm(p_anV) * norm(ss_dict[p_an]) )
        rank_counter=1; tmp_counter=1
        neighbors={}
        neighbors[c]=p_an
        for row in ss_keys:
            new_c=dot(p_anV,ss_dict[row]) / ( norm(p_anV) * norm(ss_dict[row]) )
            if new_c > c: rank_counter+=1
            if tmp_counter<10:
                neighbors.update({new_c: row})
                tmp_counter+=1
            else:
                if new_c > heapq.nsmallest(1, neighbors.iteritems())[0][0]:
                    neighbors.update({new_c: row})
                    neighbors.pop(heapq.nsmallest(1, neighbors.iteritems())[0][0])
        rank_file.write(p_an+'\t'+str(rank_counter)+'\n')
        for k,v in neighbors.iteritems():
            neighbor_file.write(p_an+'\t'+v+'\t'+str(k)+'\n')
    tFile.close()

rank_file.close(); neighbor_file.close()
