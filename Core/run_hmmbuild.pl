#!/usr/bin/env perl
## Pombert Lab, 2018

my $name = 'run_hmmbuild.pl';
my $version = '0.2';
my $updated = '2024-06-03';

use strict;
use warnings;
use Getopt::Long qw(GetOptions);
use File::Basename;

###################################################################################################
## Command line options
###################################################################################################

my $usage = <<"OPTIONS";
NAME        ${name}
VERSION     ${version}
UPDATED     ${updated}
SYNOPSIS    This script generates a hidden Markov model for each alignment provided in Multifasta format.

REQS        hmmbuild from the HMMER package - http://hmmer.org/

USAGE       ${name} -a *.aln

OPTIONS:
-a (--align)    Alignments files in FASTA format
-o (--outdir)   Output directory [Default: ./]
-v (--version)  Show script version
OPTIONS

unless (@ARGV){
    print "\n$usage\n";
    exit(0);
};

my @alignments;
my $outdir = './';
my $sc_version;
GetOptions(
    'a|align=s@{1,}' => \@alignments,
    'o|outdir=s' => \$outdir,
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
## Running hmmbuild
###################################################################################################

while (my $file = shift @alignments){

    my $basename = fileparse($file);
    my $prefix = $basename;
    $prefix =~ s/\.\w+$//;

    print "Building $prefix.hmm with hmmbuild\n";

    system ("
        hmmbuild \\
          -o /dev/null \\
          $outdir/$prefix.hmm \\
          $file
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