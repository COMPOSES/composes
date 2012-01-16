#$ -S /bin/bash
#$ -j y

. /etc/profile
. $HOME/.bash_profile
LC_ALL=C 


## Global Parameter Settings ##

if [ ! -n "$1" ]; then
    echo "Error: Invalid number of arguments"
    echo "Usage():   `basename $0` [output-directory]"
    exit 65
    fi

## Set the directory where the python script coocExtraction.py will print to
lchr=`expr substr $1 ${#1} 1`; if [ "$lchr" = "/" ]; then d="${1%?}"; else d="$1"; fi
if [ ! -d $d ]; then mkdir $d; fi

## --------------------------------

echo "begin"

## Extract the Co-occurrences from the corpus
## Note, for memory reasons it will print out an unsorted list
## of Tuples and Elements as they appear in the corpus
zcat bnc.xml.gz ukwac*.xml.gz wikipedia-*.xml.gz | python util/coocExtraction.py

## Sort and get Unique Count of all Tuples
## Note, Tuples are co-occurring element pairs of the format:
## {N, A, ANs}  {N, A, V, Adv}
zcat $d/extracted-files/tuples*.gz | sort -T . | uniq -c | gawk '{print $2 "\t" $3 "\t" $1}' > $d/tuples.fqs
gzip $d/tuples.fqs

## Calculate the Log Frequency of the tuples
zcat $d/tuples.fqs.gz | python util/coocScores.LogFq.py

## Calculate the Local Mutual Information of the tuples
if [ ! -d $d/lmi_core_matrix]; then mkdir $d/lmi_core_matrix; fi
python util/coocScores.LMI.py $d/fqs.all.gz $d/lmi_core_matrix > $d/lmi.all
gzip $d/lmi.all

## Sort and get Unique Count of all elements
## Note, elements are {N, A, ANs, V, Adv} in the corpus
zcat $d/extracted-files/elements*.gz | python util/element_frequencies.py
zcat $d/elements.fqs.gz | sort -T . - > $d/temp.elements.fqs
mv $d/elements.fqs.gz $d/extracted-files/elements.fqs_unsorted.gz
mv $d/temp.elements.fqs $d/elements.fqs
gzip $d/elements.fqs

echo; echo "[end] `basename $0`"
