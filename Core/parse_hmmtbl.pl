#!/usr/bin/env perl
## Pombert Lab, 2018

my $name = 'parse_hmmtbl.pl';
my $version = '0.3a';
my $updated = '2024-06-03';

use strict;
use warnings;
use Getopt::Long qw (GetOptions);

###################################################################################################
## Command line options
###################################################################################################

my $usage = <<"OPTIONS";
NAME        ${name}
VERSION     ${version}
UPDATED     ${updated}
SYNOPSIS    Parses the output of hmmsearch into a concise, tab-delimited format

USAGE       ${name} \\
              -tbl *.hmm.*.tbl \\
              -out hmmtable.tsv

OPTIONS:
-t (--tbl)         TBL files generated by run_hmmsearch.pl
-o (--out)         Output table name [Default = hmmtable.tsv]
-v (--version)     Show script version
OPTIONS

unless (@ARGV){
    print "\n$usage\n";
    exit(0);
};


my @tbl;
my $table = 'hmmtable.tsv';
my $sc_version;
GetOptions(
    't|tbl=s@{1,}' => \@tbl,
    'o|out=s' => \$table,
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
## Parsing files
###################################################################################################

open OUT, ">", $table or die "Can't create file $table: $!\n";
my $hflag = 0;

while (my $file = shift@tbl){

    open IN, "<", $file or die "Can't read file $file: $!\n";

        while (my $line = <IN>){

            chomp $line;

            if ($line =~ /^#/){  ## Skipping comments 
                next;
            }

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

                    # In case species info is missing
                    if (!defined $species){
                        $species = 'n/a';
                    }
                    if (!defined $genus){
                        $genus = 'n/a';
                    }

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
