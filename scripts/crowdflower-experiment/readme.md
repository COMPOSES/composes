# CrowdFlower experiment to judge unattested AN plausability #

This document describes the steps taken to construct the test set for the CrowdFlower experiment

## Unattested AN Dataset Construction ##

	$ cat disco2011-acceptable_AN_testset.txt disco2011-deviant_AN_testset.txt unattested-to-rate.txt |  perl filter_by_field.pl -s - unattested.ans | gawk 'BEGIN{srand()}{print rand() "\t" $0}' | sort -T . | head -200 | cut -f2 | sort -T . > unattested-to-rate-2.txt
	$ perl filter_by_field.pl unattested.ans disco2011-acceptable_AN_testset.txt | sort -T . > acceptable_AN_testset.txt
	$ perl filter_by_field.pl unattested.ans disco2011-deviant_AN_testset.txt | sort -T . > deviant_AN_testset.txt


## Construct the test set for CrowdFlower annotations ##

	$ cat disco2011-acceptable_AN_testset.txt disco2011-deviant_AN_testset.txt unattested-to-rate.txt |  perl filter_by_field.pl -s - unattested.ans | gawk '$1!~/(fifth|first|second|third|fourth|sixth|seventh|eighth|ninth|tenth|alive|above|Recent|Fax|Many|worth|Key)-j/ && $1!~/_(cant|cos|Everything|Everyone|Fax|Hone|iii|none|Jul|Sep|Thank)-n/' | gawk 'BEGIN{srand()}{print rand() "\t" $0}' | sort -T . | head -30000 | cut -f2 > all-ans.txt
	$ for an in `cat all-ans.txt`; do
	..    echo $an >> ans1.txt
	..    echo $an >> ans1.txt
	..    echo $an >> ans1.txt
	..    echo $an >> ans1.txt
	..    echo $an >> ans1.txt
	..    echo $an >> ans2.txt
	..    echo $an >> ans2.txt
	..    echo $an >> ans2.txt
	..    echo $an >> ans2.txt
	..    echo $an >> ans2.txt
	..    done	
	$ python 
	
	import random
	f1=open("ans1.txt","r")
	f2=open("ans2.txt","r")
	
	ans1=[]
	for line in f1:
		ans1.append(line.split())
	
	f1.close()
		
	ans2=[]
	for line in f2:
		ans2.append(line.split())
	
	f2.close()
	
	pairs={}
	leftover={}
	
	random.shuffle(ans1)
	random.shuffle(ans1)
	random.shuffle(ans2)
	for i in range(len(ans1)):
		if ans1[i]!=ans2[i]:
			if not pairs.has_key(ans1[i][0]+'\t'+ans2[i][0]):
				pairs[ans1[i][0]+'\t'+ans2[i][0]]=1
			else:
				leftover[ans1[i][0]+'\t'+ans2[i][0]]=1
		else:
			leftover[ans1[i][0]+'\t'+ans2[i][0]]=1
	
	#--- repeat from here until no leftovers -------
	ans1=[]
	ans2=[]
	for v,k in leftover.iteritems():
		ans1.append(v.split('\t')[0])
		ans2.append(v.split('\t')[1])
	
	leftover={}
	random.shuffle(ans1)
	random.shuffle(ans1)
	random.shuffle(ans2)
	for i in range(len(ans1)):
		if ans1[i]!=ans2[i]:
			if not pairs.has_key(ans1[i][0]+'\t'+ans2[i][0]):
				pairs[ans1[i][0]+'\t'+ans2[i][0]]=1
			else:
				leftover[ans1[i][0]+'\t'+ans2[i][0]]=1
		else:
			leftover[ans1[i][0]+'\t'+ans2[i][0]]=1	
	#------------------------------------------------
	
	outFile=open('all-pairs.txt','w')
	for v,k in pairs.iteritems():
		outFile.write(v+'\n')
	
	outFile.close()
	exit()


	$ cat all-pairs.txt | perl -ane 's/\-n\t/,/g; print' | perl -ane 's/\-j\_/ /g; print' | perl -ane 's/\-n\n/\n/g; print' > tmp
	$ echo "an1,an2" | cat - tmp > all-pairs_formatted.csv
	$ rm tmp

