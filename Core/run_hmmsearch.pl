#!/usr/bin/env perl
## Pombert Lab, 2019

my $name = 'run_hmmsearch.pl';
my $version = '0.3';
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
SYNOPSIS    Searches HMM profiles against proteins from known databases (e.g. SwissProt or trEMBL) in fasta format

USAGE       ${name} \\
              -h *.hmm \\
              -f *.fasta \\
              -t 10 \\
              -e 1e-10 \\
              -log

OPTIONS:
-h (--hmm)       HMM file(s) to query
-f (--fasta)     Fasta file(s) to search against
-o (--outdir)    Output directory [Default: ./]
-t (--threads)   Number of threads to use [Default: 8]
-e (--evalue)    E-value cutoff [Default: 1e-10]
-l (--log)       Redirect hmmsearch standard output(s) to log file(s)
-n (--noali)     Don't output alignments, so output is smaller
-v (--version)   Show script version
OPTIONS

unless (@ARGV){
    print "\n$usage\n";
    exit(0);
};

my @fasta;
my @hmm;
my $outdir = './';
my $threads = 8;
my $evalue = '1e-10';
my $log;
my $noali;
my $sc_version;
GetOptions(
    'f|fasta=s@{1,}' => \@fasta,
    'h|hmm=s@{1,}' => \@hmm,
    'o|outdir=s' => \$outdir,
    't|threads=i' => \$threads,
    'e|evalue=s' => \$evalue,
    'l|log' => \$log,
    'n|noali' => \$noali,
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
## Log
###################################################################################################

my $dbnum = scalar(@fasta); my $hmm_num = scalar(@hmm);
my $start = localtime(); my $tstart = time;

open LOG, ">", "$outdir/hmmsearch.log";
print LOG "HMM search(es) started on: $start\n";
print LOG "# of HMM motif to search: $hmm_num\n";
print LOG "# of databases to search: $dbnum\n";

###################################################################################################
## Running HMM searches
###################################################################################################

my $dbcount = 0;

while (my $fasta = shift@fasta){

    $dbcount++;
    print LOG "DB #$dbcount = $fasta\n";

    my $db;

    if ($fasta =~ /(sprot|trembl|ncbi)/i){
        $db = $1;
    }
    else{
        $db = "DB$dbcount";
    }

    foreach my $hmm (@hmm){

        print "Searching $hmm against $fasta...\n";
        my ($basename) = fileparse($hmm);
        my $tbl = "$outdir/$basename.$db.tbl";

        ## With alignments
        unless ($noali){
            if ($log){
                system ("
                    hmmsearch \\
                      --cpu $threads \\
                      -E $evalue \\
                      --tblout $tbl \\
                      $hmm \\
                      $fasta \\
                      >> $outdir/hmm.$db.log
                ") == 0 or checksig();
            }
            else{
                system ("
                    hmmsearch \\
                      --cpu $threads \\
                      -E $evalue \\
                      --tblout $tbl \\
                      $hmm \\
                      $fasta
                ") == 0 or checksig();
            }
        }

        ## Without alignments
        else{
            if ($log){
                system ("
                    hmmsearch \\
                      --cpu $threads \\
                      -E $evalue \\
                      --noali \\
                      --tblout $tbl \\
                      $hmm \\
                      $fasta \\
                      >> $outdir/hmm.$db.log
                ") == 0 or checksig();
            }
            else{
                system ("
                    hmmsearch \\
                      --cpu $threads \\
                      -E $evalue \\
                      --noali \\
                      --tblout $tbl \\
                      $hmm \\
                      $fasta
                ") == 0 or checksig();
            }
        }
    }
}

###################################################################################################
## Completion
###################################################################################################

my $end = localtime();
my $time_taken = time - $tstart;
print LOG "HMM search(es) ended on: $end\nTime elapsed: $time_taken seconds\n";

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