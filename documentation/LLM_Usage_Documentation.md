# LLM Usage Documentation

## Model/Service Used
**Claude Sonnet 4** (Anthropic) - June 2025

## Purpose of LLM Assistance

### 1. **Tool Selection & Technical Architecture**
- Comparative analysis of bioinformatics tools (Flye vs Canu, ABRicate vs CARD RGI vs AMR++)
- Pipeline architecture design discussions
- Platform-specific considerations (Illumina vs Nanopore workflows)
- Sample type analysis (isolates vs metagenomes) and tool implications

### 2. **Automatic generate environment**
- Having the full tools set selected, the next step is to create the environment to ensure that all needed packages are installed. 
- Because optimization of version can take a lot of time, using AI to already screen for the best packages in terms of compatibility saves time. So AI was used to make the "environment.yml", "requirements.txt" and "setup_environment.sh" files

### 3. **Assistency to troubleshooting when error happened**
- Issue with installation of fastqc and multiqc required fast help on code troubleshoot due to shortage of time for assignment
- AI generated code to troubleshoot installation of fastqc and multiqc and track error
- Error running flye and assistance to edit code - since it is the first time I use the tool (I didn´t work with pipelines for nanopore before, so assistance to run flye was needed since I didn´t have time enough to evaluate the full documentation and understand all requirements in depth).
- Issue to setup the mock DB for abricate. After figuring that we had a Klebsiella DNA (I took a portion of the contig file from SPAdes and blasted in NCBI to see which bacteria was), I needed to create a new DB specific to get some hits. Because with the very generic DB I got zero hits. Used AI to help me create a new DB specific to Klebsiella to ensure pipeline execution. 

### 4. **Creation of demo reports for documentation purposes**
- Because a few steps in the pipeline were not completed properly (flye and quast for nanopore samples) I created a demo folder inside assets and asked AI to create reports for me to populate the file.

### 5. **Help to brainstorm on infrastructure regarding best tools usage**
- Having the majority of the infrastructure already layouted, I was unsure about the best tools to use to verify update of the DB. So I requested explanation on what different tools could be used and which would be best. 

## Key Discussion Points & Prompts

### Tool Selection Discussion:
```
"lets just discuss shortly the differences between Flye and Canu. For illumina I would go for SPAdes. But I never worked with nanopore, so I would like to understand better the advantages and desadvantages of each."
```
```
"I assume they will run everything in AWS service, so they should have super computer infrastructure, and because they want to use SLURM its better to run using nextflow, correct?"
```
```
"My data files are between 60-120MB and the DBs (from what I saw) are a few GBs. But that will take too long to run, so I would like to create a script to take an exisiting DB online and only sample it to 1/5 of the size, that allows me to get correct output in a short timeframe. Can you help me script a short script to do such task?"
```

### Automatic generate environment:
```
"I need to start a new environment for a project. This environment will run illumina and nanopore sequencing and should process it. I selected the following tools to be used: fastqc, multiqc, trimmomatic, SPAdes, flye, quast, bandage. And they should run in a nextflow pipeline and use docker for containarization. Can you create the files needed to build my environment. Please provide "requirements.txt", "environment.yml" and "setup_environment.sh". Please add all dependencies needed"

"I got an incopatibility with quast. Can we use another version of python? the issue is the python version. Please check which version of python will be compatible with the latest version of quast. thanks."
```

### Assistency to troubleshooting when error happened
"I need help to troubleshoot the absence of output I am getting from fastqc. Currently I am using version 0.11.9 and python 3.9. I need a script to run fastqc manually and return exactly where the error is located so it can be fixed. Can you help me with a short script that will return well explained output for the possible errors during the html creation on fastqc? thanks."
```

"Based on a short screen of flye, I wrote this basic script for processing nanopore data (see attached file). I got an error printed. Can you please revise the code and help me understand which parameter is causing the error and the best fixing for it."

"I run blast on my contig output from SPAdes and found that the bacteria we are working with (the FASTA files I have) is Klebsiella. Can you help me create a new mock DB (I am attaching the previous script here to makes things work properly). where the AMR genes are specific to Klebsiella so I can ensure I will get hits to verify that abricate module is running correct, Thanks"
```

### Creation of demo reports for documentation purposes
```
"I need to create a demo report for fastqc (bioinformatics analysis - bacterial samples from illumina and nanopore) for documentation purposes. Can you help me create a HTML report I can use for the documentation. Thanks"
```

```
"I also need to create a demo report for multiqc for the same pipeline I just asked a report for fastqc for documentation purposes. Can you help me create a HTML report I can use for the documentation. Thanks"
```

### **Help to brainstorm on infrastructure regarding best tools usage**
```
"I started drawing some solutions for a theoreticall architecture and would like some guidance for a tool selection.
The basic of the structure would be as follows: 
Files come from the sequence machine automatically, could use rsync/DataSync or inotify. This files are saved in S3 using a input folder. 
Daily at a trigger hour, lets say 2AM, we have a S3 event which uses lambda function to create the samplesheet and start pipeline for data processing.
The pipeline will run and we can have a SLURM hook when the pipeline is over. Then we have a lambda function copying this results which are in a CSV to the Results DB. 
Once the results are in the DB, which we could verify by using some "Multi-Step Cleanup Trigger" (SNS Topic Orchestration, S3 + DB Sync Verification), it would trigger another lambda function which would move the data from the input bucket in S3 to a storage bucket together with the analysis output. This storage bucket would have multiple folders with sample name and date as identifier.
The end users can access the DB by API and the CI/CD is done using GitHub for version control. 
Questions: which of the 2 options for DB multi-step cleanup is best? can you help me with overview of functionality? And is this a robust enough architectural solution or am I forgetting any step? 
"
```

## Data Security Measures
- **No sequence data shared**: All discussions remained at tool/methodology level
- **No proprietary information disclosed**: Only publicly available tool specifications discussed
- **No sensitive URLs or credentials**: Assignment download links and passwords not shared in prompts

## Review and Validation Process
- **Critical evaluation**: All LLM suggestions evaluated against personal bioinformatics experience
- **Independent research**: Tool recommendations verified against current literature and documentation
- **Strategic alignment**: Ensured recommendations align with mission based on prior experience

## Implementation Notes
- LLM provided strategic guidance and technical comparisons
- All final technical decisions made independently based on assignment requirements
- Code implementation to be developed independently using LLM suggestions as starting framework

---
*Documentation updated: 2025.06.09
*Next update planned: After pipeline implementation phase*