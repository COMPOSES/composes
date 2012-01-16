#!/usr/bin/perl -w

# input:
# 1) max size of chunks to pass to the cosine computing routine (if 0,
# no max size)

# 2) path to scripts superdir

# 3) name of output dir

# 4)  scored list in format (tab- or space-delimited)
# e1 e2 score

# 5...) matrix file(s) in format (tab- or space-delimited)
# el d1 d2...
# (if an el is not in it, it is assumed to have 0 cosince with all
# other els)

# output
# - to STDOUT and STDERR, various progress info
# - in the output dir, the various files constructed on the way and a
# R.out file with the spearman and pearson results for each input
#  matrix

$max_chunk_size = shift;
$scripts_dir = shift;
$independent_dir =  "$scripts_dir/task-independent";
$specific_dir =  "$scripts_dir/task-specific";

$out_dir = shift;
if (-e $out_dir) {
    die "$out_dir already exists";
}
`mkdir $out_dir`;

$score_file = shift;
$temp_in = "$out_dir/tempinXXX";
$temp_file = "$out_dir/tempXXX";
`gawk '{print \$1 "\t" \$2}' $score_file | sort -k2 > $temp_in`;

$i = 1;
while ($matrix = shift) {
    print "processing $matrix\n";
    print STDERR "processing $matrix\n";

    print STDERR "computing pairwise cosines\n";
    if ($max_chunk_size) {
	$chunk_number = 0;
	$chunk_file = "$out_dir/temp_chunk_file";
	$chunk_size_counter = 0;
	open PAIRS,$temp_in;
	while (<PAIRS>) {
	    if (!$chunk_size_counter) {
		open CHUNKFILE, ">$chunk_file";
	    }
	    print CHUNKFILE $_;
	    $chunk_size_counter++;
	    if ($chunk_size_counter == $max_chunk_size) {
		close CHUNKFILE;
		
		$chunk_number++;
		print STDERR "processing chunk number $chunk_number\n";
		`$independent_dir/compute_cosines_of_pairs.pl -v $chunk_file $matrix >> $temp_file`;
		`rm -f $chunk_file`;
		
		$chunk_size_counter = 0
		}
	}
	close PAIRS;
	if ($chunk_size_counter) {
	    close CHUNKFILE;
	    $chunk_number++;
	    print STDERR "processing chunk number $chunk_number\n";
	    `$independent_dir/compute_cosines_of_pairs.pl -v $chunk_file $matrix >> $temp_file`;
	    `rm -f $chunk_file`;
	}
    }
    else { # $max_chunk_size is 0
	`$independent_dir/compute_cosines_of_pairs.pl -v $temp_in $matrix > $temp_file`;
    }

    open COS,$temp_file;
    while (<COS>) {
	chomp;
	@F = split "[\t ]+",$_;
	$cosine_of{"$F[0]\t$F[1]"} = $F[2];
    }
    close COS;
    `rm -f $temp_file`;
    $rfile_name = "$matrix.$i.R";
    $i++;
    $rfile_name =~ s/^.*\///;
    open RFILE,"> $out_dir/$rfile_name" or die "could not open file $out_dir/$rfile_name for writing";
    print RFILE "E1\tE2\tSCORE\tCOS\n";
    open SCORES,$score_file;
    while (<SCORES>) {
	chomp;
	($e1,$e2,$score) = split "[\t ]+",$_;
	$cos = 	$cosine_of{"$e1\t$e2"};
	print RFILE join "\t",($e1,$e2,$score,$cos);
	print RFILE "\n";
    }
    close SCORES;
    close RFILE;

    `R --no-save --args $out_dir/$rfile_name < $specific_dir/do-score-cos-correlations.R >> $out_dir/R.out`

}

`rm -f $temp_in`;
print "all done\n";
