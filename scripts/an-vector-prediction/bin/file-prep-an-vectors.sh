#$ -S /bin/bash
#$ -j y

. /etc/profile
. $HOME/.bash_profile
LC_ALL=C

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

echo "[begin]"

# Get the unique Adjs present in the AN file
python $simple_filter -a -f $anFile | sort -T . | uniq > $outDir/test-adjs

# Get the training matrix for the reduced and full Semantic Spaces 
# Note: Training matrix does *not* include ANs in $anFile or test.ans
# (test.ans created when semantic space was built)
for space in reduced full; do
    cat $anFile $dataDir/an-sets/test.ans | sort -T . | uniq | $filter_by_field -s - $dataDir/$space.matrix > $outDir/training.matrix.$space
done

## File Prep for Comp Models for each adjective
for ADJ in `cat $outDir/test-adjs`; do

    # Initiate directories for each adj
    if [ ! -d $outDir/$ADJ ]; then mkdir $outDir/$ADJ $outDir/$ADJ/models $outDir/$ADJ/tmp; fi
    if [ ! -d $outDir/$ADJ/tmp ]; then mkdir $outDir/$ADJ/tmp; fi

    # Get unique ANs and Ns for each adj
    egrep "^$ADJ" $anFile | sort -T . | uniq > $outDir/$ADJ/tmp/target.ans
    python $simple_filter -n -f $outDir/$ADJ/tmp/target.ans | sort -T . | uniq > $outDir/$ADJ/tmp/target.ns

    for space in reduced full; do
      # Get the Adj and component N vectors in reduced space (for linear models)
      fgrep -w "$ADJ" $outDir/training.matrix.$space > $outDir/$ADJ/tmp/adj_vector.$space
      fgrep -w -f $outDir/$ADJ/tmp/target.ns $outDir/training.matrix.$space > $outDir/$ADJ/tmp/target.ns-in-$space-space.mat
    done

done

echo "[end]"


