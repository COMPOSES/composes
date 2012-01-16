#$ -S /bin/bash
#$ -j y

. /etc/profile
. $HOME/.bash_profile
LC_ALL=C

## USAGE(): sh get_semantic_space_vocab.sh [cooc.ouput-directory] [output-directory]
# 
# $1: cooc.ouput-dir (full path)
# $2: output-directory (full path)
#

#---------------------------------------

### GLOBAL PARAMETERS ###
getVocab=1	# if = 1: get the vocabulary (rows) for the Semantic Space
buildSemSpace=1	# if = 1: build the Semantic Space using target.rows (rows) and target.columns (columns)
svdMatrix=1	# if = 1: perform SVD reduction on the Semantic Space

targetA=700	# The num of most frequent Adjs and Nouns for Target Vocabulary
targetN=4000	# ** Note, these are the Adjs and Nouns used to generate AN pairs

topFreqFilter=0	# A filter to exclude a number of the MOST frequently occurring elements in target & core vocab

coreA=4000	# The num of the most frequent Adjs and Nouns for the Core Vocabulary
coreN=8000	# ** Note, target vocab is a subset of this vocab

anFreq=50	# Minimum frequency of ANs in the corpus

column_dims=10000

col_pos='vjnr'	# specify POS for columns
		# v:verbs, j:adjectives, n:nouns, r:adverbs

fq_val='lmi'	# which type of values to populate semantic space
		# if = 'fqs': raw frequencies
		# if = 'logfq': log(frequency)
		# if = 'lmi': local mutual information

copySpaces=0	# if = 1 : Copy the Semantic Spaces built here to an-vector-pipeline directory
		# ** NOTE! This will compress the current Sem Spaces and MOVE them to the directory $copyDir/PREVIOUS-VERSION/
		# They will become the Sem Spaces used in the an-vector-pipeline (AN vector prediction)
#copyDir="/an-vector-pipeline/data"	# You must specify path to copyDir if copySpaces = 1!


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
if [ $copySpaces -eq 1 ]; then
    if [ ! -d $copyDir ]; then mkdir $copyDir; fi
fi

## Set paths for external scripts used throughout pipeline
## (easier to change one path, and easier on the eye when reading through pipeline)
filter_by_field="../task-independent/filter_by_field.pl"
getCartProduct="../task-independent/getCartProduct.py"
build_matrix_from_tuples="../task-independent/build_matrix_from_tuples.pl"
project_onto_v="../task-independent/project_onto_v.R"
svd_matrix_transformer="../task-independent/svd_matrix_transformer.pl"

#---------------------------------------

echo "[begin] `basename $0`"

if [ $getVocab -eq 1 ]; then
	echo ""
	echo "[1] Adjectives and Nouns"

	echo "    extracting Core Vocabulary..."
	zcat $cooc/elements.fqs.gz | gawk '$1~/...-j$/' | sort -nrk2 -T . | tail -n+$topFreqFilter | head -$coreA > tmp.core.adjs
	cut -f1 tmp.core.adjs | sort -T . | uniq > $d/a-and-n-sets/core.adjs
	zcat $cooc/elements.fqs.gz | gawk '$1~/...-n$/ && $1!~/-j_/' | sort -nrk2 -T . | tail -n+$topFreqFilter | head -$coreN > tmp.core.ns
	cut -f1 tmp.core.ns | sort -T . | uniq > $d/a-and-n-sets/core.ns

	echo "    extracting Target Vocabulary..."
	head -$targetA tmp.core.adjs  | cut -f1 | sort -T . | uniq > $d/a-and-n-sets/target.adjs
	head -$targetN tmp.core.ns | cut -f1 | sort -T . | uniq > $d/a-and-n-sets/target.ns

	cat util/aamp-rg.ns > $d/a-and-n-sets/aamp-rg.ns

	echo "    done!"

	#---------------------------------------

	echo ""
	echo "[2] AN Datasets"

	# For Test Set: 
	# - M&L2010 AN set (also get the component As and Ns)
	# - Color ANs for proxy study
	cat util/ml.ans > $d/an-sets/ml.ans
	cat util/ml.adjs-and-ns > $d/a-and-n-sets/ml.adjs-and-ns
	cat util/color.ans > $d/an-sets/color.ans
	
	echo "    generating AN pairs from the Target Vocabulary..."
	$filter_by_field -s util/problematic-adjs.txt $d/a-and-n-sets/target.adjs > tmp.target.adjs
	python $getCartProduct tmp.target.adjs $d/a-and-n-sets/target.ns > tmp.Cartesian.Product
	zcat $cooc/elements.fqs.gz | $filter_by_field tmp.Cartesian.Product - | sort -T . > tmp.target.ans
	cut -f1 tmp.target.ans > $d/an-sets/attested.ans
	$filter_by_field -s $d/an-sets/attested.ans tmp.Cartesian.Product | cut -f1 | sort -T . > $d/an-sets/unattested.ans
	awk -v number=$anFreq '$2 >= number' tmp.target.ans | cut -f1 | sort -T . > $d/an-sets/filtered-attested.ans
	
	# For each target adjective, make sure we have at least 100 ANs for the training data
	# Note, not including the ml.ans and the color.ans
	> tmp.min-training.ans
	for ADJ in `cat $d/a-and-n-sets/target.adjs`; do
	    cat $d/an-sets/ml.ans $d/an-sets/color.ans | $filter_by_field -s - $d/an-sets/filtered-attested.ans | egrep "^$ADJ" | gawk 'BEGIN{srand()}{print rand() "\t" $0}' | sort -T . | head -100 | cut -f2 | sort -T . >>  tmp.min-training.ans
	done

	echo "    extracting Training, Test, Devel and Unused AN datasets..."
	declare -i a=`wc -l $d/an-sets/filtered-attested.ans | cut -f1 -d' '`
	declare -i b=`wc -l tmp.min-training.ans | cut -f1 -d' '`
	echo "$a*.50-$b" | bc -l > tmp
	declare -i trainingANcount=`cat tmp | cut -f1 -d'.'`
	echo "$a*.30" | bc -l > tmp
	declare -i testANcount=`cat tmp | cut -f1 -d'.'`
	echo "$a*.10" | bc -l > tmp
	declare -i develANcount=`cat tmp | cut -f1 -d'.'`
	rm tmp

	cat $d/an-sets/ml.ans $d/an-sets/color.ans tmp.min-training.ans | $filter_by_field -s - $d/an-sets/filtered-attested.ans | gawk 'BEGIN{srand()}{print rand() "\t" $0}' | sort -T . | head -$trainingANcount | cut -f2 | cat - tmp.min-training.ans | sort -T . > $d/an-sets/training.ans
	$filter_by_field -s $d/an-sets/training.ans $d/an-sets/filtered-attested.ans | gawk 'BEGIN{srand()}{print rand() "\t" $0}' | sort -T . | head -$testANcount | cut -f2 | cat - $d/an-sets/ml.ans $d/an-sets/color.ans | sort -T . | uniq  > $d/an-sets/test.ans
	cat $d/an-sets/test.ans $d/an-sets/training.ans | $filter_by_field -s - $d/an-sets/filtered-attested.ans | gawk 'BEGIN{srand()}{print rand() "\t" $0}' | sort -T . | head -$develANcount | cut -f2 | sort -T .  > $d/an-sets/devel.ans
	cat $d/an-sets/test.ans $d/an-sets/training.ans $d/an-sets/devel.ans | sort -T . > $d/an-sets/sem-space.ans
	$filter_by_field -s $d/an-sets/sem-space.ans $d/an-sets/filtered-attested.ans | sort -T . > $d/an-sets/unused.ans
	
	echo "    extracting additional set of 3.5K random ANs..."
	python $getCartProduct $d/a-and-n-sets/core.adjs $d/a-and-n-sets/core.ns > tmp.random.ans
	zcat $cooc/elements.fqs.gz | $filter_by_field tmp.random.ans - | awk -v number=$anFreq '$2 >= number' | sort -T . | uniq > tmp.random.ans.attested
	cat $d/an-sets/unused.ans $d/an-sets/sem-space.ans | $filter_by_field -s - tmp.random.ans.attested | gawk 'BEGIN{srand()}{print rand() "\t" $0}' | sort -T . | head -3500 | cut -f2 | sort -T . > $d/an-sets/3500.ans
	
	echo "    done!"

	#---------------------------------------

	echo ""
	echo "[3] Extendend Vocabulary"
	echo "    putting together elements to include in the Extended Vocabulary..."
	cat $d/a-and-n-sets/core.adjs $d/a-and-n-sets/core.ns $d/a-and-n-sets/aamp-rg.ns $d/a-and-n-sets/ml.adjs-and-ns $d/an-sets/sem-space.ans $d/an-sets/3500.ans | sort -T . | uniq > $d/target.rows
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

	echo "    getting columns: $column_dims most frequently cooccurring elements with POS in [$col_pos] (leaving out those in top 300 all POS cooccurrences)..."

	# filter with all POS in cooccurrence tuples file
	zcat $cooc/fqs.all.gz | gawk '$2~/.../' | $filter_by_field $d/target.rows - | cut -f2 | sort -T . | uniq -c | gawk '{print $2 "\t" $1}' | sort -nrk2 -T . > tmp.relevant.column.type.counts
	cat tmp.relevant.column.type.counts | tail -n+300 | cut -f1 | egrep "\-[$col_pos]$" | head -$column_dims | sort -T . > $d/target.columns
#	cat tmp.relevant.column.type.counts | tail -n+300 | gawk '$1~/-[vjnr]$/' | head -$column_dims | cut -f1 | sort -T . > $d/target.columns

	zcat $cooc/$fq_val.all.gz | $filter_by_field -f2 $d/target.columns - > $d/$fq_val.sub
	if [ -s $d/$fq_val.sub.gz ]; then rm $d/$fq_val.sub.gz; fi
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
	zcat $d/$fq_val.sub.gz | $filter_by_field tmp.target.rows.aa - | $filter_by_field -f2 $d/target.columns - | $build_matrix_from_tuples tmp.nonreduced.aa -
	zcat $d/$fq_val.sub.gz | $filter_by_field tmp.target.rows.ab - | $filter_by_field -f2 $d/target.columns - | $build_matrix_from_tuples tmp.nonreduced.ab -
	zcat $d/$fq_val.sub.gz | $filter_by_field tmp.target.rows.ac - | $filter_by_field -f2 $d/target.columns - | $build_matrix_from_tuples tmp.nonreduced.ac -
	zcat $d/$fq_val.sub.gz | $filter_by_field tmp.target.rows.ad - | $filter_by_field -f2 $d/target.columns - | $build_matrix_from_tuples tmp.nonreduced.ad -
	zcat $d/$fq_val.sub.gz | $filter_by_field tmp.target.rows.ae - | $filter_by_field -f2 $d/target.columns - | $build_matrix_from_tuples tmp.nonreduced.ae -
	zcat $d/$fq_val.sub.gz | $filter_by_field tmp.target.rows.af - | $filter_by_field -f2 $d/target.columns - | $build_matrix_from_tuples tmp.nonreduced.af -
	zcat $d/$fq_val.sub.gz | $filter_by_field tmp.target.rows.ag - | $filter_by_field -f2 $d/target.columns - | $build_matrix_from_tuples tmp.nonreduced.ag -
	zcat $d/$fq_val.sub.gz | $filter_by_field tmp.target.rows.ah - | $filter_by_field -f2 $d/target.columns - | $build_matrix_from_tuples tmp.nonreduced.ah -

	cat tmp.nonreduced.aa.mat tmp.nonreduced.ab.mat tmp.nonreduced.ac.mat tmp.nonreduced.ad.mat tmp.nonreduced.ae.mat tmp.nonreduced.af.mat tmp.nonreduced.ag.mat tmp.nonreduced.ah.mat | sort -T . | uniq > $d/full.matrix
	gzip $d/full.matrix

	rm tmp*
	echo "    done"
	fi

#---------------------------------------

if [ $svdMatrix -eq 1 ]; then
	echo ""
	echo "[5] SVD Reduction"

	if [ ! -s $d/full.matrix ] && [ -s $d/full.matrix.gz ]; then gzip -d $d/full.matrix.gz; fi
	if [ -s $d/reduced.matrix.gz ]; then rm $d/reduced.matrix.gz; fi
	if [ -d $d/svdoutdir ]; then rm -r $d/svdoutdir; fi

	echo "    getting Adj and Noun elements for SVD..."
	gawk '$1~/-[nj]$/ && $1!~/-j_/' $d/target.rows | sort -T . > $d/svd.elements
	$filter_by_field $d/svd.elements $d/full.matrix | sort -T . > tmp.svd.elements.in.nonreduced.mat

	echo "    performing SVD on svd.elements..."
	$svd_matrix_transformer -d $d/svdoutdir -s300 tmp.svd.elements.in.nonreduced.mat > $d/svd.out.mat
	tail -n+2 $d/svdoutdir/svd_out-Vt > $d/Vt

	echo "    projecting the remaining rows onto Vt..."
	$filter_by_field -s $d/svd.elements $d/full.matrix | sort -T . > tmp.not.yet.in.reduced.mat

	## Split the remaining rows into 8 smaller parts for memory reasons
	declare -i a=`wc -l tmp.not.yet.in.reduced.mat | cut -f1 -d' '`
	echo "$a/8" | bc -l > tmp
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

	cat $d/svd.out.mat tmp.reduced.a*.mat | sort -T . | uniq > $d/reduced.matrix
	echo "    done!"

	if [ -s tmp.reduced.ah.mat ]; then 
	  rm tmp*

	  if [ $copySpaces -eq 1 ]; then
	      if [ -s $copyDir/full.matrix ]; then
		  gzip $copyDir/reduced.matrix; gzip $copyDir/full.matrix
		  mv $copyDir/*.matrix.gz $copyDir/PREVIOUS-VERSION/
		  mv $copyDir/all.rows $copyDir/PREVIOUS-VERSION/
		  mv $copyDir/an-sets/* $copyDir/PREVIOUS-VERSION/an-sets/
	      fi
	      if [ ! -d $copyDir/an-sets ]; then mkdir $copyDir/an-sets; fi
	      cp $d/an-sets/* $copyDir/an-sets/
	      cp $d/*.matrix $copyDir/
	      cut -f1 $d/reduced.matrix > $copyDir/all.rows
	      gzip $d/reduced.matrix; gzip $d/full.matrix
	  fi
	fi	 
	echo ""
	echo "done!"
fi	

#---------------------------------------

echo; echo "[end] `basename $0`"
