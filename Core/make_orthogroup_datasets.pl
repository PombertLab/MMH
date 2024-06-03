#!/usr/bin/env perl
## Pombert Lab, 2018

my $name = 'make_orthogroup_datasets.pl';
my $version = '0.4a';
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
SYNOPSIS    Create Fasta datasets from OrthoFinder Orthogroups output files.
            This script will split single- and multi-copy orthologs in distinct subfolders

USAGE       ${name} \\
              -f FASTA/ \\
              -t *.tsv \\
              -o ./Datasets

OPTIONS:
-f (--fasta)    Folder containing multifasta files
-t (--tsv       Orthogroups.tsv file(s) from OrthoFinder
-o (--outdir)   Output directory
-v (--version)  Show script version
OPTIONS

unless (@ARGV){
    print "\n$usage\n";
    exit(0);
};

my $folder;
my @csv;
my $odir;
my $sc_version;
GetOptions(
    'f|fasta=s' => \$folder,
    't|tsv=s@{1,}' => \@csv,
    'o|outdir=s' => \$odir,
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
## Output directory/subdirectories
###################################################################################################

my $single_og = $odir.'/SINGLE_COPY_OG';
my $multi_og = $odir.'/MULTI_COPY_OG';

my @outdirs = ($odir, $single_og, $multi_og);

for my $dir (@outdirs){
    unless (-d $dir){
        mkdir ($dir, 0755) or die "Cannot create $dir: $!\n";
    }
}

###################################################################################################
## Creating database of sequences
###################################################################################################

opendir DIR, $folder or die "Cannot open $folder: $!\n";

my %db;
my $seq;

while (my $fasta = readdir DIR){

    open FASTA, "<", "${folder}/$fasta" or die "Cannot read $fasta: $!\n";
    $fasta =~ s/\.\w+$//; 

    while (my $line = <FASTA>){

        chomp $line;

        if ($line =~ /^>(\S+)/){
            $seq = $1; ## Keeping only the first part of the header
            $db{$fasta}{$seq}[0] = $fasta;
            ## Must keep track of file names in case fasta identifiers are 
            ## identical between datatest and prevent overwrite of data...
        } 
        else{
            $db{$fasta}{$seq}[1] .= $line;
        }

    }

}

###################################################################################################
## Creating multifasta files for each orthogroup
###################################################################################################

my @OG;
my @species;

while (my $csv = shift@csv){

    open CSV, "<", $csv or die "Cannot read $csv: $!\n";
    my $basename = fileparse($csv);
    $basename = lc($basename);

    open ORT, ">", "${odir}/single_copy_$basename" or die "Cannot write to ${odir}/single_copy_$basename $!\n";
    open PAR, ">", "${odir}/multi_copy_$basename" or die "Cannot write to ${odir}/mutli_copy_$basename $!\n";
 
    my $mc = 0;
    my $sc = 0;

    while (my $line = <CSV>){

        chomp $line;

        if ($line =~ /^Orthogroup/){

            print ORT "$line\n";
            print PAR "$line\n";

            @species = split("\t", $line);
            for (1..$#species){
                print "Species # $_ = $species[$_]\n";
            }
            print "\n";

        }
        else{

            @OG = split(/\t/, $line); ## @OG -> list of orthologs, single or multicopy
            my $og = $OG[0];

            print "Working on $og...\n";

            if ($line =~ /,/){ ## Multicopy
                $mc++; $mc = sprintf("%05d", $mc);
                print PAR "MOG$mc\t$line\n";
                open OUT, ">", "$multi_og/MOG$mc.fasta"; ## MOG = Multi-copy orthogroups
                seq();
            }

            else { ## Single copy
                $sc++; $sc = sprintf("%05d", $sc);
                print ORT "SOG$sc\t$line\n";
                open OUT, ">", "$single_og/SOG$sc.fasta"; ## SOG = Single-copy orthogroups
                seq();
            }

        }

    }

}

###################################################################################################
## Subroutine(s)
###################################################################################################

## Print sequence subroutine
sub seq{ 

    for (1..$#species){

        my $organism = $species[$_];
        chomp $organism;
        my $sp = $OG[$_];
        
        my @splits;
        if ($sp){ ## Getting rid of empty columns, if any 
            @splits = split(",", $sp);
        }

        while (my $para = shift@splits){

            chomp $para;

            if ((exists $db{$organism}{$para}[0]) && ($db{$organism}{$para}[1] ne '')){

                print OUT ">$db{$organism}{$para}[0]\@$para\n";
                my @seq = unpack("(A60)*", $db{$organism}{$para}[1]);
                while (my $tmp = shift@seq){
                    print OUT "$tmp\n";
                }
            }

        }

    }

    close OUT;

}
