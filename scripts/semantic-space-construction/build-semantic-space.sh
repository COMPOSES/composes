#$ -wd /github/COMPOSES/commons/scripts/semantic-space-construction
#$ -S /bin/bash
#$ -j y

export LC_ALL=C
unset LANG

## USAGE(): sh build-semantic-space.sh [cooc-directory] [output-directory]
# 
# $1: cooc-directory (full path)
# $2: output-directory (full path)
#

#---------------------------------------

### GLOBAL PARAMETERS ###
getVocab=0	# if = 1: get the vocabulary (rows) for the Semantic Space
buildSemSpace=0	# if = 1: build the Semantic Space using target.rows (rows) and target.columns (columns)
svdMatrix=0	# if = 1: perform SVD reduction on the Semantic Space

coreA=4000	# The num of the most frequent Adjs and Nouns for the Core Vocabulary
coreN=8000	# ** Note, target vocab is a subset of this vocab

targetA=700	# The num of most frequent Adjs and Nouns for Target Vocabulary
targetN=4000	# ** Note, these are the Adjs and Nouns used to generate AN pairs

topFreqFilter=0	# A filter to exclude a number of the MOST frequently occurring elements in target & core vocab

anFreq=100	# Minimum frequency of ANs in the corpus

column_dims=10000

col_pos='vjnr'	# specify POS for columns
		# v:verbs, j:adjectives, n:nouns, r:adverbs

fq_val='lmi'	# which type of values to populate semantic space
		# if = 'fqs': raw frequencies
		# if = 'logfq': log(frequency)
		# if = 'lmi': local mutual information

#---------------------------------------

## * Preliminaries *

## Read command line arguments
if [ ! -n "$2" ]; then echo "Usage: `basename $0` [cooc-directory] [output-directory]"; exit 65; fi

# Check to make sure cooc.output-directory and output-directory 
# do not end in "/", if so, remove the final char
lchr=`expr substr $1 ${#1} 1`
if [ "$lchr" = "/" ]; then cooc="${1%?}"; else cooc="$1"; fi
lchr=`expr substr $2 ${#2} 1`
if [ "$lchr" = "/" ]; then d="${2%?}"; else d="$2"; fi

## Check for / create necessary directories
if [ ! -d $cooc ]; then echo ""; echo "ERROR: $cooc: directory not found!"; echo ""; exit 1; fi
if [ ! -d $d ]; then mkdir $d; fi
if [ ! -d $d/a-and-n-sets ]; then mkdir $d/a-and-n-sets; fi
if [ ! -d $d/an-sets ]; then mkdir $d/an-sets; fi

## Set paths for external scripts used throughout pipeline
## (easier to change one path, and easier on the eye when reading through pipeline)
filter_by_field="../task-independent/filter_by_field.pl"
getCartProduct="../task-independent/getCartProduct.py"
compute_LMI_from_pairs="../task-independent/compute_LMI_from_pairs.py"
compute_LogFq_from_pairs="../task-independent/compute_LogFq_from_pairs.py"
build_matrix_from_tuples="../task-independent/build_matrix_from_tuples.pl"
project_onto_v="../task-independent/project_onto_v.R"
svd_matrix_transformer="../task-independent/svd_matrix_transformer.pl"

echo "[begin] `basename $0`"

#---------------------------------------

## Print all parameter settings to readme file in the output directory
echo "Parameter Settings for Semantic Space" > $d/readme.txt; echo >> $d/readme.txt
echo "Core Vocabulary:" >> $d/readme.txt; echo "    top $coreA adjectives" >> $d/readme.txt; echo "    top $coreN nouns" >> $d/readme.txt; echo >> $d/readme.txt
echo "Target Vocabulary: adjs and ns used to construct AN pairs" >> $d/readme.txt; echo "    top $targetA adjectives" >> $d/readme.txt; echo "    top $targetN nouns" >> $d/readme.txt; echo >> $d/readme.txt
echo "AN Frequency Threshold: $anFreq" >> $d/readme.txt; echo >> $d/readme.txt
echo "Cell Weighting (frequency values): $fq_val" >> $d/readme.txt; echo >> $d/readme.txt
echo "Dimensions in non-reduced space: $column_dims" >> $d/readme.txt; echo >> $d/readme.txt
echo "Column POS: $col_pos" >> $d/readme.txt; echo >> $d/readme.txt

#---------------------------------------

if [ $getVocab -eq 1 ]; then
	echo ""
	echo "[1] Adjectives and Nouns"

	echo "    extracting Core Vocabulary..."
	zcat $cooc/elements.fqs.gz | gawk '$1~/...-j$/' | sort -nrk2 -T . | tail -n+$topFreqFilter | head -$coreA > tmp.core.adjs
	cut -f1 tmp.core.adjs | sort -T . | uniq > $d/a-and-n-sets/core.adjs
	zcat $cooc/elements.fqs.gz | gawk '$1~/...-n$/ && $1!~/-j_/' | sort -nrk2 -T . | tail -n+$topFreqFilter | head -$coreN > tmp.core.ns
	cut -f1 tmp.core.ns | sort -T . | uniq > $d/a-and-n-sets/core.ns

	echo "    extracting Target Vocabulary..."
	head -$targetA tmp.core.adjs  | cut -f1 | $filter_by_field -s util/problematic-adjs.txt - | sort -T . | uniq > $d/a-and-n-sets/target.adjs
	head -$targetN tmp.core.ns | cut -f1 | $filter_by_field -s util/problematic-ns.txt - | sort -T . | uniq > $d/a-and-n-sets/target.ns
	
	cat $d/a-and-n-sets/core.ns $d/a-and-n-sets/core.adjs util/aamp-rg.ns util/ml.adjs-and-ns | sort -T . | uniq > $d/a-and-n-sets/core.elements

	echo "    done!"

	#---------------------------------------

	echo ""
	echo "[2] AN Datasets"

	# For Test Set: 
	# - M&L2010 AN set (also get the component As and Ns) (util/ml.ans)
	# - Color ANs for proxy study (util/color.ans)
	
	echo "    generating AN pairs from the Target Vocabulary..."
	$filter_by_field -s util/problematic-adjs.txt $d/a-and-n-sets/target.adjs > tmp.target.adjs
	$filter_by_field -s util/problematic-ns.txt $d/a-and-n-sets/target.ns > tmp.target.ns
	python $getCartProduct tmp.target.adjs tmp.target.ns > tmp.Cartesian.Product
	zcat $cooc/elements.fqs.gz | $filter_by_field tmp.Cartesian.Product - | sort -T . > tmp.target.ans
	cut -f1 tmp.target.ans > $d/an-sets/attested.ans
	$filter_by_field -s $d/an-sets/attested.ans tmp.Cartesian.Product | cut -f1 | sort -T . > $d/an-sets/unattested.ans
	awk -v number=$anFreq '$2 >= number' tmp.target.ans | cut -f1 | sort -T . > $d/an-sets/filtered-attested.ans
	
	# For each target adjective, make sure we have at least 100 ANs for the training data
	# Note, not including the ml.ans and the color.ans
	> tmp.min-training.ans
	for ADJ in `cat $d/a-and-n-sets/target.adjs`; do
	    cat util/ml.ans util/color.ans | $filter_by_field -s - $d/an-sets/filtered-attested.ans | egrep "^$ADJ" | gawk 'BEGIN{srand()}{print rand() "\t" $0}' | sort -T . | head -100 | cut -f2 | sort -T . >>  tmp.min-training.ans
	done

	echo "    extracting Development AN dataset..."
	# For each target adjective, get a random 10 ANs for the devel dataset
	# Note, not including the ml.ans, color.ans or tmp.min-training.ans
	> $d/an-sets/devel.ans
	for ADJ in `cat $d/a-and-n-sets/target.adjs`; do
	    cat util/ml.ans util/color.ans tmp.min-training.ans | $filter_by_field -s - $d/an-sets/filtered-attested.ans | egrep "^$ADJ" | gawk 'BEGIN{srand()}{print rand() "\t" $0}' | sort -T . | head -10 | cut -f2 | sort -T . >> $d/an-sets/devel.ans
	done

	echo "    extracting Training, Test and Unused AN datasets..."
	declare -i a=`$filter_by_field -s $d/an-sets/devel.ans $d/an-sets/filtered-attested.ans | wc -l | cut -f1 -d' '`
	declare -i b=`wc -l tmp.min-training.ans | cut -f1 -d' '`
	echo "$a*.60-$b" | bc -l > tmp
	declare -i trainingANcount=`cat tmp | cut -f1 -d'.'`
	echo "$a*.30" | bc -l > tmp
	declare -i testANcount=`cat tmp | cut -f1 -d'.'`
	rm tmp

	cat util/ml.ans util/color.ans tmp.min-training.ans $d/an-sets/devel.ans | $filter_by_field -s - $d/an-sets/filtered-attested.ans | gawk 'BEGIN{srand()}{print rand() "\t" $0}' | sort -T . | head -$trainingANcount | cut -f2 | cat - tmp.min-training.ans | sort -T . > $d/an-sets/training.ans
	cat $d/an-sets/devel.ans $d/an-sets/training.ans | $filter_by_field -s - $d/an-sets/filtered-attested.ans | gawk 'BEGIN{srand()}{print rand() "\t" $0}' | sort -T . | head -$testANcount | cut -f2 | cat - util/ml.ans util/color.ans | sort -T . | uniq > $d/an-sets/test.ans

	# Finalize the set of semantic space ANs
	cat $d/an-sets/test.ans $d/an-sets/training.ans $d/an-sets/devel.ans util/ml.ans util/color.ans | sort -T . | uniq > $d/an-sets/sem-space.ans
	# Keep aside a set of unused ANs for plausibility experiments
	$filter_by_field -s $d/an-sets/sem-space.ans $d/an-sets/filtered-attested.ans | sort -T . > $d/an-sets/unused.ans
	
	echo "    extracting additional set of 3.5K random ANs..."
	python $getCartProduct $d/a-and-n-sets/core.adjs $d/a-and-n-sets/core.ns > tmp.random.ans
	zcat $cooc/elements.fqs.gz | $filter_by_field tmp.random.ans - | awk -v number=$anFreq '$2 >= number' | sort -T . | uniq > tmp.random.ans.attested
	cat $d/an-sets/unused.ans $d/an-sets/sem-space.ans | $filter_by_field -s - tmp.random.ans.attested | gawk 'BEGIN{srand()}{print rand() "\t" $0}' | sort -T . | head -3500 | cut -f2 | sort -T . > $d/an-sets/3500.ans

	mv tmp.target.ans $d/an-sets/attested-ans-fqs

	echo "    done!"

	#---------------------------------------

	echo ""
	echo "[3] Extendend Vocabulary"
	echo "    putting together elements to include in the Extended Vocabulary..."
	# This set contains all rows in the semantic space
	cat $d/a-and-n-sets/core.adjs $d/a-and-n-sets/core.ns util/aamp-rg.ns util/ml.adjs-and-ns $d/an-sets/sem-space.ans $d/an-sets/3500.ans | sort -T . | uniq > $d/target.rows
	echo "    done!"
	
	# cleanup tmp files
	rm tmp.*
fi

#---------------------------------------

## Check that the Rows file (target.rows) is where it should be
if [ ! -s $d/target.rows ]; then
	echo "Error: target.rows: File not created or Does not exist"
	exit 1
fi

#---------------------------------------

if [ $buildSemSpace -eq 1 ]; then
	echo ""
	echo "[4] Build Semantic Space"

	echo "    getting target columns: $column_dims most frequent elements with POS in [$col_pos] that cooccur with target rows (leaving out those in top 300 all POS cooccurrences)..."
	## filter with all POS in cooccurrence tuples file
	zcat $cooc/fqs.all.gz | gawk '$2~/..../' | $filter_by_field $d/target.rows - | cut -f2 | sort -T . | uniq > tmp.relevant.column.types
	zcat $cooc/fqs.all.gz | gawk '$2~/..../' | $filter_by_field $d/a-and-n-sets/core.elements - | cut -f2 | sort -T . | uniq > tmp.relevant.column.types
	zcat $cooc/elements.fqs.gz | $filter_by_field tmp.relevant.column.types - | sort -nrk2 -T . | tail -n+300 | cut -f1 | egrep "\-[$col_pos]$" | head -$column_dims | sort -T . > $d/target.columns

	if [ "$fq_val" == "lmi" ]; then
	        if [ -s $d/fqs.sub.gz ]; then rm $d/fqs.sub.gz; fi
		if [ -s $d/$fq_val.sub.gz ]; then rm $d/$fq_val.sub.gz; fi
	        zcat $cooc/fqs.all.gz | $filter_by_field $d/target.rows - | $filter_by_field -f2 $d/target.columns - > $d/fqs.sub
	        gzip $d/fqs.sub
	        echo "    computing LMI values for target rows..."
		if [ ! -d $d/lmi_core_matrix ]; then mkdir $d/lmi_core_matrix; fi
		python $compute_LMI_from_pairs $d/fqs.sub.gz $d/lmi_core_matrix $d/a-and-n-sets/core.elements $d/target.rows $d/target.columns > $d/$fq_val.sub
		gzip $d/$fq_val.sub
	elif [ "$fq_val" == "logfq" ]; then
	        echo "    computing log(fq) values for target rows..."        
		python $compute_LogFq_from_pairs $cooc/fqs.all.gz $d/target.rows $d/target.columns > $d/$fq_val.sub
	else
		zcat $cooc/$fq_val.all.gz | $filter_by_field -f2 $d/target.columns - > $d/$fq_val.sub
	fi
	gzip $d/$fq_val.sub
	rm tmp.*
	echo "    done"

	echo ""
	echo "    Rows: \"target.rows\""
	echo "    Columns: \"target.columns\""
	echo ""
	echo "    building the non-reduced matrix from the tuples..."

	## Split the rows into 8 smaller parts for memory reasons
	declare -i a=`wc -l $d/target.rows | cut -f1 -d' '`
	echo "$a/8" | bc -l > tmp
	declare -i s=`cat tmp | cut -f1 -d'.'`+2
	split -l$s $d/target.rows tmp.target.rows.
	zcat $d/$fq_val.sub.gz | $filter_by_field tmp.target.rows.aa - | $build_matrix_from_tuples tmp.nonreduced.aa -
	zcat $d/$fq_val.sub.gz | $filter_by_field tmp.target.rows.ab - | $build_matrix_from_tuples tmp.nonreduced.ab -
	zcat $d/$fq_val.sub.gz | $filter_by_field tmp.target.rows.ac - | $build_matrix_from_tuples tmp.nonreduced.ac -
	zcat $d/$fq_val.sub.gz | $filter_by_field tmp.target.rows.ad - | $build_matrix_from_tuples tmp.nonreduced.ad -
	zcat $d/$fq_val.sub.gz | $filter_by_field tmp.target.rows.ae - | $build_matrix_from_tuples tmp.nonreduced.ae -
	zcat $d/$fq_val.sub.gz | $filter_by_field tmp.target.rows.af - | $build_matrix_from_tuples tmp.nonreduced.af -
	zcat $d/$fq_val.sub.gz | $filter_by_field tmp.target.rows.ag - | $build_matrix_from_tuples tmp.nonreduced.ag -
	zcat $d/$fq_val.sub.gz | $filter_by_field tmp.target.rows.ah - | $build_matrix_from_tuples tmp.nonreduced.ah -

	# Check that the columns are the same in all 8 matrices (if not, exit with error)
	> tmp.diff
	diff tmp.nonreduced.aa.col tmp.nonreduced.ab.col >> tmp.diff
	diff tmp.nonreduced.aa.col tmp.nonreduced.ac.col >> tmp.diff
	diff tmp.nonreduced.aa.col tmp.nonreduced.ad.col >> tmp.diff
	diff tmp.nonreduced.aa.col tmp.nonreduced.ae.col >> tmp.diff
	diff tmp.nonreduced.aa.col tmp.nonreduced.af.col >> tmp.diff
	diff tmp.nonreduced.aa.col tmp.nonreduced.ag.col >> tmp.diff
	diff tmp.nonreduced.aa.col tmp.nonreduced.ah.col >> tmp.diff
	if [ -s tmp.diff ]; then
	        echo; echo "Error: columns in nonreduced matrices are not all the same!!"; echo
		exit
        fi

	cat tmp.nonreduced.aa.mat tmp.nonreduced.ab.mat tmp.nonreduced.ac.mat tmp.nonreduced.ad.mat tmp.nonreduced.ae.mat tmp.nonreduced.af.mat tmp.nonreduced.ag.mat tmp.nonreduced.ah.mat | sort -T . | uniq > $d/full.matrix
	
	rm tmp*
	echo "    done"
fi

#---------------------------------------

if [ $svdMatrix -eq 1 ]; then
	echo ""
	echo "[5] SVD Reduction"

	if [ ! -s $d/full.matrix ] && [ -s $d/full.matrix.gz ]; then gzip -d $d/full.matrix.gz; fi
	if [ -s $d/900.matrix.gz ]; then rm $d/900.matrix.gz; fi
	if [ -d $d/svdoutdir ]; then rm -r $d/svdoutdir; fi

	echo "    getting Adj and Noun elements for SVD..."
	gawk 'BEGIN{srand()}{print rand() "\t" $0}' $d/an-sets/sem-space.ans | sort -T . | head -8000 | cut -f2 | sort -T . > tmp.ans
	gawk '$1~/-[nj]$/ && $1!~/-j_/' $d/target.rows | cat - tmp.ans | sort -T . > $d/svd.elements
	$filter_by_field $d/svd.elements $d/full.matrix | sort -T . > tmp.svd.elements.in.nonreduced.mat

	echo "    performing SVD on svd.elements..."
	$svd_matrix_transformer -d $d/svdoutdir -s600 tmp.svd.elements.in.nonreduced.mat > $d/svd.out.mat
	tail -n+2 $d/svdoutdir/svd_out-Vt > $d/Vt

	echo "    projecting the remaining rows onto Vt..."
	$filter_by_field -s $d/svd.elements $d/full.matrix | sort -T . > tmp.not.yet.in.reduced.mat

	## Split the remaining rows into 9 smaller parts for memory reasons
	declare -i a=`wc -l tmp.not.yet.in.reduced.mat | cut -f1 -d' '`
	echo "$a/9" | bc -l > tmp
	declare -i s=`cat tmp | cut -f1 -d'.'`+2
	split -l$s tmp.not.yet.in.reduced.mat tmp.not.yet.in.reduced.

	R --slave --args tmp.not.yet.in.reduced.aa $d/Vt tmp.reduced.aa.mat < $project_onto_v
	echo "    ...done with tmp.reduced.aa.mat"

	R --slave --args tmp.not.yet.in.reduced.ab $d/Vt tmp.reduced.ab.mat < $project_onto_v
	echo "    ...done with tmp.reduced.ab.mat"

	R --slave --args tmp.not.yet.in.reduced.ac $d/Vt tmp.reduced.ac.mat < $project_onto_v
	echo "    ...done with tmp.reduced.ac.mat"

	R --slave --args tmp.not.yet.in.reduced.ad $d/Vt tmp.reduced.ad.mat < $project_onto_v
	echo "    ...done with tmp.reduced.ad.mat"

	R --slave --args tmp.not.yet.in.reduced.ae $d/Vt tmp.reduced.ae.mat < $project_onto_v
	echo "    ...done with tmp.reduced.ae.mat"

	R --slave --args tmp.not.yet.in.reduced.af $d/Vt tmp.reduced.af.mat < $project_onto_v
	echo "    ...done with tmp.reduced.af.mat"

	R --slave --args tmp.not.yet.in.reduced.ag $d/Vt tmp.reduced.ag.mat < $project_onto_v
	echo "    ...done with tmp.reduced.ag.mat"

	R --slave --args tmp.not.yet.in.reduced.ah $d/Vt tmp.reduced.ah.mat < $project_onto_v
	echo "    ...done with tmp.reduced.ah.mat"

	R --slave --args tmp.not.yet.in.reduced.ai $d/Vt tmp.reduced.ai.mat < $project_onto_v
	echo "    ...done with tmp.reduced.ai.mat"

	cat $d/svd.out.mat tmp.reduced.a*.mat | sort -T . | uniq > $d/600.matrix
#	gawk '{for(i=1;i<301;i++) printf "%s\t",$i; print $301; }' $d/600.matrix > $d/300.matrix

	echo "    done!"

	if [ -s tmp.reduced.ai.mat ]; then 
	  rm tmp*
#	  sh run_semantic_space_quality_evaluation_experiments.sh $d > $d/quality-eval-results.txt
	fi
fi

#---------------------------------------

echo; echo "[end] `basename $0`"

#---------------------------------------