#$ -S /bin/bash
#$ -j y

. /etc/profile
. $HOME/.bash_profile
LC_ALL=C

## ----------------------------------------------------------------------------------------------------------

## Global Settings:

# Specify the file with ANs we want to predict vectors for 
anFile="$1"

# Specify full path of the output directory (remove final "/")
lchr=`expr substr $2 ${#2} 1`; if [ "$lchr" = "/" ]; then outDir="${2%?}"; else outDir="$2"; fi

# Specify full path where the full/reduced Semantic Spaces are stored (remove final "/")
lchr=`expr substr $3 ${#3} 1`; if [ "$lchr" = "/" ]; then dataDir="${3%?}"; else dataDir="$3"; fi

## reference to external scripts
simple_filter="../../task-independent/simple.filter.py"
filter_by_field="../../task-independent/filter_by_field.pl"
adj_augmented_align_firstel_specific_ivs_dvs="util/adj_augmented_align_firstel_specific_ivs_dvs.pl"

## ----------------------------------------------------------------------------------------------------------

echo "[begin] `basename $0`"; echo

# Get the unique Adjs present in the AN file
#python $simple_filter -a -f $anFile | sort -T . | uniq | $filter_by_field -s $dataDir/an-sets/problem-adjectives - > $outDir/test-adjs
python $simple_filter -a -f $anFile | sort -T . | uniq > $outDir/test-adjs

# Get the training matrix for the reduced and full Semantic Spaces 
# Note: Training matrix includes vectors for the Adjectives, Nouns and Training ANs (not in the Test AN file)
# (training.ans created when semantic space was built)
echo "    building the training matrix for the reduced and full Semantic Spaces..."
gawk '$1~/-[nj]$/ && $1!~/-j_/' $dataDir/all.rows | cut -f1 > $outDir/tmp.training_a_n
for space in reduced full; do
    cat $outDir/tmp.training_a_n $dataDir/an-sets/training.ans | $filter_by_field -s $anFile - | $filter_by_field - $dataDir/$space.matrix | sort -T . > $outDir/training.matrix.$space
done
rm $outDir/tmp.*
echo "    done"; echo

## ----------------------------------------------------------------------------------------------------------

## File Prep for Comp Models for each adjective
echo "    prep directories and files for each test adjective..."
for ADJ in `cat $outDir/test-adjs`; do

    # Initiate directories for each adj
    if [ ! -d $outDir/$ADJ ]; then mkdir $outDir/$ADJ $outDir/$ADJ/models $outDir/$ADJ/tmp; fi
    if [ ! -d $outDir/$ADJ/tmp ]; then mkdir $outDir/$ADJ/tmp; fi

    # Get unique ANs and Ns for each adj
    egrep "^$ADJ" $anFile | sort -T . | uniq > $outDir/$ADJ/tmp/target.ans
    python $simple_filter -n -f $outDir/$ADJ/tmp/target.ans | sort -T . | uniq > $outDir/$ADJ/tmp/target.ns

    for space in reduced full; do
      # Get the Adj and component N vectors in reduced space (for linear models)
      egrep -w "^$ADJ" $outDir/training.matrix.$space > $outDir/$ADJ/tmp/adj_vector.$space
      perl $filter_by_field $outDir/$ADJ/tmp/target.ns $outDir/training.matrix.$space > $outDir/$ADJ/tmp/target.ns-in-$space-space.mat
    done

done
echo "    done"; echo

## ----------------------------------------------------------------------------------------------------------

## Get training ANs and ivs-dvs file for emi-style Linear Model
echo "    getting training data for emi-style Linear Model..."
space='reduced'
if [ ! -d $outDir/emi-lm-training ]; then mkdir $outDir/emi-lm-training; fi
if [ ! -s $outDir/emi-lm-training/lm.ans ]; then 
#    for ADJ in `cat $outDir/test-adjs`; do
#	egrep "^$ADJ\_" $outDir/training.matrix.$space | cut -f1 >> $outDir/tmp.lm.ans
#    done
    cat $dataDir/an-sets/training.ans | gawk 'BEGIN{srand()}{print rand() "\t" $0}' | sort | head -2500 | gawk '{print $2}' | sort > $outDir/emi-lm-training/lm.ans
    perl $adj_augmented_align_firstel_specific_ivs_dvs $outDir/emi-lm-training/lm.ans $outDir/training.matrix.$space | sort -T . > $outDir/emi-lm-training/lm.ans-ivs-dvs.txt
fi
rm $outDir/tmp.*
echo "    done"

## ----------------------------------------------------------------------------------------------------------

echo; echo "[end] `basename $0`"


