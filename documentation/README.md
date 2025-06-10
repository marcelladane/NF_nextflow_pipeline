# FOHM AMR Pipeline

Antibiotic Resistance (AMR) analysis pipeline for Illumina and Nanopore sequencing data.   

## Quick Start   
1. Clone Repository   
`bash   
git clone <your-repo-url>   
cd fohm-amr-pipeline`   

2. Set Up Test Data   
Option A: Download data   

`bash   
mkdir -p data   
cd data  `

## Download from Cloud
curl -L <your_URL -o fast_R1.fastq.gz>   
curl -L <your_URL -o fast_R2.fastq.gz>   
curl -L <your_URL -o nanopore.fastq.gz>   

`cd ..`   

3. Run Pipeline   
### Local development (laptops/workstations):     
bashnextflow run main.nf --input data/samplesheet.csv -profile local   

#### Production (HPC/Cloud with full resources):   
bashnextflow run main.nf --input data/samplesheet.csv -profile production   

### SLURM cluster:   
bashnextflow run main.nf --input data/samplesheet.csv -profile slurm   

### AWS Cloud:   
bashnextflow run main.nf --input data/samplesheet.csv -profile aws   

Results will be generated in:   
- results/fastqc/ - Individual FastQC reports   
- results/multiqc/ - Aggregated quality control report   

## Input Format   
The pipeline expects a CSV samplesheet:   
- csv  
sample,platform,fastq_1,fastq_2   
illumina_sample,illumina,data/illumina_R1.fastq.gz,data/illumina_R2.fastq.gz   
nanopore_sample,nanopore,data/nanopore.fastq.gz,   

## Deployment Profiles   
The pipeline supports multiple execution environments:   

|Profile  |Use Case  |Memory  |CPUs  |Time  |   
| --- | --- | --- | --- | --- |
|local          |Development/Testing6 | 6GB           | 4             | 2h         | # used only with portion of data    
|production     |HPC/Cloud            | 128GB         | 32            | 24h        |   
|slurm          |SLURM clusters       | 128GB         | 32            | 24h        |   
|aws            |AWS Cloud            | 128GB         | 32            | 24h        |   
|test           |CI/CD                | 6GB           | 2             | 4h         | # used only with portion of data    

Example for cloud deployment:
`
bash# Scale up resources for large datasets
nextflow run main.nf --input samplesheet.csv -profile production
`

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

## Development Strategy   
Phase 1 (Current): Complete pipeline architecture with realistic demonstration outputs   
Phase 2 (Production): Containerize all tools for environment-independent execution   
This approach prioritizes:   
✅ Complete end-to-end workflow demonstration   
✅ Realistic bioinformatics analysis expectations   
✅ Professional problem-solving approach   
✅ Production-ready architecture planning   

## Development Status
✅ Data loading and validation
✅ Platform detection (Illumina vs Nanopore)
✅ Git-friendly data management
✅ FastQC quality control
✅ MultiQC reporting
✅ Read trimming (Illumina) 
✅ Genome assembly (SPAdes/Flye) - See notes on issues and workarounds
✅ Abricate
✅ Comparative analysis - Will need update once Flye is working properly   

## Issues and workarounds
- Flye failure:
    - Nanopore file is a 120MB file, that is more than my laptop can handle. So my first approach was to create a script to fractionate the original file. 
    - The second step tried was to setup a sequencial processing. So Flye would not start before Spades was done running. That also still failed.
    - So for the last step I need to add a troubleshooting in case a file doesnt exist to proceed without it. Because I cannot run this tool on my laptop. That will need to be tested and optimized on the cloud. 
- To have a full DB to run Abricade my laptop would not have computer power enough. For testing purposes, I use a mock DB made with help of AI. Therefore the results are not correct, only for demonstration purposes.
- Quast is skippping report on nanopore considering I cannot run it locally. So once nanopore module is tested on the cloud we need to edit quast accordingly. 


Repository Structure   
fohm-amr-pipeline/   
├── main.nf                 # Pipeline entry point   
├── nextflow.config         # Configuration   
├── .gitignore             # Excludes large files   
├── environment.yml        # Environment requirements   
├── setup_environment.sh   # Install pkgs to environment
├── README.rmd             # Pipeline development and implementation docs   
├── workflows   
├──── main.nf       # Main workflow logic   
├── data   
├──── samplesheet.csv    # Input specification   
├──── *.fastq.gz         # (excluded from Git)   
├── modules   
├────local       
├────── fastqc   
├──────── main.nf      
├────── multiqc   
├──────── main.nf   
├────── trimmomatic  
├──────── main.nf         
├────── spades   
├──────── main.nf   
├────── flye   
├──────── main.nf   
├────── abricate   
├──────── main.nf   
├────── quast   
├──────── main.nf   
├── bin   
├──── setup_fastqc_config   
├── assets    
├──── multiqc_config      
├──── fastqc   
├────── adapter_list   
├────── limits   
├──── demo   
├────── fastqc_report_template   
├────── multiqc_report_template     
├────── trimmomatic_example_output     
├────── multiqc_report_template     
├── documents   
├──── LLM_usage_documentation.rmd     
├──── Technical_limitations_rmd   
├── containers   
├────    
├────    
├── results   
├────fastqc                # contain all fastqc reports       
├────multiqc               # contain multiqc reports   
├────pipeline_info         # contain system requirements/run time reports       
├────