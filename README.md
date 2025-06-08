# FOHM AMR Pipeline

Antibiotic Resistance (AMR) analysis pipeline for Illumina and Nanopore sequencing data.

## Quick Start
1. Clone Repository
'''bash
git clone <your-repo-url>
cd fohm-amr-pipeline'''

2. Set Up Test Data
Option A: Download data

'''bash
mkdir -p data
cd data'''

## Download from Cloud
curl -L <your_URL -o fast_R1.fastq.gz>
curl -L <your_URL -o fast_R2.fastq.gz>
curl -L <your_URL -o nanopore.fastq.gz>

"cd .."

3. Run Pipeline
'''bash
nextflow run main.nf --input data/samplesheet.csv'''


## Input Format
The pipeline expects a CSV samplesheet:

- csv example 
- file should be named "samplesheet.csv"
sample,platform,fastq_1,fastq_2
illumina_sample,illumina,data/illumina_R1.fastq.gz,data/illumina_R2.fastq.gz
nanopore_sample,nanopore,data/nanopore.fastq.gz,

## Requirements
- Nextflow ≥22.10.1
- Docker or Singularity
- curl (for data download)

Data Management
- Large FASTQ files are excluded from Git via .gitignore
- Data must be downloaded separately before running pipeline

Expected checksums (MD5):
illumina_R1.fastq.gz: e44f4abf80afaf09e23546b40a13c8ee
illumina_R2.fastq.gz: 5239cbef2403b79c96ca782ff47fd8b0
nanopore.fastq.gz: 34407430af7ffc9fe296ebc217e6ffcf

Development Status
 Data loading and validation
 Platform detection (Illumina vs Nanopore)
 Git-friendly data management
 FastQC quality control
 Read trimming (Illumina)
 Genome assembly (SPAdes/Flye)
 AMR annotation (RGI)
 Comparative analysis

Repository Structure
fohm-amr-pipeline/
├── main.nf                 # Pipeline entry point
├── nextflow.config         # Configuration
├── workflows
├──── main.nf       # Main workflow logic
├── data
├──── samplesheet.csv    # Input specification
├──── *.fastq.gz         # (excluded from Git)
├── modules
├──── 
├──── 
├── results
├──── 
├──── 
├── documents
├──── 
├──── 
├── containers
├──── 
├──── 
└── .gitignore             # Excludes large files
