#!/usr/bin/perl
## Pombert Lab, 2018
my $name = 'run_mafft.pl';
my $version = 0.1;
my $updated = '03/03/2021';

use strict; use warnings; use Getopt::Long qw(GetOptions);

my $usage = <<"OPTIONS";
NAME		${name}
VERSION		${version}
UPDATED		${updated}
SYNOPSIS	Aligns multifasta files with MAFFT (https://mafft.cbrc.jp/alignment/software/)

EXAMPLE		${name} -f *.fasta -t 10 -q

OPTIONS:
-f (--fasta)		Multifasta files to be aligned
-t (--thread)		Number of threads, default: 8
-o (--op)		Gap opening penalty, default: 1.53
-e (--ep)		Offset (works like gap extension penalty), default: 0.0
-e (--max)		Maximum number of iterative refinement, default: 0
-c (--clustalout)	Output: clustal format, default: fasta
-r (--reorder)		Outorder: aligned, default: input order
-q (--quiet)		Do not report progress
OPTIONS
die "\n$usage\n" unless @ARGV;

my @fasta;
my $thread = 8;
my $op = '1.53';
my $ep = '0.0';
my $max = 0;
my $clustal;
my $reorder;
my $quiet;
GetOptions(
	'f|fasta=s@{1,}' => \@fasta,
	't|thread=i'	=> \$thread,
	'o|op=s' => \$op,
	'e|ep=s' => \$ep,
	'm|max' => \$max,
	'c|clustalout' => \$clustal,
	'r|reorder' => \$reorder,
	'q|quiet' => \$quiet
);

my $aln = ''; if ($clustal){$aln = '--clustalout';}
my $rr = ''; if ($reorder){$rr = '--reorder';}
my $qt = ''; if ($quiet){$qt = '--quiet';}

while (my $fasta = shift@fasta) {
	my $out = $fasta; $out =~ s/(.fasta|.fa|.fsa|.faa|.fna)$//;
	print "Aligning $fasta...\n";
	system "mafft --op $op --ep $ep --maxiterate $max $qt $rr $aln --thread $thread $fasta > $out.aln";
}

exit;
