#!/usr/bin/perl -w

use strict "vars";
use Getopt::Std;
use String::Random qw(random_string);

my $usage;
{
$usage = <<"_USAGE_";

This script assumes an input co-occurrence matrix in (space- or
tab-delimited) format

element1 value1 value2 ... valueN
...
elementN value1 value2 ... valueN

The script applies SVD to the matrix, and returns a matrix in the same
format, but where the dimensions are replaced by the top s right
singular vectors or "latent dimensions" and the corresponding values
in each row are the projections of the corresponding elements on the
latent dimensions (s is 300 by default, or use the -s option).

The script calls the svd command-line program of the SVDLIBC toolkit
(http://tedlab.mit.edu/~dr/SVDLIBC/), that must thus be installed
before running the script.

If the option -d string is passed, the script also creates a
directory, named string, where it leaves the SVD singular vector and
value matrices.

NB: If no option -d is passed, The script creates a randomly named
directory that it deletes at the end of the operations; if it dies
before being done it will not clean it up.

The following parameters/options can be specified:

-c: center row vectors before applying SVD

-d string: leave SVD matrices in directory string (default: create
 temp directory and delete it at the end)

-h: print this documentation and exit

-s: singular vectors to be preserved (default: 300)

Usage examples:

svd_matrix_transformer.pl inmatrix > outmatrix

svd_matrix_transformer.pl -d svdout inmatrix > outmatrix

svd_matrix_transformer.pl -s100 inmatrix > outmatrix

svd_matrix_transformer.pl -c -s100 inmatrix > outmatrix

svd_matrix_transformer.pl -d svdout -s100 inmatrix > outmatrix

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

##################### initializing parameters #####################


my %opts = ();

getopts('cd:hs:',\%opts);

if ($opts{h}) {
    print $usage;
    exit;
}

# by default we keep 300 sing values and vectors
my $max_sing_val = 300;
if ($opts{s}) {
    $max_sing_val = $opts{s};
}

# out dir requested?
my $dir;
my $dir_is_temp = 1;
if ($opts{d}) {
    $dir = $opts{d};
    if (-e $dir) {
	die "directory $dir already exists";
    }
    $dir_is_temp = 0;
}
# not requested? then we create a temp dir
else {
    $dir = random_string("cccccccccccccccccccc");
    # if that dir already exists (unlikely!) we try with another random
    # name
    while (-e $dir) {
	$dir = random_string("cccccccccccccccccccc");
    }
}

`mkdir $dir`;


my $input_matrix = shift
    or die "no input matrix specified";


##################### average row vector (if -c) #####################

# we traverse the input matrix one to collect the column sums and then
# average

# number of rows
my $m = 0;
my @average_row_vector_values = ();

# if no centering option, collect by wc, otherwise we might as well
# count while traversing the matrix a first time
if (!defined($opts{c})) {
    $m = `wc $input_matrix`;
    chomp $m;
    $m =~ s/^[ \t]*([0-9]+).*$/$1/;
}
else { # i.e., we need to center: traverse matrix, sum and then
       # average!

    print STDERR "computing average vector for centering\n";

    open INMATRIX,$input_matrix 
	or die "could not open input file $input_matrix";
    while (<INMATRIX>) {
	chomp;
	s/\r//g;
	my @F = split "[\t ]+",$_;
	# first el is label
	shift @F;
	# traverse vector, and add each element to the corresponding
	# dimension of average
	my $dimension_counter = 0;
	while ($dimension_counter<=$#F) {
	    $average_row_vector_values[$dimension_counter] += 
		$F[$dimension_counter];
	    $dimension_counter++;
	}

	# increase line counter
	$m++;

    }
    close INMATRIX;

    # now, let's divide average vector by number of rows
    my $dimension_counter = 0;
    while ($dimension_counter<=$#average_row_vector_values) {
	$average_row_vector_values[$dimension_counter] = 
	    $average_row_vector_values[$dimension_counter]/$m;
	$dimension_counter++;
    }
}

##################### converting the input  matrix #####################

print STDERR "now preparing the input matrix in SVDLIBC format\n";

my $matrix = "$dir/in_mat";
my @input_row_elements = ();


# we will count the number of columns on the first input line
my $is_first_line = 1;
open INMATRIX,$input_matrix 
    or die "could not open input file $input_matrix";
open MATRIX,">$matrix";
while (<INMATRIX>) {
    chomp;
    s/\r//g;
    my @F = split "[\t ]+",$_;
    push @input_row_elements,shift @F;
    if ($is_first_line) {
	$is_first_line = 0;
	# print number of rows and columns
	print MATRIX $m, " ", $#F+1, "\n";
    }
    # if option -c, center, otherwise print as is
    if ($opts{c}) {
	my $dimension_counter = 0;
	while ($dimension_counter <= $#F) {
	    $F[$dimension_counter] = $F[$dimension_counter] - 
		$average_row_vector_values[$dimension_counter];
	    $dimension_counter++;
	}
    }

    print MATRIX join " ",@F;
    print MATRIX "\n";
}
close INMATRIX;
close MATRIX;

# just in case, empty average vector
@average_row_vector_values = ();

print STDERR "building the sparse matrix\n";

my $sparse_matrix = "$dir/sparse_in_matrix";
`svd -r dt -w st -c $matrix $sparse_matrix`;

# converted input mat is no longer needed
`rm -f $matrix`;

print STDERR "sparse input matrix ready\n";


##################### performing SVD #####################

print STDERR "performing svd\n";

my $svd_prefix = "$dir/svd_out";
`svd  -d $max_sing_val -o $svd_prefix $sparse_matrix`;

# sparse matrix no longer needed
`rm -f $sparse_matrix`;

print STDERR "svd done\n";

##################### processing output of SVD #####################

print STDERR "now processing output of SVD\n";

# if everythning worked correctly, the svd program should have generated
# 3 files:

# svd_prefix-Ut has the transpose of U, i.e., each _row_ contains the
# left singular vectors (this is in the same dense format as the input
# dense matrix generated above)

# svd_prefix-St has the singular values, one per line, preceded by a line
# with the total number of values

# svd_prefix-Vt is the transpose of V, i.e., each row contains the right singular vectors (same format as the -Ut matrix), that we ignore here

my $singval_filename = $svd_prefix . "-S";
my $transposed_left_singvec_filename = $svd_prefix . "-Ut";

print STDERR "reading singular values\n";

# we read the singular value file
open VALFILE,$singval_filename or
    die "could not open file $singval_filename";
# variables used to deal with singvals
my $line = 0;
my @singvals = ();
while (<VALFILE>) {
    chomp;
    $line++;
    # first line has number of singular values, that we do not need
    # but it should be equal to number of requested singular
    # values
    if ($line ==1) {
	if ($_!=$max_sing_val) {
	    die "$max_sing_val requested, $_ obtained";
	}
	next;
    }
    
    push @singvals, $_;
}
close VALFILE;

print STDERR "reading left singular vectors and generating output\n";
# note that the left sing vect matrix is transposed, so each row is a
# sing vec, and we should have gotten as many sing vectors (rows) as
# singular values

# for each row, after scalar multiplication by the corresponding
# singular value, we print the corresponding output lines, i.e.,
# for each input row element (as stored in the correspodning array)
# its value on the current dimension)

my %reduced_values_of = ();

open LVECFILE,$transposed_left_singvec_filename or
    die "could not open file $transposed_left_singvec_filename";
$line = 0; # reset line counter
while (<LVECFILE>) {
    $line++;
    # first line has numRows numCols
    if ($line == 1) {
	next;
    }
    my @vec_elements = ();

    # foreach element, we multiply by singular value of current sing
    # vec, and we generate an output line for "co-occurrence" of
    # corresponding input row element with current scaled sinv vec
    @vec_elements = split("[ \t]+",$_);
    my $i = 0;
    foreach my $element (@vec_elements) {
	my $scaled = $element * $singvals[$line-2];
	push @{$reduced_values_of{$input_row_elements[$i]}},$scaled;
	$i++;
    }
}
close LVECFILE;

# printing the new matrix
foreach my $row_item (@input_row_elements) {
    print $row_item;
    foreach my $value (@{$reduced_values_of{$row_item}}) {
	printf ("\t%.4f", $value);
    }
    print "\n";
}
close LVECFILE;

# if it was temp dir, we remove it
if ($dir_is_temp) {
    `rm -fr $dir`;
}

print STDERR "done!\n";
