# FOHM AMR Pipeline - Complete Usage Guide

## Prerequisites

1. **Setup mock databases** (for local testing):
```bash
# Run the database setup script
cd bin
bash setup_fohm_databases.sh
cd ..

# Set environment variable for ABRicate
export ABRICATE_DATADIR="./databases/abricate"
```

2. **Verify tools are installed**:
```bash
# Check essential tools
nextflow -version
fastqc --version
multiqc --version
trimmomatic -version
spades --version
flye --version
abricate --version
quast --version
```

## Pipeline Execution

### 1. Local Testing (recommended first run)
```bash
# Use local profile with reduced resources and mock databases
nextflow run main.nf --input data/samplesheet.csv -profile local

# Alternative with custom parameters
nextflow run main.nf \
    --input data/samplesheet.csv \
    --abricate_datadir ./databases/abricate \
    --abricate_db card \
    --outdir results_local \
    -profile local
```

### 2. Production Run (with full resources)
```bash
# Production profile for HPC/cloud environments
nextflow run main.nf --input data/samplesheet.csv -profile production

# With custom AMR database settings
nextflow run main.nf \
    --input data/samplesheet.csv \
    --abricate_db resfinder \
    --abricate_minid 80 \
    --abricate_mincov 60 \
    -profile production
```

### 3. SLURM Cluster
```bash
# For HPC environments with SLURM
nextflow run main.nf --input data/samplesheet.csv -profile slurm
```

## Pipeline Outputs

### Quality Control
- `results/fastqc/` - Individual FastQC reports for each sample
- `results/multiqc/` - Comprehensive quality report combining all analyses

### Assembly Results
- `results/spades/` - SPAdes assemblies for Illumina data
- `results/flye/` - Flye assemblies for Nanopore data (may be empty if failed)

### AMR Analysis
- `results/abricate/` - AMR gene predictions
  - `*_abricate.tsv` - Detailed AMR gene annotations
  - `logs/` - Analysis logs

### Assembly Quality Assessment
- `results/quast/` - Assembly quality metrics
  - `*_quast/report.html` - Interactive quality reports
  - `*_quast/report.tsv` - Tabular quality metrics

### Processing Logs
- `results/pipeline_info/` - Execution reports and timelines

### CSV file extration
- `results/export_csv/` - csv file to be appended to the DB
  - `*_.csv` - csv table with results
  - `logs/` - Analysis logs

## Expected Behavior with Test Data

### Successful Components ✅
- **FastQC**: Complete quality control for all samples
- **Trimmomatic**: Read trimming for Illumina paired-end data
- **SPAdes**: Assembly of Illumina reads (working reliably)
- **ABRicate**: AMR gene annotation (using mock databases)
- **QUAST**: Assembly quality assessment
- **MultiQC**: Comprehensive reporting
- **Export**: Makes csv format tables to be appended to the DB

### Limited Components ⚠️
- **Flye**: May fail due to memory constraints on development hardware
  - Pipeline continues gracefully
  - Empty assembly files are filtered out automatically
  - Other analyses proceed with available assemblies

## Pipeline Parameters

### Core Parameters
| Parameter | Description | Default |
|-----------|-------------|---------|
| `--input` | Samplesheet CSV file | Required |
| `--outdir` | Output directory | `./results` |

### AMR Analysis Parameters
| Parameter | Description | Default |
|-----------|-------------|---------|
| `--abricate_db` | AMR database to use | `card` |
| `--abricate_datadir` | Custom database directory | `null` |
| `--abricate_minid` | Minimum identity threshold | `75` |
| `--abricate_mincov` | Minimum coverage threshold | `50` |

### Quality Control Parameters
| Parameter | Description | Default |
|-----------|-------------|---------|
| `--skip_fastqc` | Skip FastQC analysis | `false` |
| `--skip_multiqc` | Skip MultiQC reporting | `false` |
| `--skip_abricate` | Skip AMR analysis | `false` |
| `--skip_quast` | Skip assembly QC | `false` |

## Troubleshooting

### Memory Issues with Flye
If you see memory errors:
```
ERROR: Looks like the system ran out of memory
```
This is expected on development hardware. The pipeline will:
1. Log the error
2. Create empty output files
3. Continue with other processes
4. Filter out failed assemblies automatically

### QUAST Issues
If QUAST fails, the pipeline will generate basic assembly statistics of existing samples only.

## Development Notes

- The pipeline is designed to handle partial failures gracefully
- Mock databases are used for local testing to avoid downloading large reference databases
- Resource requirements are scaled by profile (local vs production)
- All processes include comprehensive error handling and logging

## Next Steps

For production deployment:
1. Use real AMR databases: `abricate --setupdb`
2. Increase resource allocations for large datasets
3. Implement CI/CD testing with the test profile