<p align="left"><img src="https://github.com/PombertLab/MMH/blob/master/logo.png" alt="MMH - A simple pipeline to create and search HMM models against reference protein databases." width="800"></p>

## Table of contents
* [Introduction](#Introduction)
* [Dependencies](#Dependencies)
* [Installation](#Installation)
* [Example](#Example)
* [Scripts](#Scripts)
* [Funding and acknowledgments](#Funding-and-acknowledgments)
* [References](#References)

## Introduction
Sequenced-based homology searches are usually performed with tools that search for similarity between proteins of interest and databases of sequences (*e.g.* [BLAST](https://blast.ncbi.nlm.nih.gov/Blast.cgi)) or with tools that search for known motifs (*e.g.* [Pfam](http://pfam.xfam.org/)). However, if a biological sequence is highly divergent, sequenced-based tools may fail to find homology with known sequences or motifs. This lack of detectable homology renders functional assignment based on sequence similarity difficult, which can be problematic for groups of organisms with highly divergent sequences.

Homology searches against database motifs are inherently tied to the motifs themselves, and depending on how these motifs were generated, they may not accurately reflect the full spectrum of sequence diversity for the corresponding group of proteins. Therefore, by inverting the directionality of the search, *i.e.* by creating motifs from sets of divergent sequences and then searching these motifs against known proteins, we might be able to improve the sensitivity of these searches and/or detect new signals. This approach is similar to the reciprocity-scheme that is commonly used by the research community for BLAST searches, and should return similar hits when performed on proteins with known motifs.

We have implemented this approach in a simple to use pipeline. For this approach to work, at least a few datasets of proteins from (closely) related organisms should be available. The MMH pipeline leverages [OrthoFinder](https://github.com/davidemms/OrthoFinder), [MAFTT](https://mafft.cbrc.jp/alignment/software/) and [HMMER](http://hmmer.org/) to identify single copy orthologs, align them, and generate hidden Markov models from the alignments. Those HMM models can then be searched against reference databases such as [UniProt](https://www.uniprot.org/)’s Swiss-Prot and trEMBL.

## Dependencies
- [Perl 5](https://www.perl.org/)
- [OrthoFinder 2.3.1+](https://github.com/davidemms/OrthoFinder)
- [Diamond 2.0+](https://github.com/bbuchfink/diamond)
- [MAFFT 7+](https://mafft.cbrc.jp/alignment/software/)
- [HMMER 3.1b2+](http://hmmer.org/)

## Installation
To download MMH from the command line with Git, then add MMH to the $PATH variable (for the current session), type:
```Bash
git clone --recursive https://github.com/PombertLab/MMH.git
cd MMH/
export PATH=$PATH:$(pwd)
```

## Example
For ease of use, we can create an environment variable pointing to the Example/ folder, let's call it EX (for example):
```Bash
cd Example/         ## Replace Example/ by its location
export EX=$(pwd)
```

#### Creating orthologous datasets
Before we can create HMM models, we must first identify homologs in the datasets, then align them. We can do that with [OrthoFinder](https://github.com/davidemms/OrthoFinder) and [MAFFT](https://mafft.cbrc.jp/alignment/software/).

[OrthoFinder](https://github.com/davidemms/OrthoFinder) command line options are described on its [GitHub page](https://github.com/davidemms/OrthoFinder#further-options). To run OrthoFinder on the data located in the Example/ folder (using 10 threads; -t 10), type:
```Bash
orthofinder \
   -t 10 \
   -f $EX/FASTA/ \
   -S diamond \
   -o $EX/OrthoFinder

find $EX/OrthoFinder -name "Orthogroups.tsv" | xargs cp -t $EX/
```

To create datasets with standardized names (file_name@accession_number), type:
```Bash
make_orthogroup_datasets.pl \
   -f $EX/FASTA/ \
   -t $EX/Orthogroups.tsv \
   -o $EX/Datasets
```
Two outputs folders will be generated inside the Datasets/ directory: SINGLE_COPY_OG and MULTI_COPY_OG. Datasets featuring only single copy orthologs will be located in SINGLE_COPY_OG. Those featuring more than one ortholog per species, if any, will be located in MULTI_COPY_OG.

Options for [make_orthogroup_datasets.pl](https://github.com/PombertLab/MMH/blob/master/make_orthogroup_datasets.pl) are:
```
-f (--fasta)   Folder containing multifasta files
-t (--tsv)     Orthogroups.tsv file(s) from OrthoFinder
-o (--outdir)  Output directory
```

To align single-copy ortholog datasets with [MAFFT](https://mafft.cbrc.jp/alignment/software/), type:
```Bash
run_mafft.pl \
   -f $EX/Datasets/SINGLE_COPY_OG/*.fasta \
   -t 10
```

Alignments thus generated (with the file extension .aln) will be located in the same folder as the FASTA files.

Options for [run_mafft.pl](https://github.com/PombertLab/MMH/blob/master/run_mafft.pl) are:
```
-f (--fasta)		Multifasta files to be aligned
-t (--thread)		Number of threads, default: 8
-o (--op)		Gap opening penalty, default: 1.53
-e (--ep)		Offset (works like gap extension penalty), default: 0.0
-e (--max)		Maximum number of iterative refinement, default: 0
-c (--clustalout)	Output: clustal format, default: fasta
-r (--reorder)		Outorder: aligned, default: input order
-q (--quiet)		Do not report progress
```

#### Downloading the Swiss-Prot database
The Swiss-Prot database will be queried against with the HMM models generated in the next step. To download the Swiss-Prot database, type:
```Bash
get_UniProt.pl -s -f $EX/UniProt
```

Options for [get_UniProt.pl](https://github.com/PombertLab/MMH/blob/master/get_UniProt.pl) are:
```
-s (--swiss)		Download Swiss-Prot
-t (--trembl)		Download trEMBL
-f (--folder)		Download folder [Default: ./]
-n (--nice)		Linux Process Priority [Default: 20] ## Runs downloads in the background
-l (--log)		Print download information to log file
-d (--decompress)	Decompresss downloaded files with gunzip ## trEMBL files will be huge, off by default
```

#### Generating hidden Markov models
Hidden Markov models will be generated and queried against [UniProt](https://www.uniprot.org/)’s Swiss-Prot database with [HMMER](http://hmmer.org/). To generate the models, query against Swiss-Prot, then parse the output, type:

```Bash
run_hmmbuild.pl -a $EX/Datasets/SINGLE_COPY_OG/*.aln

run_hmmsearch.pl \
   -h $EX/Datasets/SINGLE_COPY_OG/*.hmm \
   -f $EX/UniProt/uniprot_sprot.fasta.gz \
   -t 10 \
   -e 1e-10 \
   -log

parse_hmmtbl.pl \
   -tbl $EX/Datasets/SINGLE_COPY_OG/*.hmm.*.tbl \
   -out $EX/hmmtable.tsv
```

The results will be parsed into a simple tab-delimited table for spreadsheet editors (*e.g.* Microsoft Excel, gnumeric). The .tsv table should look like this:
```Bash
head -n 10 $EX/hmmtable.tsv
Query	Target	E-value	Product	Genus	Species	OS descriptor
SOG00004	sp|P23968|VATO_YEAST	6.9e-19	V-type proton ATPase subunit c''	Saccharomyces	Saccharomyces cerevisiae	Saccharomyces cerevisiae (strain ATCC 204508 / S288c) 
SOG00004	sp|Q9SLA2|VATO2_ARATH	5.2e-18	V-type proton ATPase subunit c''2	Arabidopsis	Arabidopsis thaliana	Arabidopsis thaliana 
SOG00004	sp|Q9SZY7|VATO1_ARATH	6e-18	V-type proton ATPase subunit c''1	Arabidopsis	Arabidopsis thaliana	Arabidopsis thaliana 
SOG00004	sp|O14046|VATO_SCHPO	1.7e-16	Probable V-type proton ATPase 20 kDa proteolipid subunit	Schizosaccharomyces	Schizosaccharomyces pombe	Schizosaccharomyces pombe (strain 972 / ATCC 24843) 
SOG00004	sp|Q91V37|VATO_MOUSE	1.7e-15	V-type proton ATPase 21 kDa proteolipid subunit	Mus	Mus musculus	Mus musculus 
SOG00004	sp|Q99437|VATO_HUMAN	2.3e-15	V-type proton ATPase 21 kDa proteolipid subunit	Homo	Homo sapiens	Homo sapiens 
SOG00004	sp|Q2TA24|VATO_BOVIN	4.8e-15	V-type proton ATPase 21 kDa proteolipid subunit	Bos	Bos taurus	Bos taurus 
SOG00005	sp|P26659|RAD15_SCHPO	5.8e-238	General transcription and DNA repair factor IIH helicase subunit XPD	Schizosaccharomyces	Schizosaccharomyces pombe	Schizosaccharomyces pombe (strain 972 / ATCC 24843) 
SOG00005	sp|P06839|RAD3_YEAST	1.1e-234	General transcription and DNA repair factor IIH helicase subunit XPD	Saccharomyces	Saccharomyces cerevisiae	Saccharomyces cerevisiae (strain ATCC 204508 / S288c) 
```

Options for [run_hmmsearch.pl](https://github.com/PombertLab/MMH/blob/master/run_hmmsearch.pl) are:
```
-h (--hmm)	HMM file(s) to query
-f (--fasta)	Fasta file(s) to search against
-t (--thread)	Number of threads to use [Default: 8]
-e (--evalue)	E-value cutoff [Default: 1e-10]
-l (--log)	Redirect hmmsearch standard output(s) to log file(s)
-n (--noali)	Don't output alignments, so output is smaller
```

Options for [parse_hmmtbl.pl](https://github.com/PombertLab/MMH/blob/master/parse_hmmtbl.pl) are:
```
-t (--tbl)	TBL files generated by run_hmmsearch.pl
-o (--out)	Output table name [Default = hmmtable.tsv]
```

## Scripts
1. [get_UniProt.pl](https://github.com/PombertLab/MMH/blob/master/get_UniProt.pl) - Downloads the SwissProt and/or trEMBL databases from UniProt automatically.
2. [make_orthogroup_datasets.pl](https://github.com/PombertLab/MMH/blob/master/make_orthogroup_datasets.pl) - Creates Fasta datasets from OrthoFinder Orthogroups.tsv output file(s).
3. [run_mafft.pl](https://github.com/PombertLab/MMH/blob/master/run_mafft.pl) - Aligns multifasta files with MAFFT.
4. [run_hmmbuild.pl](https://github.com/PombertLab/MMH/blob/master/run_hmmbuild.pl) - Generates a hidden Markov model for each alignment provided in Multifasta format.
5. [run_hmmsearch.pl](https://github.com/PombertLab/MMH/blob/master/run_hmmsearch.pl) - Searches HMM profiles against proteins from known databases (*e.g.* SwissProt or trEMBL) in fasta format.
6. [parse_hmmtbl.pl](https://github.com/PombertLab/MMH/blob/master/parse_hmmtbl.pl) - Parses the output of hmm searches into a concise, tab-delimited format.

## Funding and acknowledgments
This work was supported by the National Institute of Allergy and Infectious Diseases of the National Institutes of Health (award number R15AI128627) to Jean-Francois Pombert. The content is solely the responsibility of the authors and does not necessarily represent the official views of the National Institutes of Health.

## References
Buchfink B, Xie C, Huson DH. **Fast and sensitive protein alignment using DIAMOND.** *Nat Methods.* 2015 Jan;12(1):59-60. doi: [10.1038/nmeth.3176](https://doi.org/10.1038/nmeth.3176). Epub 2014 Nov 17. PMID: 25402007.

Emms DM, Kelly S. **OrthoFinder: phylogenetic orthology inference for comparative genomics.** *Genome Biol.* 2019 Nov 14;20(1):238. doi: [10.1186/s13059-019-1832-y](https://doi.org/10.1186/s13059-019-1832-y). PMID: 31727128
 
Katoh K, Standley DM. **MAFFT multiple sequence alignment software version 7: improvements in performance and usability.** *Mol Biol Evol.* 2013 Apr;30(4):772-80. doi: [10.1093/molbev/mst010](https://doi.org/10.1093/molbev/mst010). PMID: 23329690

UniProt Consortium. **UniProt: a worldwide hub of protein knowledge.** *Nucleic Acids Res.* 2019 Jan 8;47(D1):D506-D515. doi: [10.1093/nar/gky1049](https://doi.org/10.1093/nar/gky1049). PMID: 30395287; PMCID: PMC6323992.

Söding J. **Protein homology detection by HMM-HMM comparison.** *Bioinformatics.* 2005 Apr 1;21(7):951-60. doi: [10.1093/bioinformatics/bti125](https://doi.org/10.1093/bioinformatics/bti125). PMID: 15531603

Altschul SF, Gish W, Miller W, Myers EW, Lipman DJ. **Basic local alignment search tool.** *J Mol Biol.* 1990 Oct 5;215(3):403-10. doi: [10.1016/S0022-2836(05)80360-2](https://doi.org/10.1016/s0022-2836(05)80360-2). PMID: 2231712.

El-Gebali S, Mistry J, Bateman A, Eddy SR, Luciani A, Potter SC, Qureshi M, Richardson LJ, Salazar GA, Smart A, Sonnhammer ELL, Hirsh L, Paladin L, Piovesan D, Tosatto SCE, Finn RD. **The Pfam protein families database in 2019.** *Nucleic Acids Res.* 2019 Jan 8;47(D1):D427-D432. doi: [10.1093/nar/gky995](https://doi.org/10.1093/nar/gky995). PMID: 30357350