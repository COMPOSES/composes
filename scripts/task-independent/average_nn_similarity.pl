#!/opt/perl/bin/perl -w

use strict "vars";
use PDL;
use Getopt::Std;

my $usage;
{
$usage = <<"_USAGE_";

This script takes as inputs

- a (tab- or space-delimited) list with a target element in the first
field, a neighbour in the second field and possibly other fields that
will be ignored;

- a matrix with word/phrase labels in the first column, and values for
the distributional vector representing each word/phrase in the other
columns.

The script computes the pairwise cosines of the neighbours of the same
target in the first list based on their representation in the matrix,
and returns, for each target, the average of these cosines. If a
neighbour is not represented in the matrix, it\'s cosine with any
other neigbour is taken to be 0.

The output file has two tab-delimited fields, containing each target
and the corresponding neighbour average cosines.

The script requires the PDL module to be installed.

Usage:

average_nn_similarity.pl -h

average_nn_similarity.pl nn-list matrix

Copyright 2011, Marco Baroni

This program is free software. You may copy or redistribute it under
the same terms as Perl itself.

_USAGE_
}
{
    my $blah = 1;
# this useless block is here because here document confuses
# emacs
}


## processing input options

my %opts = ();

getopts('h',\%opts);

if ($opts{h}) {
    print $usage;
    exit;
}


## processing input arguments

my $target_list = shift;
my $matrix = shift;


# global variables
# an empty hash to collect the neighbours specific to a target
my %neighbours_of = ();
# another empty hash to collect all neighbours
my %all_neighbours = ();
# another empty hash to collect the vectors of the neighbours
my %vectors = ();
# an empty hash to hold cosines so we avoid having to recompute them
my %cosines = ();



print STDERR "average_nn_similarity.pl: reading target-neighbour list\n";
# we traverse the target-neighbour list, collecting all neighbours of
# a target
open TARGETS,$target_list;
while (<TARGETS>) {
  chomp;
  s/\r//;

  my @F = split "[\t ]",$_;
  push @{$neighbours_of{$F[0]}},$F[1];
  $all_neighbours{$F[1]} = 1;
}
close TARGETS;

print STDERR "average_nn_similarity.pl: reading neighbour vectors\n";
# now we traverse the matrix to store the normalized vectors of all
# neighbours and precompute their lengths
open MATRIX,$matrix;
while (<MATRIX>) {
  chomp;
  s/\r//;

  my @F = split "[\t ]",$_;
  my $term = shift @F;

  # ignore rows for terms that are not neighbours of one of our
  # targets
  if (!($all_neighbours{$term})) {
    next;
  }

  my $temp_raw =  pdl @F;
  my $temp_length = sqrt(sum($temp_raw**2));
  # we treat 0 vectors as unseen terms
  if ($temp_length != 0) {
      $vectors{$term} =  $temp_raw / $temp_length;
  }
  undef($temp_raw);
  @F = ();
}
close MATRIX;

# we no longer need the %all_neighbours hash
%all_neighbours = ();

print STDERR "average_nn_similarity.pl: computing average neighbour cosines and printing\n";
# now we traverse the list of targets, and for each we compute the
# quantity of interest
foreach my $target (keys %neighbours_of) {
  # traverse all neighbours and sum their cosines

  my $neighbour_count = 0;
  my $cosine = 0;

  my $i = 0;
  while ($i< $#{$neighbours_of{$target}}) {
    my $j = $i + 1;
    while ($j<= $#{$neighbours_of{$target}}) {

      $neighbour_count++;

      my ($first_term,$second_term) = 
	sort ($neighbours_of{$target}[$i],$neighbours_of{$target}[$j]);


      # have we already stored this cosine?
      if (defined($cosines{$first_term}{$second_term})) {
	  $cosine += $cosines{$first_term}{$second_term};
      }
      else {
	  # cosine is not 0 only if both terms have non-0 vectors
	  my $curr_cosine = 0;
	  if (defined($vectors{$first_term}) && 
	      defined($vectors{$second_term})) {
	      $curr_cosine = sum($vectors{$first_term}*$vectors{$second_term});
	  }
	  # sum to cumulative neighbour cosines
	  $cosine += $curr_cosine;
	  # add cosine to list of seen cosines
	  $cosines{$first_term}{$second_term} = $curr_cosine;
      }
      #printf("%s\t%s\t%.5f\n",$first_term,$second_term,$cosines{$first_term}{$second_term});
      $j++;
    }
    $i++;
  }

  # $cosine could be 0 because a target had one neighbour only, to
  # avoid divisions-by-0 errors we consider this possibility...
  if ($cosine != 0) {
      $cosine /= $neighbour_count;
  }
  # print current target and its average cosine
  printf("%s\t%.5f\n",$target,$cosine);
}


print STDERR "average_nn_similarity.pl: ALL DONE\n";
