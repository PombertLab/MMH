<p align="left"><img src="https://github.com/PombertLab/MMH/blob/master/Images/logo.png" alt="MMH - A simple pipeline to create and search HMM models against reference protein databases." width="800"></p>

[![DOI](https://zenodo.org/badge/345143326.svg)](https://zenodo.org/doi/10.5281/zenodo.5532798)

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
To download MMH from the command line (with `git`):

```Bash
git clone https://github.com/PombertLab/MMH.git
cd MMH/
export PATH=$PATH:$(pwd)
export PATH=$PATH:$(pwd)/Core
```

#### Downloading the UniProt databases
Hidden markov searches will be performed against a local copy of the UniProt Swiss-Prot and/or trEMBL databases.

The Swiss-Prot database can be downloaded with `get_UniProt.pl` as follows:

```Bash
UNIPROT=~/UniProt                ## Replace by desired download location

## Downloading the Swiss-Prot database
get_UniProt.pl \
  -s \
  -f $UNIPROT

## Downloading both the Swiss-Prot and trEMBL databases
get_UniProt.pl \
  -s \
  -t \
  -f $UNIPROT
```

Note that the trEMBL database is quite large. We recommend using the [aria2](https://aria2.github.io/) lightweight utility to download large files. If missing, get_UniProt.pl will use `wget` instead (or `curl` if the latter is missing as well).

Options for [get_UniProt.pl](https://github.com/PombertLab/MMH/blob/master/Core/get_UniProt.pl) are:
```
-s  (--swiss)         Download Swiss-Prot
-t  (--trembl)        Download trEMBL
-f  (--folder)        Download folder [Default: ./]
-l  (--log)           Print download information to log file
-dt (--dtool)         Specify download tool: aria2c, wget or curl ## Tries to autodetect otherwise
-x  (--connex)        Number of aria connections [Default: 10]
-d  (--decompress)    Decompress downloaded files with gunzip     ## trEMBL is huge, off by default
-v  (--version)       Show script version
```

## Running MMH

The MMH pipeline consists of a few simple steps:
1. It finds homologs (orthologs/paralogs) with [OrthoFinder](https://github.com/davidemms/OrthoFinder).
2. It aligns homologs with [MAFFT](https://mafft.cbrc.jp/alignment/software/).
3. It builds HMM models from these alignments with hmmbuild from [HMMER](http://hmmer.org/).
4. It searches these HMM models against a local copy of the [UniProt](https://www.uniprot.org/) databases.
5. It reports matches as simple tab-delimited output files.

The MMH pipeline can be run via its `run_mmh.pl` master script. To run MMH, provide run_mmh.pl with the directory containing the FASTA files to query and the desired output directory:

```Bash
FASTA=~/FASTA              ## Replace by FASTA file directory 
OUTDIR=~/MMH               ## Replace by desired output directory
DBLOC=~/UniProt            ## Replace by UniProt database location
DB=swiss                   ## Desired database to query: swiss, trembl, both

run_mmh.pl \
  -f $FASTA \
  -o $OUTDIR \
  -dbloc $DBLOC \
  -db swiss
```

Options for run_mmh.pl are:
```
-f (--fasta)        Directory containing fasta files to create HMM models from
-o (--outdir)       Output directory [Default: MMH]
-d (--db)           Databases to query: swiss, trembl, or both [Default: swiss]
-l (--dbloc)        Databases location
-t (--threads)      Number of threads to use [Default: 16]
-e (--evalue)       HMM search evalue cutoff [Default: 1e-10]
-v (--version)      Show script version
```

The content of the results directory will look like this:
```
ls -lah MMH/

drwxr-xr-x  4 jpombert jpombert 4.0K Jun  3 14:19 Datasets
drwxr-xr-x  4 jpombert jpombert 4.0K Jun  3 14:19 HMM_motifs
drwxr-xr-x  4 jpombert jpombert 4.0K Jun  3 14:19 HMM_searches
drwxr-xr-x  3 jpombert jpombert 4.0K Jun  3 14:36 OrthoFinder
-rw-r--r--  1 jpombert jpombert  11K Jun  3 14:36 hmmtable_sog.tsv
-rw-r--r--  1 jpombert jpombert 1.9K Jun  3 14:36 mmh.log
```

The contents of the subdirectories are:

 - DATASETS:
   - Contains SOG/MOG datasets (in FASTA format)
   - Contains tab-delimited SOG/MOG summaries (in TSV format)
 - HMM_motifs:
   - Contains HMM motifs (created with hmmbuild) for each SOG/MOG
 - HMM_searches:
   - Contains tables (.tbl) containing homology results for each SOG/MOG 
 - OrthoFinder:
   - Contains the output from OrthoFinder searches

For ease of use, single copy orthogroups (sog) and multicopy orthogroups (mog) will be labelled distinctively in the files and subdirectories. Results will be contatenated in the corresponding tab-delimited hmmtable_{sog,mog}.tsv file(s). The TSV table(s) should look like this:

```Bash
head -n 10 MMH/hmmtable_sog.tsv

Query	Target	E-value	Product	Genus	Species	OS descriptor
SOG00004	sp|P23968|VATO_YEAST	1.1e-18	V-type proton ATPase subunit c''	Saccharomyces	Saccharomyces cerevisiae	Saccharomyces cerevisiae (strain ATCC 204508 / S288c) 
SOG00004	sp|Q9SLA2|VATO2_ARATH	1e-17	V-type proton ATPase subunit c''2	Arabidopsis	Arabidopsis thaliana	Arabidopsis thaliana 
SOG00004	sp|Q9SZY7|VATO1_ARATH	1.1e-17	V-type proton ATPase subunit c''1	Arabidopsis	Arabidopsis thaliana	Arabidopsis thaliana 
SOG00004	sp|O14046|VATO_SCHPO	1.1e-15	Probable V-type proton ATPase 20 kDa proteolipid subunit	Schizosaccharomyces	Schizosaccharomyces pombe	Schizosaccharomyces pombe (strain 972 / ATCC 24843) 
SOG00004	sp|G5EDB8|VATO_CAEEL	1.4e-15	V-type proton ATPase 21 kDa proteolipid subunit c''	Caenorhabditis	Caenorhabditis elegans	Caenorhabditis elegans 
SOG00004	sp|Q99437|VATO_HUMAN	8.6e-15	V-type proton ATPase 21 kDa proteolipid subunit c''	Homo	Homo sapiens	Homo sapiens 
SOG00004	sp|Q91V37|VATO_MOUSE	8.6e-15	V-type proton ATPase 21 kDa proteolipid subunit c''	Mus	Mus musculus	Mus musculus 
SOG00004	sp|Q2TA24|VATO_BOVIN	1.8e-14	V-type proton ATPase 21 kDa proteolipid subunit c''	Bos	Bos taurus	Bos taurus 
SOG00005	sp|P26659|RAD15_SCHPO	7.2e-233	General transcription and DNA repair factor IIH helicase subunit XPD	Schizosaccharomyces	Schizosaccharomyces pombe	Schizosaccharomyces pombe (strain 972 / ATCC 24843) 
```

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