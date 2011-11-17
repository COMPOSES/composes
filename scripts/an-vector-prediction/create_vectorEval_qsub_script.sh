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
if [ ! -d $outDir ]; then echo "Error: Output directory does not exist"; exit 1; fi

# Specify directory where to find the Semantic Spaces (IMPORTANT)
lchr=`expr substr $3 ${#3} 1`
if [ "$lchr" = "/" ]; then dataDir="${3%?}"; else dataDir="$3"; fi
if [ ! -d $dataDir ]; then 
    echo "Error: Data directory does not exist or is empty"
    echo $usage
    exit 65
    fi

# Specify location of scripts
evaluate_vector_predictions="util/evaluate-an-vector-predictions.sh"

#----------------------------------------------------------

echo "[begin]"
echo "Test ANs: $anFile"
echo "Output File: $outDir/vectorEval-full-run.sh"

echo "#$ -wd $outDir" > $outDir/vectorEval-full-run.sh
echo "#$ -S /bin/bash" >> $outDir/vectorEval-full-run.sh
echo "#$ -j y" >> $outDir/vectorEval-full-run.sh
echo "" >> $outDir/vectorEval-full-run.sh
echo "LC_ALL=C" >> $outDir/vectorEval-full-run.sh
echo "" >> $outDir/vectorEval-full-run.sh

for model in adj ns; do
    echo "## Commands for $model models" >> $outDir/vectorEval-full-run.sh
    for space in reduced full; do
	echo "sh $evaluate_vector_predictions $anFile $outDir $dataDir $model $space nonnormalized none" >> $outDir/vectorEval-full-run.sh
    done
    echo "" >> $outDir/vectorEval-full-run.sh
done


for model in add mult; do
    echo "## Commands for $model models" >> $outDir/vectorEval-full-run.sh
    for space in reduced full; do
	for weight in none 4a6n 3a7n 6a4n 7a3n; do
	    for norm in nonnormalized normalized; do
		    echo "sh $evaluate_vector_predictions $anFile $outDir $dataDir $model $space $norm $weight" >> $outDir/vectorEval-full-run.sh
	    done
	done
    done
    echo "" >> $outDir/vectorEval-full-run.sh
done

echo "## Commands for Dilation models" >> $outDir/vectorEval-full-run.sh
for space in reduced full; do
    for lambda in 16.7 2.2 2 4 6 8 10 12 14 16 18 20; do
	for norm in nonnormalized normalized; do
	    echo "sh $evaluate_vector_predictions $anFile $outDir $dataDir dl $space $norm $lambda" >> $outDir/vectorEval-full-run.sh
	done
    done
done
echo "" >> $outDir/vectorEval-full-run.sh

for param in 100 200 300 10 20 30 40 50; do
    echo "## Commands for lm models" >> $outDir/vectorEval-full-run.sh
    echo "sh $evaluate_vector_predictions $anFile $outDir $dataDir lm reduced nonnormalized $param" >> $outDir/vectorEval-full-run.sh
done
echo "" >> $outDir/vectorEval-full-run.sh

for param in 50 40 30 20 10; do
    echo "## Commands for alm models" >> $outDir/vectorEval-full-run.sh
    echo "sh $evaluate_vector_predictions $anFile $outDir $dataDir alm reduced nonnormalized $param" >> $outDir/vectorEval-full-run.sh
done
echo "" >> $outDir/vectorEval-full-run.sh

echo "[end]"


