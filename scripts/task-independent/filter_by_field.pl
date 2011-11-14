#!/usr/bin/perl

use Getopt::Std;

{
$usage = <<"_USAGE_";

Usage:

filter_by_field.pl [-s] [-fN] target_list to_be_filtered > filtered
filtered_by_field.pl -h

- target_list is in one-string per line format;

- to_be_filtered is a list where each line has the same number of
  fields (space or tab delimited).

The script keeps only those lines of to_be_filtered where the element
in field N (1 by default, or specified by -f option) is identical to
(or, if -s option is passed, is NOT identical to) one of the strings
in target_list.

This script is free software. You may copy or redistribute it under
the same terms as Perl itself.
    
_USAGE_
}

{
    my $blah = 1;
# this useless block is here because here document confuses
# emacs
}

%opts = ();
getopts('sf:h',\%opts);

if ($opts{h}) {
    print $usage;
    exit;
}

$stop_op = 0;
if ($opts{s}) {
  $stop_op = 1;
}

$target_field = 0;
if ($opts{f}) {
    $target_field = $opts{f} - 1;
}

if (!(open WLIST, shift)) {
    print $usage;
    exit;
}
while (<WLIST>) {
    chomp;
    s/\r//g;
    $in{$_} = 1;
}
close WLIST;

if (!(open ULIST, shift)) {
    print $usage;
    exit;
}
while (<ULIST>) {
    $input = $_;
    chomp;
    s/\r//g;
    @F = split "[\t ]",$_;
    if ($stop_op) {
	if ($in{$F[$target_field]}) {
	    next;
	}
    }
    else {
	if (!$in{$F[$target_field]}) {
	    next;
	}
    }
    print $input;
}
close ULIST;
