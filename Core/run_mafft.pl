#!/usr/bin/env perl
## Pombert Lab, 2018

my $name = 'run_mafft.pl';
my $version = '0.2';
my $updated = '2024-06-03';

use strict;
use warnings;
use Getopt::Long qw(GetOptions);

my $usage = <<"OPTIONS";
NAME        ${name}
VERSION     ${version}
UPDATED     ${updated}
SYNOPSIS    Aligns multifasta files with MAFFT (https://mafft.cbrc.jp/alignment/software/)

EXAMPLE     ${name} \\
              -f *.fasta \\
              -t 10 \\
              -q

OPTIONS:
-f (--fasta)         Multifasta files to be aligned
-t (--threads)       Number of threads [Default: 8]
-o (--op)            Gap opening penalty [Default: 1.53]
-e (--ep)            Offset (works like gap extension penalty) [Default: 0.0]
-e (--max)           Maximum number of iterative refinement [Default: 0]
-c (--clustalout)    Output: clustal format [Default: fasta]
-r (--reorder)       Reorder outorder as aligned
-q (--quiet)         Do not report progress
-v (--version)       Show script version
OPTIONS

unless (@ARGV){
    print "\n$usage\n";
    exit(0);
};

my @fasta;
my $threads = 8;
my $op = '1.53';
my $ep = '0.0';
my $max = 0;
my $clustal;
my $reorder;
my $quiet;
my $sc_version;
GetOptions(
    'f|fasta=s@{1,}' => \@fasta,
    't|threads=i'    => \$threads,
    'o|op=s' => \$op,
    'e|ep=s' => \$ep,
    'm|max' => \$max,
    'c|clustalout' => \$clustal,
    'r|reorder' => \$reorder,
    'q|quiet' => \$quiet,
    'v|version' => \$sc_version
);

###################################################################################################
## Version
###################################################################################################

if ($sc_version){
    print "\n";
    print "Script:     $name\n";
    print "Version:    $version\n";
    print "Updated:    $updated\n\n";
    exit(0);
}

###################################################################################################
## MAFFT flags
###################################################################################################

my $aln = '';
if ($clustal){
    $aln = '--clustalout';
}

my $rr = '';
if ($reorder){
    $rr = '--reorder';
}

my $qt = '';
if ($quiet){
    $qt = '--quiet';
}

###################################################################################################
## Running MAFFT
###################################################################################################

while (my $fasta = shift@fasta) {

    my $out = $fasta;
    $out =~ s/\.\w+$//;

    print "Aligning $fasta...\n";

    system ("
        mafft \\
          --op $op \\
          --ep $ep \\
          --maxiterate $max \\
          $qt \\
          $rr \\
          $aln \\
          --thread $threads \\
          $fasta \\
          > $out.aln
    ") == 0 or checksig();

}

###################################################################################################
## Subroutine(s)
###################################################################################################

sub checksig {

    my $exit_code = $?;
    my $modulo = $exit_code % 255;

    print "\nExit code = $exit_code; modulo = $modulo \n";

    if ($modulo == 2) {
        print "\nSIGINT detected: Ctrl+C => exiting...\n";
        exit(2);
    }
    elsif ($modulo == 131) {
        print "\nSIGTERM detected: Ctrl+\\ => exiting...\n";
        exit(131);
    }

}