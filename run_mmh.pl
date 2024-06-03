#!/usr/bin/env perl
# Pombert lab, 2024

my $name = 'run_mmh.pl';
my $version = '0.1a';
my $updated = '2024-06-03';

use strict;
use warnings;
use Getopt::Long qw(GetOptions);
use File::Basename;
use Cwd qw(abs_path);
use File::Path qw(make_path);

###################################################################################################
## Command line options
###################################################################################################

my $usage = <<"EXIT";
NAME        ${name}
VERSION     ${version}
UPDATED     ${updated}
SYNOPSIS    Runs the MMH pipeline

REQS        OrthoFinder - https://github.com/davidemms/OrthoFinder
            Diamond - https://github.com/bbuchfink/diamond
            MAFFT - https://mafft.cbrc.jp/alignment/software/
            HMMER - http://hmmer.org/

USAGE       ${name} \\
              --fasta ./FASTA \\
              --outdir ./MMH \\
              --db swiss \\
              --dbloc ~/UniProt

OPTIONS:
-f (--fasta)        Directory containing fasta files to create HMM models from
-o (--outdir)       Output directory [Default: MMH]
-d (--db)           Databases to query: swiss, trembl, or both [Default: swiss]
-l (--dbloc)        Databases location
-t (--threads)      Number of threads to use [Default: 16]
-e (--evalue)       HMM search evalue cutoff [Default: 1e-10]
-v (--version)      Show script version
EXIT

unless (@ARGV){
    print "\n$usage\n";
    exit(0);
};

my @commands = @ARGV;

my $fasta_dir;
my $outdir = 'MMH';
my $db = 'swiss';
my $dbloc = '';
my $threads = 16;
my $evalue = '1e-10';
my $sc_version;
GetOptions(
    'f|fasta=s' => \$fasta_dir,
    'o|outdir=s' => \$outdir,
    'd|db=s' => \$db,
    'l|dbloc=s' => \$dbloc,
    't|threads=i' => \$threads,
    'e|evalue=s' => \$evalue,
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
## Output directory creation and setup
###################################################################################################

unless (-d $outdir){
    make_path($outdir,{mode=>0755}) or die "Can't create $outdir: $!\n";
}


###################################################################################################
## Log
###################################################################################################

my $log_file = $outdir.'/'.'mmh.log';
open LOG, '>', $log_file or die "Can't create $log_file: $!\n";

my $time = localtime();
my $start_time = time();
my $tstart = time();

print LOG "MMH started on: ".$time."\n\n";
logs(\*LOG, 'Command line', 'header');

print LOG "$0 @commands\n\n";
logs(\*LOG, 'Runtime', 'header');

###################################################################################################
## Grabbing $path location from script
###################################################################################################

my ($script,$path) = fileparse($0);
my $core = $path.'/Core';

###################################################################################################
## Checking dependencies
###################################################################################################

# OrthoFinder
my $ortho_check = `echo \$(command -v orthofinder.py)`;
chomp $ortho_check;

if ($ortho_check eq ''){
    print STDERR "\n";
    print STDERR "[E]: Cannot find orthofinder.py. Please install it in your \$PATH.\n";
    print STDERR "[E]: Exiting..\n\n";
    exit(1);
}

# Diamond
my $diamond_check = `echo \$(command -v diamond)`;
chomp $diamond_check;
if ($diamond_check eq ''){
    print STDERR "\n";
    print STDERR "\n[E]: Cannot find diamond. Please install it in your \$PATH.\n";
    print STDERR "[E]: Exiting..\n\n";
    exit(1);
}

# MAFFT
my $mafft_check = `echo \$(command -v mafft)`;
chomp $mafft_check;
if ($mafft_check eq ''){
    print STDERR "\n";
    print STDERR "[E]: Cannot find mafft. Please install it in your \$PATH.\n";
    print STDERR "[E]: Exiting..\n\n";
    exit(1);
}

# HMMER
my $hmmer_check = `echo \$(command -v hmmbuild)`;
chomp $hmmer_check;
if ($hmmer_check eq ''){
    print STDERR "\n";
    print STDERR "[E]: Cannot find hmmbuild. Please install HMMER in your \$PATH.\n";
    print STDERR "[E]: Exiting..\n\n";
    exit(1);
}

###################################################################################################
## Running OrthoFinder
###################################################################################################

my $ortho_dir = $outdir.'/OrthoFinder';

logs(\*LOG, 'OrthoFinder', 'start');

if (-d $ortho_dir){
    system ("rm -R $ortho_dir");
}

print "\n"."### Finding orthogroups with OrthoFinder\n\n";

system ("
    orthofinder.py \\
      -t $threads \\
      -f $fasta_dir \\
      -S diamond \\
      -o $ortho_dir
");

logs(\*LOG, 'OrthoFinder', 'end');

###################################################################################################
## Creating Orthogroup datasets
###################################################################################################

my $tsv_file = `find $ortho_dir -name Orthogroups.tsv`;
chomp $tsv_file;

my $dataset_dir = $outdir.'/Datasets';

print "\n"."### Creating orthogroup datasets\n\n";
logs(\*LOG, 'make_orthogroup_datasets.pl', 'start');

system ("
    $core/make_orthogroup_datasets.pl \\
      -f $fasta_dir \\
      -t $tsv_file \\
      -o $dataset_dir
");

logs(\*LOG, 'make_orthogroup_datasets.pl', 'end');

###################################################################################################
## Aligning orthogroup datasets
###################################################################################################

my $sogdir = $dataset_dir.'/SINGLE_COPY_OG';
my $mogdir = $dataset_dir.'/MULTI_COPY_OG';

logs(\*LOG, 'run_mafft.pl', 'start');

# single copy
my @sog_fasta = ();

opendir (SOGDIR, $sogdir) or die "\n\n[ERROR]\tCan't open $sogdir: $!\n\n";
while (my $file = readdir(SOGDIR)){
	if ($file =~ /\.fasta$/){
		my $fasta_file = "$sogdir/$file";
		push (@sog_fasta, $fasta_file);
	}
}
closedir SOGDIR;

if (scalar(@sog_fasta) >= 1){

    print "\n"."### Aligning single copy orthogroups with MAFFT\n\n";

    system ("
        $core/run_mafft.pl \\
        --quiet \\
        -t $threads \\
        -f $sogdir/*.fasta
    ");

}

# multicopy
my @mog_fasta = ();

opendir (MOGDIR, $mogdir) or die "\n\n[ERROR]\tCan't open $mogdir: $!\n\n";
while (my $file = readdir(MOGDIR)){
	if ($file =~ /\.fasta$/){
		my $fasta_file = "$mogdir/$file";
		push (@mog_fasta, $fasta_file);
	}
}
closedir MOGDIR;

if (scalar(@mog_fasta) >= 1){

    print "\n"."### Aligning multicopy orthogroups with MAFFT\n\n";

    system ("
        $core/run_mafft.pl \\
        --quiet \\
        -t $threads \\
        -f $mogdir/*.fasta \\
    ");

}

logs(\*LOG, 'run_mafft.pl', 'end');

###################################################################################################
## Creating HMM models from alignments
###################################################################################################

my $hmmdir = $outdir.'/HMM_motifs';
my $soghmm = $hmmdir.'/SOG';
my $moghmm = $hmmdir.'/MOG';

for my $dir ($hmmdir, $soghmm, $moghmm){
    unless (-d $dir){
        mkdir ($dir, 0755) or die "Can't create $dir: $!\n";
    }
}

print "\n"."### Creating HMM models with hmmbuild from HMMER\n\n";
logs(\*LOG, 'run_hmmbuild.pl', 'start');

if (scalar(@sog_fasta) >= 1){
    system("
        $core/run_hmmbuild.pl \\
          -o $soghmm \\
          -a $sogdir/*.aln
    ");
}

if (scalar(@mog_fasta) >= 1){
    system("
        $core/run_hmmbuild.pl \\
          -o $moghmm \\
          -a $mogdir/*.aln
    ");
}

logs(\*LOG, 'run_hmmbuild.pl', 'end');

###################################################################################################
## Querying HMM models against UniProt database(s)
###################################################################################################

my $hmm_search = $outdir.'/HMM_searches';
my $tbl_sog = $hmm_search.'/TBL_SOG';
my $tbl_mog = $hmm_search.'/TBL_MOG';

for my $dir ($hmm_search, $tbl_sog, $tbl_mog){
    unless (-d $dir){
        mkdir ($dir, 0755) or die "Can't create $dir: $!\n";
    }
}

my $dbfile;
if (($db eq 'swiss') or ($db eq 'both')){

    print "\n"."### Searching HMM models against Swiss-Prot with hmmsearch from HMMER\n\n";
    logs(\*LOG, 'run_hmmsearch.pl (Swiss-Prot)', 'start');

    $dbfile = $dbloc.'/uniprot_sprot.fasta.gz';

    ## Single orthogroups
    if (scalar(@sog_fasta) >= 1){

        system ("
            $core/run_hmmsearch.pl \\
            --hmm $soghmm/*.hmm \\
            --fasta $dbfile \\
            --threads $threads \\
            --outdir $tbl_sog \\
            --evalue $evalue \\
            --log
        ");

        system ("
            $core/parse_hmmtbl.pl \\
            -tbl $tbl_sog/*.hmm.*.tbl \\
            -out $outdir/hmmtable_sog.tsv
        ");

    }

    ## Multicopy orthogroups
    if (scalar(@mog_fasta) >= 1){

        system ("
            $core/run_hmmsearch.pl \\
            --hmm $moghmm/*.hmm \\
            --fasta $dbfile \\
            --threads $threads \\
            --outdir $tbl_mog \\
            --evalue $evalue \\
            --log
        ");

        system ("
            $core/parse_hmmtbl.pl \\
            -tbl $tbl_mog/*.hmm.*.tbl \\
            -out $outdir/hmmtable_mog.tsv
        ");

    }

    logs(\*LOG, 'run_hmmsearch.pl (Swiss-Prot)', 'end');

}

if (($db eq 'trembl') or ($db eq 'both')){

    print "\n"."### Searching HMM models against trEMBL with hmmsearch from HMMER\n\n";
    logs(\*LOG, 'run_hmmsearch.pl (trEMBL)', 'start');

    $dbfile = $dbloc.'/uniprot_trembl.fasta.gz';

    ## Single orthogroups
    if (scalar(@sog_fasta) >= 1){

        system ("
            $core/run_hmmsearch.pl \\
            --hmm $soghmm/*.hmm \\
            --fasta $dbfile \\
            --threads $threads \\
            --outdir $tbl_sog \\
            --evalue $evalue \\
            --log
        ");

        system ("
            $core/parse_hmmtbl.pl \\
            -tbl $tbl_sog/*.hmm.*.tbl \\
            -out $outdir/hmmtable_sog.tsv
        ");

    }

    ## Multicopy orthogroups
    if (scalar(@mog_fasta) >= 1){

        system ("
            $core/run_hmmsearch.pl \\
            --hmm $moghmm/*.hmm \\
            --fasta $dbfile \\
            --threads $threads \\
            --outdir $tbl_mog \\
            --evalue $evalue \\
            --log
        ");

        system ("
            $core/parse_hmmtbl.pl \\
            -tbl $tbl_mog/*.hmm.*.tbl \\
            -out $outdir/hmmtable_mog.tsv
        ");

    }

    logs(\*LOG, 'run_hmmsearch.pl (trEMBL)', 'end');

}

###################################################################################################
## Completion
###################################################################################################

print "\n";

my $end_time = localtime();
my $run_time = time - $start_time;

logs(\*LOG, 'Total runtime', 'header');
print LOG "MMH completed on: ".$end_time."\n";
print LOG "Total runtime: ".$run_time." seconds\n";
close LOG;

###################################################################################################
## Subroutines
###################################################################################################

sub checksig {

	my $exit_code = $?;
	my $modulo = $exit_code % 255;

	if ($modulo == 2) {
		print "\nSIGINT detected: Ctrl+C => exiting...\n\n";
		exit(2);
	}
	elsif ($modulo == 131) {
		print "\nSIGTERM detected: Ctrl+\\ => exiting...\n\n";
		exit(131);
	}

}

sub logs {

	my $fh = $_[0];
	my $analysis = $_[1];
	my $type = $_[2];
	my $len = length($analysis);
	my $pad = 60 - $len;
	my $spacer = ' ' x $pad;


	my $mend = localtime();
	if ($type eq 'header'){
		my $barsize = '#' x 96;
		print $fh $barsize."\n";
		print LOG "##### $analysis\n";
		print LOG $barsize."\n\n";
	}
	elsif ($type eq 'start'){
		print $fh "$analysis:".$spacer."started on $mend\n";
	}
	elsif ($type eq 'end'){

		my $run_time = time - $tstart;
		my $tlen = length($run_time);
		my $tpad = $pad + $len - $tlen - 18;
		my $tspacer = ' ' x $tpad;

		print $fh "Runtime: $run_time seconds".$tspacer."completed on $mend\n\n";

	}

}