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
------------------------------------------------------------------------------------   
|Profile        |Use Case             |Memory         |CPUs           |Time        |   
|local          |Development/Testing6 | 6GB           | 4             | 2h         | # used only with portion of data    
|production     |HPC/Cloud            | 128GB         | 32            | 24h        |   
|slurm          |SLURM clusters       | 128GB         | 32            | 24h        |   
|aws            |AWS Cloud            | 128GB         | 32            | 24h        |   
|test           |CI/CD                | 6GB           | 2             | 4h         | # used only with portion of data    
------------------------------------------------------------------------------------   

Example for cloud deployment:
'''
bash# Scale up resources for large datasets
nextflow run main.nf --input samplesheet.csv -profile production
'''

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

## Known Issues & Solutions   
- FastQC Configuration Challenges   
- Issue: FastQC configuration format varies between versions and environments   

-- Multiple FastQC versions require different configuration file formats   
-- System-wide vs local configuration conflicts   
-- Java environment and classpath dependencies   

--- Current Status: Pipeline attempts real FastQC execution, falls back to demonstration output   
---Production Solution: Use containerized FastQC deployment   

'''
# Production FastQC
docker run -v $(pwd):/data quay.io/biocontainers/fastqc:0.11.9--0 \   
  fastqc /data/*.fastq.gz --outdir /data/results/   

# Production MultiQC     
docker run -v $(pwd):/data quay.io/biocontainers/multiqc:1.13--pyhdfd78af_0 \   
  multiqc /data/results/ --outdir /data/reports/'''      

--- Expected QC Results (from real FastQC analysis):   
~4% Illumina Universal Adapter contamination in test data   
Good overall sequence quality scores   
Recommendation: Proceed with adapter trimming before assembly   
Assembly Readiness: Post-QC data suitable for SPAdes/Flye assembly   

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
✅ FastQC quality control (with demonstration outputs + containerization strategy)
✅ MultiQC reporting (with demonstration outputs + containerization strategy)
 Read trimming (Illumina) - Next: demonstration implementation
 Genome assembly (SPAdes/Flye) - Next: demonstration implementation
 AMR annotation (RGI) - Next: demonstration implementation
 Comparative analysis - Next: demonstration implementation   

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
├────local       
├────── fastqc
├────── multiqc   
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
├── documents   
├────    
├────    
├── containers   
├────    
├────    
└── .gitignore             # Excludes large files   
