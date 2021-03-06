#!/usr/bin/perl
## Pombert Lab, 2018
my $name = 'parse_hmmtbl.pl';
my $version = '0.3';
my $updated = '2021-06-02';

use strict; use warnings; use Getopt::Long qw (GetOptions);

my $usage = <<"OPTIONS";
NAME		${name}
VERSION		${version}
UPDATED		${updated}
SYNOPSIS	Parses the output of hmmsearch into a concise, tab-delimited format

USAGE		${name} \\
		  -tbl *.hmm.*.tbl \\
		  -out hmmtable.tsv

OPTIONS:
-t (--tbl)	TBL files generated by run_hmmsearch.pl
-o (--out)	Output table name [Default = hmmtable.tsv]
OPTIONS
die "\n$usage\n" unless @ARGV;

## Defining GetOptions() variables
my @tbl;
my $table = 'hmmtable.tsv';
GetOptions(
	't|tbl=s@{1,}' => \@tbl,
	'o|out=s' => \$table
);

## Print table header
open OUT, ">", "$table" or die "Can't create file $table: $!\n";
my $hflag = 0;

## Parsing files
while (my $file = shift@tbl){
	open IN, "<", "$file" or die "Can't read file $file: $!\n";
		while (my $line = <IN>){
		chomp $line;
		if ($line =~ /^#/){ next; } ## Skipping comments 
		else {
			## File format is space separated, must use a regex...
			my @columns = split (/\s+/, $line);
		
			my $target = $columns[0];
			my $taccession = $columns[1];
			my $query = $columns[2];
			my $qaccession = $columns[3];
			my $fevalue = $columns[4];
			my $fscore = $columns[5];
			my $fbias = $columns[6];
			my $devalue = $columns[7];
			my $dscore = $columns[8];
			my $dbias = $columns[9];
			## 10-17 domain number estimation

			my $description;
			for my $num (18..$#columns){
				$description .= "$columns[$num] ";
			}

			if ($description =~ /(.*)\sOS=(.*?)(?:OX|GN|PE|SV)=/){
				my $product = $1;
				my $OS = $2;
				my ($species,$genus) = $OS =~ /^((\S+)\s+\S+)/;
				if ($hflag == 0){
					print OUT "Query\tTarget\tE-value\tProduct\tGenus\tSpecies\tOS descriptor\n";
					$hflag = 1;
				}
				print OUT "$query\t$target\t$fevalue\t$product\t$genus\t$species\t$OS\n";
			}
			else {
				if ($hflag == 0){
					print OUT "Query\tTarget\tE-value\tDescription\n";
					$hflag = 1;
				}
				print OUT "$query\t$target\t$fevalue\t$description\n";
			}
		}
	}
}
