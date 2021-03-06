## MMH - Reversed HMM
A simple pipeline to create and search HMM models against reference protein databases.

## Table of contents
* [Introduction](#introduction)
* [Dependencies](#dependencies)
* [Installation](#installation)
* [Usage example](#Usage-example)
* [Scripts](#Scripts)
* [Funding and acknowledgments](#Funding-and-acknowledgments)
* [References](#References)

## Introduction
Sequenced-based homology searches are usually performed with tools that search for similarity between proteins of interest and databases of sequences (*e.g.* [BLAST](https://blast.ncbi.nlm.nih.gov/Blast.cgi)) or with tools that search for known motifs (*e.g.* [Pfam](http://pfam.xfam.org/)). However, if a biological sequence is highly divergent, sequenced-based tools may fail to find homology with known sequences or motifs. This lack of detectable homology renders functional assignment based on sequence similarity difficult, which can be problematic for groups of organisms with highly divergent sequences.

Homology searches against database motifs are inherently tied to the motifs themselves, and depending on how these motifs were generated, they may not accurately reflect the full spectrum of sequence diversity for the corresponding group of proteins. Therefore, by inverting the directionalty of the search, *i.e.* by creating motifs from sets of divergent sequences and then searching these motifs against known proteins, we might be able to improve the sensitivity of these searches and/or detect new signals. This approach is similar to the reciprocity-scheme that is commonly used by the research community for BLAST searches, and should return similar hits when performed on proteins with known motifs.

We have implemented this approach in a simple to use pipeline. For this approach to work, at least a few datasets of proteins from (closely) related organims should be available. The MMH pipeline leverages [OrthoFinder](https://github.com/davidemms/OrthoFinder), [MAFTT](https://mafft.cbrc.jp/alignment/software/) and [HMMER](http://hmmer.org/) to identify single copy orthologs, align them, and generate hidden Markov models from the alignments. Those HMM models can then be searched against reference databases such as [UniProt](https://www.uniprot.org/)’s Swiss-Prot and trEMBL.

## Dependencies
- [Perl 5](https://www.perl.org/)
- [OrthoFinder 2.3.1+](https://github.com/davidemms/OrthoFinder)
- [Diamond 2.0+](https://github.com/bbuchfink/diamond)
- [MAFFT 7+](https://mafft.cbrc.jp/alignment/software/)
- [HMMER 3.1b2+](http://hmmer.org/)

## Installation
#### Downloading MMH
```Bash
git clone --recursive https://github.com/PombertLab/MMH.git
```
#### Add MMH to the $PATH variable
```Bash
cd MMH/
export PATH=$PATH:$(pwd)
```

## Usage example
####  Creating a $MMH environment variable for ease of use
```
export MMH=/path/to/installation_directory/ ## Replace operand by install location
```

#### Running OrthoFinder with 10 threads and Diamond for homology searches, then copy the Orthogroups.tsv file to the current folder
```
cd $MMH/Example/

orthofinder \
   -t 10 \
   -f $MMH/Example/FASTA/ \
   -S diamond \
   -o $MMH/Example/OrthoFinder

find $MMH/Example/OrthoFinder -name "Orthogroups.tsv" | xargs cp -t $MMH/Example/
```

#### Generate Orthogroup datasets (sequences will be named file_name@accession_number), then align them with MAFFT
```
make_orthogroup_datasets.pl \
   -f $MMH/Example/FASTA/ \
   -t $MMH/Example/Orthogroups.tsv \
   -o $MMH/Example/Datasets
   
run_mafft.pl \
   -f $MMH/Example/Datasets/SINGLE_COPY_OG/*.fasta \
   -t 10
```

#### Downloading the Swiss-Prot database
```
get_UniProt.pl -s -f $MMH/Example/UniProt
```

#### Generating hidden Markov models with HMMER, searching models against the downloaded Swiss-Prot database, and parsing the results into a simple tab-delimited table for spreadsheet editors (e.g. Microsoft Excel, gnumeric...)
```
run_hmmbuild.pl -a $MMH/Example/Datasets/SINGLE_COPY_OG/*.aln

run_hmmsearch.pl \
   -h $MMH/Example/Datasets/SINGLE_COPY_OG/*.hmm \
   -f $MMH/Example/UniProt/uniprot_sprot.fasta.gz \
   -t 10 \
   -e 1e-10 \
   -log

parse_hmmtbl.pl \
   -tbl $MMH/Example/Datasets/SINGLE_COPY_OG/*.hmm.*.tbl \
   -out $MMH/Example/hmmtable.tsv
```

## Scripts
###### get_UniProt.pl
Downloads the SwissProt and/or trEMBL databases from UniProt automatically.
###### make_orthogroup_datasets.pl
Creates Fasta datasets from OrthoFinder Orthogroups.tsv output file(s).
###### run_mafft.pl
Aligns multifasta files with MAFFT.
###### run_hmmbuild.pl
Generates a hidden Markov model for each alignment provided in Multifasta format.
###### run_hmmsearch.pl
Searches HMM profiles against proteins from known databases (e.g. SwissProt or trEMBL) in fasta format.
###### parse_hmmtbl.pl
Parses the output of hmm searches into a concise, tab-delimited format.

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