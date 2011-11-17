#!/usr/bin/perl -w

# traverse input list twice, the first time collects firstel_'s (the
# dvs), the second the corresponding simple nouns

use String::Random qw(random_string);

$first_el = shift;
$ifile = shift;

# random file so we can traverse it twice even if input is from stdout
$tfile = random_string("cccccccccccccccccccc");
# if that file already exists (unlikely!) we try with another random
# name
while (-e $tfile) {
    $tfile = random_string("cccccccccccccccccccc");
}

# copy
open IFILE,$ifile;
open TFILE,">$tfile";
while (<IFILE>) {
    print TFILE $_;
}
close TFILE;
close IFILE;

# first pass, collects firstel_x elements and their vectors
$first_el_regexp = "\Q$first_el";
open TFILE,$tfile;
while (<TFILE>) {
    chomp;
    @F = split "[\t ]+",$_;
    $pair = shift @F;
    if ($pair =~ /^${first_el_regexp}_(.*)$/) {
	$dvs_of_pair{$1} = join "\t",@F;
    }	
}
close TFILE;

# second pass, the single elements vectors and pring
open TFILE,$tfile;
while (<TFILE>) {
    chomp;
    @F = split "[\t ]+",$_;
    $item = shift @F;
    if ($dvs = $dvs_of_pair{$item}) {
	print $first_el,"\t",$item,"\t",join("\t",@F),"\t",$dvs,"\n";
    }
}
close TFILE;

`rm $tfile`;
