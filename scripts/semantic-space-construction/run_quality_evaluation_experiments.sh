#$ -wd /mnt/8tera/shareZBV/data/eva/semantic-space-construction
#$ -S /bin/bash
#$ -j y

. /etc/profile
. $HOME/.bash_profile
LC_ALL=C

## Semantic Space Quality Evaluation Experiments ##

## USAGE(): sh run_quality_evaluation_experiments.sh [output-directory]
# 
# $1: output-directory (full path)
#

## Read command line arguments
if [ ! -n "$2" ]; then echo "Usage: `basename $0` [output-directory] [testmodelDir]"; exit 65; fi
lchr=`expr substr $1 ${#1} 1`
if [ "$lchr" = "/" ]; then dir="${1%?}"; else dir="$1"; fi

filter_by_field='../../task-independent/filter_by_field.pl'
do_correlations_of_models_with_list='../../task-specific/do_correlations_of_models_with_list.pl'
do_clustering_experiment='../../task-specific/do_clustering_experiment.pl'
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

echo ""; echo "[end]"

