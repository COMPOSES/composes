#!/usr/bin/perl -w

# input files:

# - a list of target adj_noun

# - matrix including the targets, the corresponding adjs and the
# simple nouns

# output:

# iv vectors (adj and simple noun), dv vectors (adj-n vector)


use String::Random qw(random_string);

$an_file = shift;
$ifile = shift;

# random file so we can traverse input twice even if it comes from stdout
$tfile = random_string("cccccccccccccccccccc");
# if that file already exists (unlikely!) we try with another random
# name
while (-e $tfile) {
    $tfile = random_string("cccccccccccccccccccc");
}

# collect first els, simple nouns and adjs
open ANS,$an_file;
while (<ANS>) {
    chomp;
    $is_an{$_}++;
    $_ =~ /^(.*\-j)_(.*)$/;

    $is_item{$1}++;
    $is_item{$2}++;
}

# first pass through matrix, collect simple nouns and adjs
# and make a copy
open IFILE,$ifile;
open TFILE,">$tfile";
while (<IFILE>) {
    print TFILE $_;

    chomp;
    @F = split "[\t ]+",$_;
    $item = shift @F;

    if ($is_item{$item}) {
	$item_features{$item} = join "\t",@F;
    }
}
close TFILE;
close IFILE;


 
# second pass, the an vectors and print
open TFILE,$tfile;
while (<TFILE>) {
    chomp;
    @F = split "[\t ]+",$_;
    $pair = shift @F;
    if ($is_an{$pair}) {
	($adj,$noun) = ($pair=~/^(.*\-j)_(.*)$/);
	if (!($adj_features = $item_features{$adj}) || 
	    !($noun_features = $item_features{$noun})) {
	    `rm $tfile`;
	    die "no full features for pair $pair";
	}
	print $adj,"\t",$noun,"\t",$adj_features,"\t",$noun_features,"\t",
	join("\t",@F),"\n";
    }
}
close TFILE;

`rm $tfile`;
