#$ -S /bin/bash
#$ -j y

. /etc/profile
. $HOME/.bash_profile
LC_ALL=C

## USAGE(): sh generate-an-vectors.sh [test-an-file] [output-directory] [data-directory] [model] [semantic-space] [norm] [param]
# 
# * $1: test-an-file (full path)
#	- Format: one AN per line in format "adj-j_noun-n"
#
# * $2: output-directory (full path)
#
# * $3: data-directory (full path)
#	- where Semantic Spaces and AN Datasets are stored
#
# * $4: model
#	- options: add | mult | dl | lm | alm
#
# * $5: semantic-space
#	- add, mult, dl: reduced | full
#	- lm, alm: reduced
#
# * $6: norm
#	- add, mult, dl: normalized | nonnormalized
#	- lm, alm: nonnormalized
#
# * $7: param
#	- add: weight{none, 4a6n, 3a7n, 6a4n, 7a3n}
#	- mult: {none}
#	- dl: lambda{2.2, 4, 6, 8, 10, 12, 14, 16.7, 18, 20}, direction{an, na}
#	- lm: latent_dims{300, 200, 100, 50, 40, 30, 20, 10}
#	- alm: latent_dims{50, 40, 30, 20, 10}
#

if [ ! -n "$7" ]; then
    echo "Error: Invalid number of arguments"
    echo "Usage():"; echo "`basename $0` [test-an-file] [output-directory] [data-directory] [model] [semantic-space] [norm] [param]"
    exit 65
    fi

echo "[begin] `basename $0`"

### GLOBAL PARAMETERS ###
DEBUG=1        	# DEBUG=1: do NOT delete tmp files, print verbose output
		# DEBUG=0: delete tmp files, no error messages will be printed
if [ $DEBUG -eq 1 ]; then echo ""; echo "[begin] $0"; fi

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


if [ "$model" == "add" -o "$model" == "mult" ]; then
    if [ "$7" == "none" ]; then		#   weight="": NO weighted addition or multiplication 
	weight=""			#   weight="-XaYn": use weighted addition or multiplication where
	pweight=""			#		    AN = 0.X*a + 0.Y*n  || AN = 0.X*a * 0.Y*n
    else				#   possible weights={"none", "-4a6n", "-3a7n", "-6a4n", "-7a3n"}
	weight="-$7"			
	pweight="-p $7"
    fi
elif [ "$model" == "dl" -a -n "$7" ]; then
    weight="$7"
elif [ "$model" == "lm" -a -n "$7" ]; then	# Number of training items for the Emi-Style Linear Model
    lmParam="$7"				#   lmParam={100, 200, 300}
elif [ "$model" == "alm" -a -n "$7" ]; then	# Number of training items for the Adj-Specific Linear Model
    almParam="$7"				#   almParam={10, 20, 30, 40, 50}
fi

#----------------------------------------------------------

## Set paths for external scripts used throughout pipeline
## (easier to change one path, and easier on the eye when reading through pipeline)
filter_by_field="../../task-independent/filter_by_field.pl"
simple_filter="../../task-independent/simple.filter.py"
combine_vectors="../../task-independent/combine_vectors.py"
align_firstel_specific_ivs_dvs="align_firstel_specific_ivs_dvs.pl"
adj_augmented_align_firstel_specific_ivs_dvs="adj_augmented_align_firstel_specific_ivs_dvs.pl"
plsr_adjnoun_dimension_prediction="../../dim-prediction/plsr_adjnoun_dimension_prediction.R"
lm_vector_analysis="../../dim-prediction/lm_vector_analysis.R"
alm_vector_analysis="../../dim-prediction/alm_vector_analysis.R"

#----------------------------------------------------------

## If Debug: Print summary of parameters
if [ $DEBUG -eq 1 ]; then 
	echo "Generate AN Vectors"; echo ""
	if [ "$model" == "adj-only" ]; then echo "[ADJ-ONLY] $space"; fi
	if [ "$model" == "ns-only" ]; then echo "[NOUN-ONLY] $space"; fi
	if [ "$model" == "add" ]; then echo "[ADD] $space$norm$weight"; fi
	if [ "$model" == "mult" ]; then echo "[MULT] $space$norm$weight"; fi
	if [ "$model" == "dl" ]; then echo "[DL] $space$norm-$weight"; fi
	if [ "$model" == "lm" ]; then echo "[LM] $space-$lmParam"; fi
	if [ "$model" == "alm" ]; then echo "[ALM] $space-$almParam"; fi
	fi

#----------------------------------------------------------

## Get betas file for emi-style LM if this model is going to be used
if [ "$model" == "lm" -a "$space" = "reduced" ]; then
	if [ $DEBUG -eq 1 ]; then echo ""; echo "Getting betas matrix for emi-style LM model"; fi
	if [ ! -d $outDir/emi-lm-training ]; then mkdir $outDir/emi-lm-training; fi
	if [ ! -s $outDir/emi-lm-training/lm.ans ]; then 
	    gawk '$1~/-j_/' $outDir/training.matrix.$space | cut -f1 | gawk 'BEGIN{srand()}{print rand() "\t" $0}' | sort | head -2500 | gawk '{print $2}' | sort > $outDir/emi-lm-training/lm.ans
	    perl $adj_augmented_align_firstel_specific_ivs_dvs $outDir/emi-lm-training/lm.ans $outDir/training.matrix.$space | sort -T . > $outDir/emi-lm-training/lm.ans-ivs-dvs.txt
	    fi
	R --slave --args $outDir/emi-lm-training/lm.ans-ivs-dvs.txt $outDir/emi-lm-training/emi.model_$lmParam 600 $lmParam < $plsr_adjnoun_dimension_prediction > $outDir/emi-lm-training/$lmParam.out 2> $outDir/emi-lm-training/$lmParam.err
	## Check that the betas file was created. If not, script dies.
	## Error likely caused by pls package memory problems (try again or try with less ANs (fewer or with less bytes))
	if [ ! -s $outDir/emi-lm-training/emi.model_$lmParam.betas ]; then 
		if [ $DEBUG -eq 1 ]; then echo ""; echo "ERROR: Unable to get betas file for the LM!"; echo "       Check error messages: $outDir/emi-lm-training/$lmParam.err"; echo ""; fi
		exit 1
		fi
	fi

#----------------------------------------------------------

for ADJ in `cat $outDir/test-adjs`; do

  ## Make sure file-prep-an-vectors.sh was run
  if [ ! -d $outDir/$ADJ ]; then echo "Error: Path not found: $outDir/$ADJ/"; echo ">>\"file-prep-an-vectors.sh\" was not executed!"; exit 1; fi

  #--------------------------------------------------------

  ## Adj-Only Model: 
  if [ "$model" == "adj-only" ]; then
	if [ $DEBUG -eq 1 ]; then echo "Processing \"$ADJ\": $model-$space"; fi
	> $outDir/$ADJ/models/adj-only_an-$space.mat
	for noun in `cat $outDir/$ADJ/tmp/target.ns`; do
	    awk -v noun=$noun '{printf $1"_"noun"\t"; for(i=2;i<=NF-1;i++) printf "%s\t",$i; print $NF}' $outDir/$ADJ/tmp/adj_vector.$space >> $outDir/$ADJ/models/adj-only_an-$space.mat
	done
  fi

  #--------------------------------------------------------

  ## Noun-Only Model: 
  if [ "$model" == "ns-only" ]; then
	if [ $DEBUG -eq 1 ]; then echo "Processing \"$ADJ\": $model-$space"; fi
	> $outDir/$ADJ/models/ns-only_an-$space.mat
	awk -v ADJ=$ADJ '{print ADJ "_" $i}' $outDir/$ADJ/tmp/target.ns-in-$space-space.mat >> $outDir/$ADJ/models/ns-only_an-$space.mat
  fi

  #--------------------------------------------------------

  ## Additive Model: 
  if [ "$model" == "add" ]; then
	if [ $DEBUG -eq 1 ]; then echo "Processing \"$ADJ\": $model-$space$norm$weight"; fi
	python $combine_vectors -u$outDir/$ADJ/tmp/adj_vector.$space -v$outDir/$ADJ/tmp/target.ns-in-$space-space.mat $pweight $norm | awk '{printf $1"_"$2"\t"; for(i=3;i<=NF-1;i++) printf "%s\t",$i; print $NF}' - > $outDir/$ADJ/models/add_an-$space$norm$weight.mat
  fi

  #--------------------------------------------------------

  ## Multiplicative Model: 
  if [ "$model" == "mult" ]; then
	if [ $DEBUG -eq 1 ]; then echo "Processing \"$ADJ\": $model-$space$norm$weight"; fi
	python $combine_vectors -m -u$outDir/$ADJ/tmp/adj_vector.$space -v$outDir/$ADJ/tmp/target.ns-in-$space-space.mat $pweight $norm | awk '{printf $1"_"$2"\t"; for(i=3;i<=NF-1;i++) printf "%s\t",$i; print $NF}' - > $outDir/$ADJ/models/mult_an-$space$norm$weight.mat
  fi

  #--------------------------------------------------------

  ## Dilation Model: 
  if [ "$model" == "dl" ]; then
	if [ $DEBUG -eq 1 ]; then echo "Processing \"$ADJ\": $model-$space$norm-$weight"; fi
	#python $combine_vectors -d -u$outDir/$ADJ/tmp/adj_vector.$space -v$outDir/$ADJ/tmp/target.ns-in-$space-space.mat -l$weight $norm | awk '{printf $1"_"$2"\t"; for(i=3;i<=NF-1;i++) printf "%s\t",$i; print $NF}' - > $outDir/$ADJ/models/dl_an-$space$norm-$weight-an.mat
	python $combine_vectors -d -u$outDir/$ADJ/tmp/target.ns-in-$space-space.mat -v$outDir/$ADJ/tmp/adj_vector.$space -l$weight $norm | awk '{printf $2"_"$1"\t"; for(i=3;i<=NF-1;i++) printf "%s\t",$i; print $NF}' - > $outDir/$ADJ/models/dl_an-$space$norm-$weight-na.mat
  fi

  #--------------------------------------------------------

  ## Linear Model (Emi-Style):
  if [ "$model" == "lm" -a "$space" = "reduced" ]; then
	if [ $DEBUG -eq 1 ]; then echo "Processing \"$ADJ\": $model-$space-$lmParam"; fi
	R --slave --args $ADJ $outDir/emi-lm-training/emi.model_$lmParam.betas $outDir/$ADJ/tmp/adj_vector.$space $outDir/$ADJ/tmp/target.ns-in-$space-space.mat $outDir/$ADJ/models/lm_an-$space-$lmParam.mat < $lm_vector_analysis > $outDir/$ADJ/tmp/lm_vector_analysis.out 2> $outDir/$ADJ/tmp/lm_vector_analysis.err
  fi

  #--------------------------------------------------------

  ## Adjective-Specific Linear Model:
  if [ "$model" == "alm" -a "$space" = "reduced" ]; then
	if [ $DEBUG -eq 1 ]; then echo "Processing \"$ADJ\": $model-$space-$almParam"; fi
	if [ $(grep -c "^$ADJ_" $outDir/training.matrix.$space) -ge  $[ $almParam*2 ] ]; then	# condition to check for overtraining
		perl $align_firstel_specific_ivs_dvs $ADJ $outDir/training.matrix.$space > $outDir/$ADJ/tmp/$almParam.ivs-dvs.txt
		R --slave --args $outDir/$ADJ/tmp/$almParam.ivs-dvs.txt $outDir/$ADJ/tmp/$almParam.plsr.$ADJ 300 $almParam < $plsr_adjnoun_dimension_prediction > $outDir/$ADJ/tmp/$almParam.$ADJ.out 2> $outDir/$ADJ/tmp/$almParam.$ADJ.err
		R --slave --args $ADJ $outDir/$ADJ/tmp/$almParam.plsr.$ADJ.betas $outDir/$ADJ/tmp/target.ns-in-$space-space.mat $outDir/$ADJ/models/alm_an-$space-$almParam.mat < $alm_vector_analysis > $outDir/$ADJ/tmp/alm_vector_analysis.out 2> $outDir/$ADJ/tmp/alm_vector_analysis.err
	fi
  fi

  #--------------------------------------------------------

  if [ $DEBUG -eq 1 ]; then echo "    ... done"; fi
  if [ $DEBUG -eq 0 ]; then rm -r $outDir/$ADJ/tmp/; fi

done

if [ $DEBUG -eq 1 ]; then echo ""; echo "[end] `basename $0`"; fi


