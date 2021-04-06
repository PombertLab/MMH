#!/usr/bin/perl
## Pombert Lab, 2019
my $name = 'run_hmmsearch.pl';
my $version = '0.2b';
my $updated = '2021-04-06';

use strict; use warnings; use Getopt::Long qw(GetOptions);

my $usage = <<"OPTIONS";
NAME		${name}
VERSION		${version}
UPDATED		${updated}
SYNOPSIS	Searches HMM profiles against proteins from known databases (e.g. SwissProt or trEMBL) in fasta format

USAGE		${name} \\
		  -h *.hmm \\
		  -f *.fasta \\
		  -t 10 \\
		  -e 1e-10 \\
		  -log

OPTIONS:
-h (--hmm)	HMM file(s) to query
-f (--fasta)	Fasta file(s) to search against
-t (--thread)	Number of threads to use [Default: 8]
-e (--evalue)	E-value cutoff [Default: 1e-10]
-l (--log)	Redirect hmmsearch standard output(s) to log file(s)
-n (--noali)	Don't output alignments, so output is smaller
OPTIONS
die "\n$usage\n" unless @ARGV;

my @fasta;
my @hmm;
my $threads = 8;
my $evalue = '1e-10';
my $log;
my $noali;
GetOptions(
	'f|fasta=s@{1,}' => \@fasta,
	'h|hmm=s@{1,}' => \@hmm,
	't|thread=i' => \$threads,
	'e|evalue=s' => \$evalue,
	'l|log' => \$log,
	'n|noali' => \$noali
);
## Printing LOG info
my $dbnum = scalar(@fasta); my $hmm_num = scalar(@hmm);
my $start = localtime(); my $tstart = time;
open LOG, ">", "hmmsearch.log";
print LOG "HMM search(es) started on: $start\n";
print LOG "# of HMM motif to search: $hmm_num\n";
print LOG "# of databases to search: $dbnum\n";

## Running HMM searches
my $dbcount = 0;
while (my $fasta = shift@fasta){

	$dbcount++; print LOG "DB #$dbcount = $fasta\n";
	my $db;
	if ($fasta =~ /(sprot|trembl|ncbi)/i){ $db = $1; }
	else{ $db = "DB$dbcount"; }

	foreach my $hmm (@hmm){
		print "Searching $hmm against $fasta...\n";

		## With alignments
		unless ($noali){
			if ($log){
				system "hmmsearch \\
				  --cpu $threads \\
				  -E $evalue \\
				  --tblout $hmm.$db.tbl \\
				  $hmm \\
				  $fasta \\
				  >> hmm.$db.log";
			}
			else{
				system "hmmsearch \\
				  --cpu $threads \\
				  -E $evalue \\
				  --tblout $hmm.$db.tbl \\
				  $hmm \\
				  $fasta";
			}
		}

		## Without alignments
		else{
			if ($log){
				system "hmmsearch \\
				  --cpu $threads \\
				  -E $evalue \\
				  --noali \\
				  --tblout $hmm.$db.tbl \\
				  $hmm $fasta \\
				  >> hmm.$db.log";
			}
			else{
				system "hmmsearch \\
				  --cpu $threads \\
				  -E $evalue \\
				  --noali \\
				  --tblout $hmm.$db.tbl \\
				  $hmm \\
				  $fasta";
			}
		}
	}
}
my $end = localtime();
my $time_taken = time - $tstart;
print LOG "HMM search(es) ended on: $end\nTime elapsed: $time_taken seconds\n";
print "Job done; see hmmsearch.log for details...\n";