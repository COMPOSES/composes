#!/usr/bin/perl -w


use strict "vars";
use Getopt::Std;


my $usage;
{
$usage = <<"_USAGE_";
This script takes as input a prefix string and a tuple file in (tab-
or space-delimited) format:

row-element column-element score

and creates the 2 files prefix.mat and prefix.col, where prefix is the
input prefix string (existing files with these names are deleted).

The prefix.mat file contains a matrix where each row corresponds to a
row element in the input tuples, the first field contains the row
element and all the other tab-delimited fields of the row are filled
by the scores of that row element with each of the column elements (if
a row element did not occur with a column element, the corresponding
field gets a 0 score). The prefix.col file contains the column
elements, one per line, in the order in which they are represented in
the matrix (both row and column elements are in ASCII-based dictionary
order).

Suppose for example that the file input.txt contains:

dog tail 23
cat tail 21
dog barks 15

and that we call the script as:

build_matrix_from_tuples.pl output input.txt

This will generate:

1) an output.mat file containing the following lines:

cat 0 21
dog 15 23

2) an output.col file containing the following lines:

barks
tail


Usage:

build_matrix_from_tuples.pl -h

build_matrix_from_tuples.pl prefix input


Copyright 2009, Marco Baroni

This program is free software. You may copy or redistribute it under
the same terms as Perl itself.

_USAGE_
}
{
    my $blah = 1;
# this useless block is here because here document confuses
# emacs
}

my %opts = ();

getopts('h',\%opts);

if ($opts{h}) {
    print $usage;
    exit;
}


my $prefix = shift;
my $table = shift;

my $columns = $prefix . ".col";
my $matrix = $prefix . ".mat";

if (-e $columns) {
    print STDERR "$columns already exists, deleting previous version\n";
    `rm -f $columns`;
}
if (-e $matrix) {
    print STDERR "$matrix already exists, deleting previous version\n";
    `rm -f $matrix`;
}


my %seen = ();
my @col_els = ();
my @row_els = ();
my %score_of = ();
my $row_el;
my $col_el;
my $score;
open TABLE,$table;
while (<TABLE>) {
    chomp;
    ($row_el,$col_el,$score) = split "[\t ]+",$_;
    
    if (!($seen{"col"}{$col_el}++)) {
	push @col_els,$col_el;
    }
    if (!$seen{"row"}{$row_el}++) {
	push @row_els,$row_el;
    }

    $score_of{$row_el}{$col_el} = $score;

}
close TABLE;

%seen = ();
my @sorted_col_els = sort @col_els;
@col_els = ();
my @sorted_row_els = sort @row_els;
@row_els = ();

open COLUMNS,">$columns";
foreach $col_el (@sorted_col_els) {
    print COLUMNS $col_el,"\n";
}
close COLUMNS;

open MATRIX,">$matrix";
foreach $row_el (@sorted_row_els) {
    print MATRIX $row_el;
    foreach $col_el (@sorted_col_els) {
	if (!($score = $score_of{$row_el}{$col_el})) {
	    $score = 0;
	}
	print MATRIX "\t",$score;
    }
    print MATRIX "\n";
}
close MATRIX;
