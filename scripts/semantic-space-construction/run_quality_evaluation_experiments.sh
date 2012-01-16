#$ -wd /mnt/8tera/shareZBV/data/eva/semantic-space-construction
#$ -S /bin/bash
#$ -j y

. /etc/profile
. $HOME/.bash_profile
LC_ALL=C

## Semantic Space Quality Evaluation Experiments ##

## USAGE(): sh run_quality_evaluation_experiments.sh [output-directory] [testmodelDir]
# 
# $1: output-directory (full path)
# $2: testmodelDir (full path)

## Read command line arguments
if [ ! -n "$2" ]; then echo "Usage: `basename $0` [output-directory] [testmodelDir]"; exit 65; fi
lchr=`expr substr $1 ${#1} 1`
if [ "$lchr" = "/" ]; then dir="${1%?}"; else dir="$1"; fi
lchr=`expr substr $2 ${#2} 1`
if [ "$lchr" = "/" ]; then testmodelDir="${2%?}"; else testmodelDir="$2"; fi

filter_by_field='../../task-independent/filter_by_field.pl'
build_matrix_from_tuples='../../task-independent/build_matrix_from_tuples.pl'
project_onto_v='../../task-independent/project_onto_v.R'
do_correlations_of_models_with_list='util/do_correlations_of_models_with_list.pl'
do_clustering_experiment='util/do_clustering_experiment.pl'
rg_gold='util/rubenstein-goodeneough.txt'
aamp_gold='util/gold-standard.txt'
ml_gold='util/ml_2010_ans_gold.txt'

if [ ! -d $dir/quality-eval ]; then mkdir $dir/quality-eval; fi

#----------------------------------------------------------

## Get semantic spaces for the target elements

echo "[1] Build matrix with RG, AAMP and M&L targets"
cat /mnt/data2/dm/data/experiments/rg/rg.elements /mnt/data2/dm/data/experiments/c-b-lc-categorization/aamp_categorization/elements /home/evamaria.vecchi/data/an/ml_2010_ans.txt | sort -T . | uniq > $dir/quality-eval/elements
zcat $dir/full.matrix.gz | $filter_by_field $dir/quality-eval/elements - > $dir/quality-eval/nonreduced.mat
zcat $dir/reduced.matrix.gz | $filter_by_field $dir/quality-eval/elements - > $dir/quality-eval/reduced.mat

#----------------------------------------------------------

echo ""
echo "[2] RG Experiments"
perl $do_correlations_of_models_with_list 0 /mnt/data2/dm/scripts $dir/quality-eval/rg.results $rg_gold $dir/quality-eval/nonreduced.mat $dir/quality-eval/reduced.mat >$dir/quality-eval/rg.eval.out 2> $dir/quality-eval/rg.eval.err
echo ""
echo "Results of Rubenstein-Goodeneough correlations experiment:"
grep "^[\[0]" $dir/quality-eval/rg.results/R.out

#----------------------------------------------------------

echo ""
echo "[3] AAMP Experiments"
perl $do_clustering_experiment 0 /mnt/data2/dm/scripts $dir/quality-eval/aamp.results $aamp_gold rbr $dir/quality-eval/nonreduced.mat $dir/quality-eval/reduced.mat > $dir/quality-eval/aamp.eval.out 2> $dir/quality-eval/aamp.eval.err
echo ""
echo "Results of AAMP clustering experiment:"
cat $dir/quality-eval/aamp.eval.out

#----------------------------------------------------------

echo ""
echo "[4] M&L Experiments"
perl $do_correlations_of_models_with_list 0 /mnt/data2/dm/scripts $dir/quality-eval/ml.results $ml_gold $dir/quality-eval/nonreduced.mat $dir/quality-eval/reduced.mat >$dir/quality-eval/ml.eval.out 2> $dir/quality-eval/ml.eval.err 
echo ""
echo "Results of Mitchell & Lapata AN correlations experiment:"
grep "^[\[0]" $dir/quality-eval/ml.results/R.out

#----------------------------------------------------------

#echo ""
echo "[5] M&L Experiments with Predicted Vectors"

echo ""
echo "..... M&L in alm-reduced-10:"
cat $testmodelDir/*-j/models/alm_an-reduced-10.mat | perl -ane 's/^p\.//; print' - | $filter_by_field $dir/quality-eval/elements - | sort -T . > $dir/quality-eval/alm-reduced-10.mat
perl $do_correlations_of_models_with_list 0 /mnt/data2/dm/scripts $dir/quality-eval/ml_alm-reduced-10.results $ml_gold $dir/quality-eval/alm-reduced-10.mat >$dir/quality-eval/ml_alm-reduced-10.eval.out 2> $dir/quality-eval/ml_alm-reduced-10.eval.err 
grep "^[\[0]" $dir/quality-eval/ml_alm-reduced-10.results/R.out

echo ""
echo "..... M&L in lm-reduced-200:"
cat $testmodelDir/*-j/models/lm_an-reduced-200.mat | $filter_by_field $dir/quality-eval/elements - | sort -T . > $dir/quality-eval/lm-reduced-200.mat
perl $do_correlations_of_models_with_list 0 /mnt/data2/dm/scripts $dir/quality-eval/ml_lm-reduced-200.results $ml_gold $dir/quality-eval/lm-reduced-200.mat >$dir/quality-eval/ml_lm-reduced-200.eval.out 2> $dir/quality-eval/ml_lm-reduced-200.eval.err 
grep "^[\[0]" $dir/quality-eval/ml_lm-reduced-200.results/R.out

echo ""
echo "..... M&L in add-reduced-n-3a7n:"
cat $testmodelDir/*-j/models/add_an-reduced-n-3a7n.mat | $filter_by_field $dir/quality-eval/elements - | sort -T . > $dir/quality-eval/add-reduced-n-3a7n.mat
perl $do_correlations_of_models_with_list 0 /mnt/data2/dm/scripts $dir/quality-eval/ml_add-reduced-n-3a7n.results $ml_gold $dir/quality-eval/add-reduced-n-3a7n.mat >$dir/quality-eval/ml_add-reduced-n-3a7n.eval.out 2> $dir/quality-eval/ml_add-reduced-n-3a7n.eval.err 
grep "^[\[0]" $dir/quality-eval/ml_add-reduced-n-3a7n.results/R.out

echo ""
echo "..... M&L in mult-full-n:"
cat $testmodelDir/*-j/models/mult_an-full-n.mat | $filter_by_field $dir/quality-eval/elements - | sort -T . > $dir/quality-eval/mult-full-n.mat
perl $do_correlations_of_models_with_list 0 /mnt/data2/dm/scripts $dir/quality-eval/ml_mult-full-n.results $ml_gold $dir/quality-eval/mult-full-n.mat >$dir/quality-eval/ml_mult-full-n.eval.out 2> $dir/quality-eval/ml_mult-full-n.eval.err 
grep "^[\[0]" $dir/quality-eval/ml_mult-full-n.results/R.out

echo ""
echo "..... M&L in dl-reduced-n-20-na:"
cat $testmodelDir/*-j/models/dl_an-reduced-n-20-na.mat | $filter_by_field $dir/quality-eval/elements - | sort -T . > $dir/quality-eval/dl-reduced-n-20-na.mat
perl $do_correlations_of_models_with_list 0 /mnt/data2/dm/scripts $dir/quality-eval/ml_dl-reduced-n-20-na.results $ml_gold $dir/quality-eval/dl-reduced-n-20-na.mat >$dir/quality-eval/ml_dl-reduced-n-20-na.eval.out 2> $dir/quality-eval/ml_dl-reduced-n-20-na.eval.err 
grep "^[\[0]" $dir/quality-eval/ml_dl-reduced-n-20-na.results/R.out


#----------------------------------------------------------

echo ""; echo "[end]"

