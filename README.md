## Xylella_MLST_ONT

**Last update on 11 November 2022**

A quick tutorial for *Xylella* MLST identification with three methods are summarised here:
- A. **K-mer based stringMLST**
- B. **BLASTn to identify the most adundant alleles of MLST genes**
- C. NGSpeciesID is used for making consensus sequences for each gene. Concatenate all sequences to make a one fasta file with seven genes and this fasta file is used as an input for mlst to determine sequence typing.

Note: Only use NGSpeciesID if sequence data was generated using kit 12/14 chemistry and basecalled using the super high accuracy (SUP) model, otherwise mslt will provide inconsistent results. 

## Before doing analysis make sure basecalling must be done using the super high accuracy (SUP) model. 
Nanopore community has software that are frequently upgraded so use the most recent version.
Basecalling and demultiplexing is done using guppy https://community.nanoporetech.com/downloads#gns[searchValue]=guppy

## Requirement and Dependency
This workflow has been tested to work on Linux environment with conda installed and it is dependent on the following tools:
1. stringMLST (https://github.com/jordanlab/stringMLST)
2. BLAST+ (https://www.ncbi.nlm.nih.gov/books/NBK279690/)
3. NGSpeciesID (https://github.com/ksahlin/NGSpeciesID) 
4. mlst (https://github.com/tseemann/mlst)
5. Seqkit (https://github.com/shenwei356/seqkit/)

**Installation with conda**
stringMLST and NGSpeicesID are avialable on Conda and the latest version of environments should be created for running stringMLST and NGSpeicesID 

1. Creating stringMLST environment
```
conda create --name stringMLST
conda activate stringMLST
conda install stringMLST
```

2. Creating NGSpeciesID environment
```
conda create -n NGSpeciesID python=3.6 pip 
conda activate NGSpeciesID
conda install --yes -c conda-forge -c bioconda medaka==0.11.5 openblas==0.3.3 spoa racon minimap2 blast
pip install NGSpeciesID

```

3. Clone this into your working directory
```
git clone https://github.com/Pragya2019/Xylella_MLST_ONT
```



## create a directory with input files
The input unziped, basecalled, demultiplexed raw read files from Nanopore sequencing run in `fastq` format are required as input. Sample folders contained `fastq` files and all samples should be placed in a single directory as an input. Please see the example input directory in `Sample1/fastq.fastq`
## create allele.list
It containes the names of all MLST gene name list
'allele.list'

## create sample.list
It contains all samples to be tested with the fastq file for each sample. 
'sample.list'

## Step by step
## Step_1 Build stringMLST database

to run it requires a database to be build using ???buildDB
download both alleles and MLST profiles to build it. Make a txt file as given below  and run ???buildDB

[loci]
leuA  path_to_fasta/leuA.fa
petC path_to_fasta/petC.fa
malF path_to_fasta/malF.fa
cysG path_to_fasta/cysG.fa
holC path_to_fasta/holC.fa
nuoL path_to_fasta/nuoL.fa
glT path_to_fastap/glT.fa
[profile]
profile Path_to_profile.txt
stringMLST.py --buildDB -c Path_to_file/config.txt -k 35 -P NM
or download MLST scheme directly from https://github.com/jordanlab 

## Step_2 stringMLST
```
stringMLST.py --predict -1 /path_to_fasta_or_fastq -s --prefix /path_to_StringMLSTdatabase -o /sampleST.txt

```
## Step_3 makeblastdb 
 
database for each gene downloaded from PubMLST (https://pubmlst.org/bigsdbdb=pubmlst_xfastidiosa_seqdef&page=downloadAlleles)
```
makeblastdb -in /path_to_fasta_file -dbtype nucl -title name_db -out name_db
```
## Convert fastq files to fasta for BLASTn
```
seqkit fq2fa reads.fq.gz -o reads.fa.gz
```
## Step_4 BLASTn
To know the most abundant allele
```
blastn -db /Path_to_/MLSTdatabase -num_threads 8 -task megablast -outfmt 6 -max_hsps 1 -max_target_seqs 1 -query /path_to_fasta | grep "malF_" | awk '{print $2}' | sort | uniq -c | sort -nk1 -r > malF_blast.txt
```
This is repeated for all genes and txt files for genes are visualized on the screen to know the most abundant alleles. Correct alleles should be in adundance.The sequence type is known from the *Xylella fastidiosa* MLST profile from PubMLST. Rest of the steps are needed when there is a need to make consensus for each gene for automation to know sequence types.

## Step_5 Subset reads
```
blastn -db /Path_to_/MLSTdatabase -num_threads 8 -task megablast -outfmt 6 -max_hsps 1 -max_target_seqs 1 -query /path_to_fasta | grep "malF_" | awk '{print $1}' | sort -u > malF_blast_reads_ID.txt
less -S ./sample.list | while read sample; do echo $sample; cd $sample; cat ../allele.list | while read allele; do echo $allele; seqkit grep ./fastq_*.fastq -f $allele\_blast_reads_ID.txt -o $allele\_blast_reads.fastq; done; cd ..; done
```
## Step_6 NGSpeciesID
This will make clusters of the best matched reads and instead of medaka we recommend using racon polishing
```
less -S ./sample.list | while read sample; do echo $sample; cd $sample; cat ../allele.list | while read allele; do echo $allele; NGSpeciesID --fastq ./$allele\_blast_reads.fastq --ont --consensus --racon --outfolder ./$allele\_NGSpeciesID; done; cd ..; done
```
## Step_7 mlst
First cat all fasta files for seven genes created in NGSpeciesID and use this as an input for mlst 
```
less -S ./sample.list | while read sample; do echo $sample; cd $sample; cat ./*_NGSpeciesID/consensus_reference_*.fasta > all_mlst_alleles.fasta; mlst all_mlst_alleles.fasta > ./$sample\_mlst.txt; cd ..;done
```
## To inspect all results
The results from all analysis can be visualized on the screen, for this cat the files from each analyis
```
less -S ./sample.list | while read sample; do echo $sample; cat ./$sample/*_stringMLST.txt; head -n 1 ./$sample/*_blast.txt; cat ./$sample/$sample\_mlst.txt
```

    
