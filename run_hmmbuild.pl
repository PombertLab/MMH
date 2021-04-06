#!/usr/bin/perl
## Pombert Lab, 2018
my $name = 'run_hmmbuild.pl';
my $version = '0.1';
my $updated = '2021-03-03';

use strict; use warnings; use Getopt::Long qw(GetOptions);

my $usage = <<"OPTIONS";
NAME		${name}
VERSION 	${version}
UPDATED		${updated}
SYNOPSIS	This script generates a hidden Markov model for each alignment provided in Multifasta format.
REQUIREMENTS	hmmbuild from the HMMER package (http://hmmer.org/).

USAGE		${name} -a *.aln

OPTIONS:
-a (--align)	Alignments files in FASTA format
OPTIONS
die "\n$usage\n" unless @ARGV;

my @alignments;
GetOptions(
	'a|align=s@{1,}' => \@alignments
);

while (my $file = shift@alignments){
	system "hmmbuild $file.hmm $file";
}