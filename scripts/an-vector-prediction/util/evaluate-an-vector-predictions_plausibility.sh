#$ -S /bin/bash
#$ -j y

. /etc/profile
. $HOME/.bash_profile
LC_ALL=C

## USAGE(): sh evaluate-an-vector-predictions.sh [test-an-file] [output-directory] [data-directory] [model] [semantic-space] [norm] [param]
# 
# * $1: test-an-file (full path)
#	- Format: one AN per line in format "adj-j_noun-n"
#
# * $2: output-directory (full path)
#	- NOTE:: Same directory as used for generate-an-vectors.sh
#
# * $3: data-directory (full path)
#	- where Semantic Spaces are stored
#
# * $4: model
#	- options: adj | ns | add | mult | dl | lm | alm
#
# * $5: semantic-space
#	- options: reduced | full
#
# * $6: norm
#	- options: normalized | nonnormalized
#
# * $7: param
#	- add,mult: {4a6n, 3a7n, 6a4n, 7a3n}
#	- dl: {16.7, 2.2, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20}
#	- lm: {300, 200, 100}
#	- alm: {50, 40, 30, 20, 10}
#

if [ ! -n "$7" ]; then
    echo "Error: Invalid number of arguments"
    echo "Usage():"; echo "`basename $0` [test-an-file] [output-directory] [data-directory] [model] [semantic-space] [norm] [param]"
    exit 65
    fi

echo "[begin] `basename $0`"; echo

### GLOBAL PARAMETERS ###
DEBUG=1        	# DEBUG=1: do NOT delete tmp files, print verbose output
		# DEBUG=0: delete tmp files, no error messages will be printed

# Specify full path of the output directory (remove final "/")
lchr=`expr substr $2 ${#2} 1`; if [ "$lchr" = "/" ]; then outDir="${2%?}"; else outDir="$2"; fi

# Specify full path where the full/reduced Semantic Spaces are stored (remove final "/")
lchr=`expr substr $3 ${#3} 1`; if [ "$lchr" = "/" ]; then dataDir="${3%?}"; else dataDir="$3"; fi

model="$4"	# This parameter specifies which compositionality model to use

space="$5"	# This parameter specifies which Semantic Space to use
		#   space="reduced": models use the SVD-reduced space (300 dimensions)
		#   space="full": models use the non-reduced space (10K dimensions)
		# **Note: the linear models are *not* executed on the full space (memory reasons)


norm=""		# This parameter is specifically for the Addition and Multiplication models
nnorm=""
if [ "$6" == "normalized" ]; then norm="-n"; fi	
		#   norm="": the models use the raw A and N vectors from the Semantic Space
		#   norm="-n": the models use NORMALIZED A and N vectors


if [ "$model" == "add" -o "$model" == "mult" -o "$model" == "dl" ]; then
    if [ "$7" == "none" ]; then		#   weight="": NO weighted addition or multiplication 
	weight=""			#   weight="-XaYn": use weighted addition or multiplication where
    else				#		    AN = 0.X*a + 0.Y*n  || AN = 0.X*a * 0.Y*n
	weight="-$7"			#   possible weights={"none", "-4a6n", "-3a7n", "-6a4n", "-7a3n"}
    fi
    if [ "$norm" == "" -a "$weight" == "" ]; then
	nnorm="_"
    fi
elif [ "$model" == "lm" -a -n "$7" ]; then	# Number of training items for the Emi-Style Linear Model
    lmParam="$7"				#   lmParam={100, 200, 300}
elif [ "$model" == "alm" -a -n "$7" ]; then	# Number of training items for the Adj-Specific Linear Model
    almParam="$7"				#   almParam={10, 20, 30, 40, 50}
fi

#----------------------------------------------------------

## Set paths for external scripts used throughout pipeline
## (easier to change one path, and easier on the eye when reading through pipeline)
filter_by_field="../../task-independent/filter_by_field.pl"
run_vector_evaluation_fast="../../task-independent/run_vector_evaluation_fast.py"
average_nn_similarity="util/average_nn_similarity.pl"

#----------------------------------------------------------

## If Debug: Print summary of parameters
if [ $DEBUG -eq 1 ]; then 
	echo "Evaluate Predicted AN Vectors"; echo ""
	if [ "$model" == "adj" ]; then echo "[ADJ] $space"; fi
	if [ "$model" == "ns" ]; then echo "[NOUN] $space"; fi
	if [ "$model" == "add" ]; then echo "[ADD] $space$norm$weight"; fi
	if [ "$model" == "mult" ]; then echo "[MULT] $space$norm$weight"; fi
	if [ "$model" == "dl" ]; then echo "[DL] $space$norm$weight"; fi
	if [ "$model" == "lm" ]; then echo "[LM] $space-$lmParam"; fi
	if [ "$model" == "alm" ]; then echo "[ALM] $space-$almParam"; fi
	fi

#----------------------------------------------------------

# ** PRELIMINARIES **

# Check for file with set of unique adjs in the test-ans file
# **Sanity check: no adjs are to be used that were not used in "generate-an-vectors.sh"
if [ ! -s $outDir/test-adjs ]; then echo ""; echo "ERROR: $outDir/test-adjs: file not found!"; echo "     > file was created by \"generate-an-vectors.sh\""; echo "" exit 1; fi

if [ ! -d $outDir/eval ]; then mkdir $outDir/eval; fi

#----------------------------------------------------------

if [ "$model" == "adj" -o "$model" == "ns" ]; then
  python $run_vector_evaluation_fast -o$outDir -m$model-only -s$space -u
  perl $average_nn_similarity $outDir/eval/$model-only-$space.top-ten-neighbors.txt $dataDir/$space.matrix > $outDir/eval/$model-only-$space.average-nn-similarity.txt
  for ADJ in `cat $outDir/test-adjs`; do
	if [ ! -d $outDir/$ADJ/eval ]; then mkdir $outDir/$ADJ/eval; fi
	egrep "^$ADJ\_" $outDir/eval/$model-only-$space.vector_length.txt | sort -T . > $outDir/$ADJ/eval/$model-$space.vector_length
	egrep "^$ADJ\_" $outDir/eval/$model-only-$space.distance_from_component_n.txt | sort -T . > $outDir/$ADJ/eval/$model-$space.distance_from_component_n
	egrep "^$ADJ\_" $outDir/eval/$model-only-$space.nearest_neighbor.txt | sort -T . > $outDir/$ADJ/eval/$model-$space.nearest_neighbor
	egrep "^$ADJ\_" $outDir/eval/$model-only-$space.average_of_nearest_neighbors.txt | sort -T . > $outDir/$ADJ/eval/$model-$space.average_of_nearest_neighbors
	egrep "^$ADJ\_" $outDir/eval/$model-only-$space.top-ten-neighbors.txt | sort -T . > $outDir/$ADJ/eval/$model-$space.top-ten-neighbors
	egrep "^$ADJ\_" $outDir/eval/$model-only-$space.average-nn-similarity.txt | sort -T . > $outDir/$ADJ/eval/$model-$space.average-nn-similarity
  done
fi

if [ "$model" == "add" ]; then
  python $run_vector_evaluation_fast -o$outDir -m$model -s$space -p$nnorm$norm$weight -u
  perl $average_nn_similarity $outDir/eval/$model-$space$norm$weight.top-ten-neighbors.txt $dataDir/$space.matrix > $outDir/eval/$model-$space$norm$weight.average-nn-similarity.txt
  for ADJ in `cat $outDir/test-adjs`; do
	if [ ! -d $outDir/$ADJ/eval ]; then mkdir $outDir/$ADJ/eval; fi
	egrep "^$ADJ\_" $outDir/eval/$model-$space$norm$weight.vector_length.txt | sort -T . > $outDir/$ADJ/eval/$model-$space$norm$weight.vector_length
	egrep "^$ADJ\_" $outDir/eval/$model-$space$norm$weight.distance_from_component_n.txt | sort -T . > $outDir/$ADJ/eval/$model-$space$norm$weight.distance_from_component_n
	egrep "^$ADJ\_" $outDir/eval/$model-$space$norm$weight.nearest_neighbor.txt | sort -T . > $outDir/$ADJ/eval/$model-$space$norm$weight.nearest_neighbor
	egrep "^$ADJ\_" $outDir/eval/$model-$space$norm$weight.average_of_nearest_neighbors.txt | sort -T . > $outDir/$ADJ/eval/$model-$space$norm$weight.average_of_nearest_neighbors
	egrep "^$ADJ\_" $outDir/eval/$model-$space$norm$weight.top-ten-neighbors.txt | sort -T . > $outDir/$ADJ/eval/$model-$space$norm$weight.top-ten-neighbors
	egrep "^$ADJ\_" $outDir/eval/$model-$space$norm$weight.average-nn-similarity.txt | sort -T . > $outDir/$ADJ/eval/$model-$space$norm$weight.average-nn-similarity
  done
fi

if [ "$model" == "mult" ]; then
  python $run_vector_evaluation_fast -o$outDir -m$model -s$space -p$nnorm$norm -u
  perl $average_nn_similarity $outDir/eval/$model-$space$norm.top-ten-neighbors.txt $dataDir/$space.matrix > $outDir/eval/$model-$space$norm.average-nn-similarity.txt
  for ADJ in `cat $outDir/test-adjs`; do
	if [ ! -d $outDir/$ADJ/eval ]; then mkdir $outDir/$ADJ/eval; fi
	egrep "^$ADJ\_" $outDir/eval/$model-$space$norm.vector_length.txt | sort -T . > $outDir/$ADJ/eval/$model-$space$norm.vector_length
	egrep "^$ADJ\_" $outDir/eval/$model-$space$norm.distance_from_component_n.txt | sort -T . > $outDir/$ADJ/eval/$model-$space$norm.distance_from_component_n
	egrep "^$ADJ\_" $outDir/eval/$model-$space$norm.nearest_neighbor.txt | sort -T . > $outDir/$ADJ/eval/$model-$space$norm.nearest_neighbor
	egrep "^$ADJ\_" $outDir/eval/$model-$space$norm.average_of_nearest_neighbors.txt | sort -T . > $outDir/$ADJ/eval/$model-$space$norm.average_of_nearest_neighbors
	egrep "^$ADJ\_" $outDir/eval/$model-$space$norm.top-ten-neighbors.txt | sort -T . > $outDir/$ADJ/eval/$model-$space$norm.top-ten-neighbors
	egrep "^$ADJ\_" $outDir/eval/$model-$space$norm.average-nn-similarity.txt | sort -T . > $outDir/$ADJ/eval/$model-$space$norm.average-nn-similarity
  done
fi

if [ "$model" == "dl" ]; then
  python $run_vector_evaluation_fast -o$outDir -m$model -s$space -p$norm$weight-na -u
  perl $average_nn_similarity $outDir/eval/$model-$space$norm$weight-na.top-ten-neighbors.txt $dataDir/$space.matrix > $outDir/eval/$model-$space$norm$weight-na.average-nn-similarity.txt
  for ADJ in `cat $outDir/test-adjs`; do
	if [ ! -d $outDir/$ADJ/eval ]; then mkdir $outDir/$ADJ/eval; fi
	egrep "^$ADJ\_" $outDir/eval/$model-$space$norm$weight-na.vector_length.txt | sort -T . > $outDir/$ADJ/eval/$model-$space$norm$weight-na.vector_length
	egrep "^$ADJ\_" $outDir/eval/$model-$space$norm$weight-na.distance_from_component_n.txt | sort -T . > $outDir/$ADJ/eval/$model-$space$norm$weight-na.distance_from_component_n
	egrep "^$ADJ\_" $outDir/eval/$model-$space$norm$weight-na.nearest_neighbor.txt | sort -T . > $outDir/$ADJ/eval/$model-$space$norm$weight-na.nearest_neighbor
	egrep "^$ADJ\_" $outDir/eval/$model-$space$norm$weight-na.average_of_nearest_neighbors.txt | sort -T . > $outDir/$ADJ/eval/$model-$space$norm$weight-na.average_of_nearest_neighbors
	egrep "^$ADJ\_" $outDir/eval/$model-$space$norm$weight-na.top-ten-neighbors.txt | sort -T . > $outDir/$ADJ/eval/$model-$space$norm$weight-na.top-ten-neighbors
	egrep "^$ADJ\_" $outDir/eval/$model-$space$norm$weight-na.average-nn-similarity.txt | sort -T . > $outDir/$ADJ/eval/$model-$space$norm$weight-na.average-nn-similarity
  done
fi

if [ "$model" == "lm" -a "$space" = "reduced" ]; then
  python $run_vector_evaluation_fast -o$outDir -m$model -s$space -p-$lmParam -u
  perl $average_nn_similarity $outDir/eval/$model-$space-$lmParam.top-ten-neighbors.txt $dataDir/$space.matrix > $outDir/eval/$model-$space-$lmParam.average-nn-similarity.txt
  for ADJ in `cat $outDir/test-adjs`; do
	if [ ! -d $outDir/$ADJ/eval ]; then mkdir $outDir/$ADJ/eval; fi
	egrep "^$ADJ\_" $outDir/eval/$model-$space-$lmParam.vector_length.txt | sort -T . > $outDir/$ADJ/eval/$model-$space-$lmParam.vector_length
	egrep "^$ADJ\_" $outDir/eval/$model-$space-$lmParam.distance_from_component_n.txt | sort -T . > $outDir/$ADJ/eval/$model-$space-$lmParam.distance_from_component_n
	egrep "^$ADJ\_" $outDir/eval/$model-$space-$lmParam.nearest_neighbor.txt | sort -T . > $outDir/$ADJ/eval/$model-$space-$lmParam.nearest_neighbor
	egrep "^$ADJ\_" $outDir/eval/$model-$space-$lmParam.average_of_nearest_neighbors.txt | sort -T . > $outDir/$ADJ/eval/$model-$space-$lmParam.average_of_nearest_neighbors
	egrep "^$ADJ\_" $outDir/eval/$model-$space-$lmParam.top-ten-neighbors.txt | sort -T . > $outDir/$ADJ/eval/$model-$space-$lmParam.top-ten-neighbors
	egrep "^$ADJ\_" $outDir/eval/$model-$space-$lmParam.average-nn-similarity.txt | sort -T . > $outDir/$ADJ/eval/$model-$space-$lmParam.average-nn-similarity
  done
fi

if [ "$model" == "alm" -a "$space" = "reduced" ]; then
  python $run_vector_evaluation_fast -o$outDir -m$model -s$space -p-$almParam -u
  perl $average_nn_similarity $outDir/eval/$model-$space-$almParam.top-ten-neighbors.txt $dataDir/$space.matrix > $outDir/eval/$model-$space-$almParam.average-nn-similarity.txt
  for ADJ in `cat $outDir/test-adjs`; do
	if [ ! -d $outDir/$ADJ/eval ]; then mkdir $outDir/$ADJ/eval; fi
	egrep "^$ADJ\_" $outDir/eval/$model-$space-$almParam.vector_length.txt | sort -T . > $outDir/$ADJ/eval/$model-$space-$almParam.vector_length
	egrep "^$ADJ\_" $outDir/eval/$model-$space-$almParam.distance_from_component_n.txt | sort -T . > $outDir/$ADJ/eval/$model-$space-$almParam.distance_from_component_n
	egrep "^$ADJ\_" $outDir/eval/$model-$space-$almParam.nearest_neighbor.txt | sort -T . > $outDir/$ADJ/eval/$model-$space-$almParam.nearest_neighbor
	egrep "^$ADJ\_" $outDir/eval/$model-$space-$almParam.average_of_nearest_neighbors.txt | sort -T . > $outDir/$ADJ/eval/$model-$space-$almParam.average_of_nearest_neighbors
	egrep "^$ADJ\_" $outDir/eval/$model-$space-$almParam.top-ten-neighbors.txt | sort -T . > $outDir/$ADJ/eval/$model-$space-$almParam.top-ten-neighbors
	egrep "^$ADJ\_" $outDir/eval/$model-$space-$almParam.average-nn-similarity.txt | sort -T . > $outDir/$ADJ/eval/$model-$space-$almParam.average-nn-similarity
  done
fi


if [ $DEBUG -eq 1 ]; then echo ""; echo "[end] `basename $0`"; fi

