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
#	- dl: lambda {2.2,4,6,8,10,12,14,16.7,18,20} - direction {an, na}
#	- lm: {300, 200, 100, 50, 40, 30, 20, 10}
#	- alm: {50, 40, 30, 20, 10}
#

if [ ! -n "$7" ]; then
    echo "Error: Invalid number of arguments"
    echo "Usage():"; echo "`basename $0` [test-an-file] [output-directory] [data-directory] [model] [semantic-space] [norm] [param]"
    exit 65
    fi

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
if [ "$6" == "normalized" ]; then norm="-n"; fi	
		#   norm="": the models use the raw A and N vectors from the Semantic Space
		#   norm="-n": the models use NORMALIZED A and N vectors


if [ "$model" == "add" -o "$model" == "mult" -o "$model" == "dl" ]; then
    if [ "$7" == "none" ]; then		#   weight="": NO weighted addition or multiplication 
	weight=""			#   weight="-XaYn": use weighted addition or multiplication where
    else				#		    AN = 0.X*a + 0.Y*n  || AN = 0.X*a * 0.Y*n
	weight="-$7"			#   possible weights={"none", "-4a6n", "-3a7n", "-6a4n", "-7a3n"}
    fi
elif [ "$model" == "lm" -a -n "$7" ]; then	# Number of training items for the Emi-Style Linear Model
    lmParam="$7"				#   lmParam={100, 200, 300}
elif [ "$model" == "alm" -a -n "$7" ]; then	# Number of training items for the Adj-Specific Linear Model
    almParam="$7"				#   almParam={10, 20, 30, 40, 50}
fi

if [ "$space" == "full" ]; then		# Get dimensions argument to pass to compute_cosines script
    dspace="-d 10000"
elif [ "$space" == "reduced" ]; then
    dspace="-d 300"
fi

#----------------------------------------------------------

## Set paths for external scripts used throughout pipeline
## (easier to change one path, and easier on the eye when reading through pipeline)
filter_by_field="../../task-independent/filter_by_field.pl"
compute_cosines="../../task-independent/compute_cosines_of_vectors.py"
find_rank_of_observed_equivalent="../../task-independent/find_rank_of_observed_equivalent.py"

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

# get the count of Semantic Space rows
declare -i rowCount=`wc -l $dataDir/all.rows | cut -f1 -d' '`

#----------------------------------------------------------

for ADJ in `cat $outDir/test-adjs`; do

  ## Initiate necessary directories
  if [ ! -d $outDir/$ADJ/eval ]; then mkdir $outDir/$ADJ/eval; fi
  if [ ! -d $outDir/$ADJ/tmp/ ]; then mkdir $outDir/$ADJ/tmp; fi

  #--------------------------------------------------------

  ## Adj-Only Model: 
  if [ "$model" == "adj" ]; then
      if [ $DEBUG -eq 1 ]; then echo "Evaluating \"$ADJ\": $model-$space"; fi
      python $compute_cosines -t $outDir/$ADJ/models/adj-only_an-$space.mat -s $dataDir/$space.matrix $dspace -p > $outDir/$ADJ/tmp/adj-only-$space.cosines
      python $find_rank_of_observed_equivalent -i$outDir/$ADJ/tmp/adj-only-$space.cosines -o$outDir/$ADJ/eval/adj-$space -r$rowCount -t
      if [ $DEBUG -eq 1 ]; then echo "    ... done"; fi
  fi

  #--------------------------------------------------------

  ## Noun-Only Model: 
  if [ "$model" == "ns" ]; then
      if [ $DEBUG -eq 1 ]; then echo "Evaluating \"$ADJ\": $model-$space"; fi
      python $compute_cosines -t $outDir/$ADJ/models/ns-only_an-$space.mat -s $dataDir/$space.matrix $dspace -p > $outDir/$ADJ/tmp/ns-only-$space.cosines
      python $find_rank_of_observed_equivalent -i$outDir/$ADJ/tmp/ns-only-$space.cosines -o$outDir/$ADJ/eval/ns-$space -r$rowCount -t
      if [ $DEBUG -eq 1 ]; then echo "    ... done"; fi
  fi

  #--------------------------------------------------------

  ## Additive Model: 
  if [ "$model" == "add" ] && [ -s $outDir/$ADJ/models/add_an-$space$norm$weight.mat ] && [ ! -s $outDir/$ADJ/eval/add-$space$norm$weight.top-ten-neighbors ]; then
      if [ $DEBUG -eq 1 ]; then echo "Evaluating \"$ADJ\": $model-$space$norm$weight"; fi
      python $compute_cosines -t $outDir/$ADJ/models/add_an-$space$norm$weight.mat -s $dataDir/$space.matrix $dspace -p > $outDir/$ADJ/tmp/add-$space.cosines
      python $find_rank_of_observed_equivalent -i$outDir/$ADJ/tmp/add-$space.cosines -o$outDir/$ADJ/eval/add-$space$norm$weight -r$rowCount -t
      if [ $DEBUG -eq 1 ]; then echo "    ... done"; fi
  fi

  #--------------------------------------------------------

  ## Multiplicative Model: 
  if [ "$model" == "mult" ] && [ -e $outDir/$ADJ/models/mult_an-$space$norm$weight.mat ] && [ ! -s $outDir/$ADJ/eval/mult-$space$norm$weight.top-ten-neighbors ]; then
      if [ $DEBUG -eq 1 ]; then echo "Evaluating \"$ADJ\": $model-$space$norm$weight"; fi
      python $compute_cosines -t $outDir/$ADJ/models/mult_an-$space$norm$weight.mat -s $dataDir/$space.matrix $dspace -p > $outDir/$ADJ/tmp/mult-$space.cosines
      python $find_rank_of_observed_equivalent -i$outDir/$ADJ/tmp/mult-$space.cosines -o$outDir/$ADJ/eval/mult-$space$norm$weight -r$rowCount -t
      if [ $DEBUG -eq 1 ]; then echo "    ... done"; fi
  fi

  #--------------------------------------------------------

  ## Dilation Model: 
  if [ "$model" == "dl" ] && [ -e $outDir/$ADJ/models/dl_an-$space$norm$weight-an.mat ] && [ ! -s $outDir/$ADJ/eval/dl-$space$norm$weight-an.top-ten-neighbors ]; then
      if [ $DEBUG -eq 1 ]; then echo "Evaluating \"$ADJ\": $model-$space$norm$weight"; fi
      for direction in an na; do
          python $compute_cosines -t $outDir/$ADJ/models/dl_an-$space$norm$weight-$direction.mat -s $dataDir/$space.matrix $dspace -p > $outDir/$ADJ/tmp/dl-$space.cosines
          python $find_rank_of_observed_equivalent -i$outDir/$ADJ/tmp/dl-$space.cosines -o$outDir/$ADJ/eval/dl-$space$norm$weight-$direction -r$rowCount -t
      done
      if [ $DEBUG -eq 1 ]; then echo "    ... done"; fi
  fi

  #--------------------------------------------------------

  ## Linear Model (Emi-Style):
  if [ "$space" = "reduced" -a "$model" == "lm" -a -e $outDir/$ADJ/models/lm_an-$space-$lmParam.mat ] && [ ! -s $outDir/$ADJ/eval/lm-$space-$lmParam.top-ten-neighbors ]; then
      if [ $DEBUG -eq 1 ]; then echo "Evaluating \"$ADJ\": $model-$space-$lmParam"; fi
      python $compute_cosines -t $outDir/$ADJ/models/lm_an-$space-$lmParam.mat -s $dataDir/$space.matrix $dspace > $outDir/$ADJ/tmp/lm-$space.cosines
      python $find_rank_of_observed_equivalent -i$outDir/$ADJ/tmp/lm-$space.cosines -o$outDir/$ADJ/eval/lm-$space-$lmParam -r$rowCount -t
      if [ $DEBUG -eq 1 ]; then echo "    ... done"; fi
  fi

  #--------------------------------------------------------

  ## Adjective-Specific Linear Model:
  if [ "$space" = "reduced" -a "$model" == "alm" -a -e $outDir/$ADJ/models/alm_an-$space-$almParam.mat ] && [ ! -s $outDir/$ADJ/eval/alm-$space-$almParam.top-ten-neighbors ]; then
      if [ $DEBUG -eq 1 ]; then echo "Evaluating \"$ADJ\": $model-$space-$almParam"; fi
      python $compute_cosines -t $outDir/$ADJ/models/alm_an-$space-$almParam.mat -s $dataDir/$space.matrix $dspace > $outDir/$ADJ/tmp/alm-$space.cosines
      python $find_rank_of_observed_equivalent -i$outDir/$ADJ/tmp/alm-$space.cosines -o$outDir/$ADJ/eval/alm-$space-$almParam -r$rowCount -t
      if [ $DEBUG -eq 1 ]; then echo "    ... done"; fi
  fi

  #--------------------------------------------------------

  if [ $DEBUG -eq 0 ]; then rm $outDir/$ADJ/tmp/; fi

done

if [ $DEBUG -eq 1 ]; then echo ""; echo "[end]"; fi


