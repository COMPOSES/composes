#!/usr/bin/python

# Author: Yao-zhong Zhang
# Data:  2012-5-9
# Description: Experiments on Adjective Noun

from __future__ import division
from time import clock
import sys
import numpy as np
import PLSR_ as learn

def loadTrainData(noun_vec_file, an_vec_file):
	
	# n-hash
	noun_hash = loadVectors(noun_vec_file)
	
	# 0. train-n-vector
	print "Total num of nouns:", len(noun_hash)
	
	adj_hash = {}
	# 1. train-vn-vectors
	an_file = open(an_vec_file,'r')
	an_samples = an_file.readlines()
	for an_sample in an_samples:
		an_sample = an_sample.strip()
		an_elems = an_sample.split()
		an_words = an_elems[0]
		(an_adj, an_noun) = an_words.split("_")
		#nv_vector = np.array(nv_elems[1:len(nv_elems)])
		an_vector = an_elems[1:len(an_elems)]
		
		# insert elements to dictionary 
		if adj_hash.has_key(an_adj) == True:
			if adj_hash[an_adj].has_key(an_noun) == False:
				adj_hash[an_adj][an_noun] = an_vector
		else:
			temp_noun_hash={}
			temp_noun_hash[an_noun] = an_vector
			adj_hash[an_adj] = temp_noun_hash
	
	print "Total num of adjectives:", len(adj_hash)
	print "== Training data loading okay! ==\n"
		
	return (noun_hash, adj_hash)


def train(noun_hash, adj_hash, dim, num_cv = 10):
	
        adjMatrixs = {}      
        candParaList = [0, 0.01, 0.03, 0.1, 0.3, 0.6, 0.9, 1, 1.5, 3, 8, 10, 15, 20]

        # Dimenstion set up
        lowBound = dim

        cv_parameters = []
        cv_fold = num_cv

        residal_total = 0

        start = clock()

	for (key, value) in adj_hash.items():
		print ">> ", key, " :: Training with", len(value), "samples, ",
		X = []
		Y = []
		for noun_item in value.keys():
                    
                        if noun_item not in noun_hash:
                            #print '\nerr:',noun_item,'not found in noun_hash!\n',
                            continue

			X.append(noun_hash[noun_item])
			Y.append(adj_hash[key][noun_item])

		arrayX = np.array(X, np.dtype(float))
		arrayY = np.array(Y, np.dtype(float))

                # TRUCTED
		arrayX = arrayX[:,:lowBound]
		arrayY = arrayY[:,:lowBound]

                # Do row normalization
                arrayX = learn.len_norm(arrayX)
                arrayY = learn.len_norm(arrayY)
                
                # add the constant vector 
                one_vect = np.array( [1.]*arrayX.shape[0] , np.dtype(float))
                one_vect = np.reshape(one_vect,(-1,1))
                arrayX = np.hstack((arrayX, one_vect))

                #avoid over CV when the samples are small
                idx = len(candParaList)

                sum_reside = np.zeros(idx)
                    
                # generate the data idx for CV 
                gcv = 1.0e50
                para = 0
                BB = np.zeros((arrayX.shape[1],arrayX.shape[1]))
                for j in range(idx):
                    B, S = learn.linReg(arrayX, arrayY, candParaList[j])                    
                    gcv_t = arrayX.shape[0]*np.linalg.norm( np.dot(arrayX, B) - arrayY )**2/(np.trace(np.eye(arrayX.shape[0])-S))**2
                    if gcv_t < gcv:
                        gcv = gcv_t
                        para = candParaList[j]
                        BB = B

                cv_parameters.append(para)
                
                adjMatrixs[key] = BB
		
		print "Parameter =",para,"...",
                print "Done!"
    
        finish = clock()

        print "\n====Total Training time is: ", (finish-start)

        #test the results
        return adjMatrixs

def loadVectors(VecFile):
    
    ahash = {}
	
    noun_file = open(VecFile, 'r')
    n_samples = noun_file.readlines()
    for n_sample in n_samples:
	n_sample = n_sample.strip()
	n_elems = n_sample.split()
	n_word = n_elems[0]
	n_vector = n_elems[1:len(n_elems)]
        ahash[n_word] = n_vector

    return ahash



if __name__ == "__main__":
	
        if len(sys.argv)!= 5:
            print "python "+sys.argv[0]+" [dims] [noun-vectors-file] [an-training-vectors-file] [outDir]"
            sys.exit()
        
        dim = int(sys.argv[1])
        print "Num of independent dimensions:",dim
        noun_vec_file = sys.argv[2]
	print "[input] Noun vectors:",noun_vec_file
	an_vec_file = sys.argv[3]
	print "[input] AN training vectors:",an_vec_file
	outDir = sys.argv[4]

	(noun_hash, adj_hash) = loadTrainData(noun_vec_file, an_vec_file)
	adjMatrixs = train(noun_hash, adj_hash, dim)

	# print
 	for adj in adjMatrixs.keys():
	    np.savetxt(outDir+'/'+adj+'/alm-training/'+str(dim)+'.rr-gcv.betas', adjMatrixs[adj], fmt="%12.6G")   
	
