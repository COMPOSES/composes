#$ -S /bin/bash
#$ -j y

. /etc/profile
. $HOME/.bash_profile
LC_ALL=C

#----------------------------------------------------------

usage="Usage(): `basename $0` [test-an-file] [output-directory] [data-directory]"

## Read command line arguments
if [ ! -n "$3" ]; then
    echo "Error: Invalid number of arguments"
    echo $usage
    exit 65
    fi

# Specify the file with ANs we want to predict vectors for 
anFile="$1"

# Specify full path of the output directory (remove final "/")
lchr=`expr substr $2 ${#2} 1`
if [ "$lchr" = "/" ]; then outDir="${2%?}"; else outDir="$2"; fi
if [ ! -d $outDir ]; then mkdir $outDir; fi

# Specify directory where to find the Semantic Spaces (IMPORTANT)
lchr=`expr substr $3 ${#3} 1`
if [ "$lchr" = "/" ]; then dataDir="${3%?}"; else dataDir="$3"; fi
if [ ! -d $dataDir ]; then 
    echo "Error: Data directory does not exist or is empty"
    echo $usage
    exit 65
    fi

# Specify location of scripts
file_prep="util/file-prep-an-vectors.sh"
generate_vectors="util/generate-an-vectors.sh"

#----------------------------------------------------------

echo "[begin]"
echo "Test ANs: $anFile"
echo "Output File: $outDir/anVectors-full-run.sh"

echo "#$ -wd $outDir" > $outDir/anVectors-full-run.sh
echo "#$ -S /bin/bash" >> $outDir/anVectors-full-run.sh
echo "#$ -j y" >> $outDir/anVectors-full-run.sh
echo "" >> $outDir/anVectors-full-run.sh
echo "LC_ALL=C" >> $outDir/anVectors-full-run.sh
echo "" >> $outDir/anVectors-full-run.sh

echo "## File prep for compositionality models" >> $outDir/anVectors-full-run.sh
echo "sh $file_prep $anFile $outDir $dataDir" >> $outDir/anVectors-full-run.sh
echo "" >> $outDir/anVectors-full-run.sh

# Baseline models (adj and noun only)
for model in adj-only ns-only; do
    echo "## Commands for $model models" >> $outDir/anVectors-full-run.sh
    for space in reduced full; do
	echo "sh $generate_vectors $anFile $outDir $dataDir $model $space nonnormalized none" >> $outDir/anVectors-full-run.sh
    done
    echo "" >> $outDir/anVectors-full-run.sh
done

# Additive and Multiplicative models
for model in add mult; do
    echo "## Commands for $model models" >> $outDir/anVectors-full-run.sh
    for space in reduced full; do
	for norm in nonnormalized normalized; do
	    for weight in none 4a6n 3a7n 6a4n 7a3n; do
		    echo "sh $generate_vectors $anFile $outDir $dataDir $model $space $norm $weight" >> $outDir/anVectors-full-run.sh
	    done
	done
    done
    echo "" >> $outDir/anVectors-full-run.sh
done

# Dilation models
echo "## Commands for dilation models" >> $outDir/anVectors-full-run.sh
    for space in reduced full; do
	for norm in nonnormalized normalized; do
	    for lambda in 2.2 4 6 8 10 12 14 16.7 18 20; do
		    echo "sh $generate_vectors $anFile $outDir $dataDir dl $space $norm $lambda" >> $outDir/anVectors-full-run.sh
	    done
	done
    done
echo "" >> $outDir/anVectors-full-run.sh

# Emiliano-style linear model
echo "## Commands for lm models" >> $outDir/anVectors-full-run.sh
for param in 100 200 300 10 20 30 40 50; do
    echo "sh $generate_vectors $anFile $outDir $dataDir lm reduced nonnormalized $param" >> $outDir/anVectors-full-run.sh
done
echo "" >> $outDir/anVectors-full-run.sh

# (Baroni & Zamparelli, 2010) Adj-specific linear model
echo "## Commands for alm models" >> $outDir/anVectors-full-run.sh
for param in 50 40 30 20 10; do
    echo "sh $generate_vectors $anFile $outDir $dataDir alm reduced nonnormalized $param" >> $outDir/anVectors-full-run.sh
done
echo "" >> $outDir/anVectors-full-run.sh

echo "[end]"


