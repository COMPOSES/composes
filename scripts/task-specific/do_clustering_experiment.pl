#!/usr/bin/perl -w

# input:
# 1) number of splits

# 2) path to scripts superdir

# 3) name of output dir

# 4) gold standard in format
# element class1 ... classN
# where each column after the first represents a different clustering solution

# 5) clustering method string, to be passed to cluto

# 6...) matrix file(s) in format (tab- or space-delimited)
# el d1 d2...
# (if an el is not in it, it is assumed to have 0 cosince with all
# other els)

# output
# - to STDOUT and STDERR: some progress report
#
# - in the output dir, the sorted version of the gold standard and,
# for each input matrix, the corresponding similarity matrix, and,
# for each clustering solution and each input matrix, the
# corresponding cluster output summary and a file with the elements,
# the cluster number and the true class

$number_of_splits = shift;
$scripts_dir = shift;
$independent_dir =  "$scripts_dir/task-independent";


$out_dir = shift;
if (-e $out_dir) {
    die "$out_dir already exists";
}
`mkdir $out_dir`;

$in_gold_standard = shift;
`sort $in_gold_standard > $out_dir/gold_standard`;

$clustering_method = shift;

$solution_total = `head -1 $out_dir/gold_standard | gawk '{print NF}'`;
$solution_total =~ s/^[^0-9]+//;
$solution_total =~ s/[^0-9]+$//;
$solution_total--;

open GOLD, "$out_dir/gold_standard";
$i=1;
while ($i<=$solution_total) {
    open $i,">$out_dir/solution.$i";
    $i++;
}
while (<GOLD>) {
    chomp;
    s/\r//g;
    @F = split "[\t ]+",$_;
    push @ordered_element_list,shift @F;
    $solution_counter = 0;
    foreach (@F) {
	$solution_counter++;
	$unique_in_solution{$solution_counter}{$_} = 1;
	print $solution_counter $_,"\n";
    }
}
close GOLD;

$last_element_index = $#ordered_element_list;
if ($number_of_splits == 0) {
    $chunk_size = $last_element_index + 1;
}
else {
    $chunk_size = int(($last_element_index+1)/$number_of_splits);
}
$chunk_offset = 0;
while ($chunk_offset <= $last_element_index) {
    push @begin_chunk_offsets,$chunk_offset;
    $chunk_end = $chunk_offset + $chunk_size - 1;
    if ($chunk_end > $last_element_index) {
	$chunk_end = $last_element_index;
    }
    push @end_chunk_offsets,$chunk_end;
    $chunk_offset += $chunk_size;
}


$i=1;
while ($i<=$solution_total) {
    close $i;
    $i++;
}

print scalar(@ordered_element_list), " elements\n";

print "solutions: $solution_total\n";
$i = 1;
while ($i<=$solution_total) {
    $cluster_count{$i} = scalar(keys(%{$unique_in_solution{$i}}));
    print "$cluster_count{$i} clusters in solution $i\n";
    $i++;
}

$paired_file = "$out_dir/TEMPpaired";
$temp_cosine_file = "$out_dir/tempXXX";

$matrix_counter = 1; 
while ($matrix = shift) {
    print "processing $matrix\n";
    print STDERR "processing $matrix\n";


    $first_chunk_index = 0;
    while ($first_chunk_index <= $#begin_chunk_offsets) {
	$first_chunk_begin = $begin_chunk_offsets[$first_chunk_index];
	$first_chunk_end = $end_chunk_offsets[$first_chunk_index];

	$second_chunk_index = $first_chunk_index;
	while ($second_chunk_index <= $#begin_chunk_offsets) {
	    $second_chunk_begin = $begin_chunk_offsets[$second_chunk_index];
	    $second_chunk_end = $end_chunk_offsets[$second_chunk_index];


	    print STDERR 
		"pairing chunks ", $first_chunk_index + 1, 
		" and ", $second_chunk_index + 1, "\n";

	    open PAIRED,">$paired_file";
	    foreach $first_el 
		(@ordered_element_list[$first_chunk_begin..$first_chunk_end]) {
		    foreach $second_el
			(@ordered_element_list
			 [$second_chunk_begin..$second_chunk_end]) {
			    print PAIRED $first_el,"\t",$second_el,"\n";
		    }
	    }
	    close PAIRED;
	    `$independent_dir/compute_cosines_of_pairs.pl -v $paired_file $matrix >> $temp_cosine_file`;
	    `rm -f $paired_file`;
   	    $second_chunk_index++;
	}
	$first_chunk_index++;
    }

    open COS,$temp_cosine_file;
    while (<COS>) {
	chomp;
	@F = split "[\t ]+",$_;
	$cosine_of{$F[0]}{$F[1]} = $F[2];
    }
    close COS;
    `rm -f $temp_cosine_file`;
    
    $cluto_name = "$matrix.$matrix_counter";
    $matrix_counter++;
    $cluto_name =~ s/^.*\///;

    $cluto_matrix = "$out_dir/$cluto_name.mat";
    open MAT,">$cluto_matrix";
    print MAT scalar(@ordered_element_list),"\n";
    $i = 0;
    while ($i<=$#ordered_element_list) {
	$j = 0;
	@row = ();
	while ($j<=$#ordered_element_list) {
	    if ($i<=$j) {
		push @row,
		$cosine_of{$ordered_element_list[$i]}
		{$ordered_element_list[$j]};
	    }
	    else {
		push @row,
		$cosine_of{$ordered_element_list[$j]}
		{$ordered_element_list[$i]};
	    }
	    $j++;
	}
	print MAT join "\t",@row;
	print MAT "\n";
	$i++;
    }
    close MAT;
    
    $i = 1;
    while ($i<=$solution_total) {
	
	`scluster -clmethod=$clustering_method -clustfile=$out_dir/temp.clusters -rclassfile=$out_dir/solution.$i $cluto_matrix $cluster_count{$i} > $out_dir/$cluto_name.$i.out`;

	`gawk '{print \$1}' $out_dir/gold_standard | paste - $out_dir/temp.clusters $out_dir/solution.$i | sort -nk2 > $out_dir/$cluto_name.$i.clusters`;
	
	`rm -f $out_dir/temp.clusters`;

	$i++;
    }
}

print "results summmary:\n";
$result_lines = `grep Entropy $out_dir/*out`;
print $result_lines;

`rm -f $paired_file`;
print "all done\n";
