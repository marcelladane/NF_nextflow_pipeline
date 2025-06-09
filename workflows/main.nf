// workflows/main.nf - VERSION WITH TRIMMOMATIC

include { FASTQC }      from '../modules/local/fastqc/main'
include { TRIMMOMATIC } from '../modules/local/trimmomatic/main'
include { MULTIQC }     from '../modules/local/multiqc/main'

workflow FOHM_AMR {
    // Define input channel from samplesheet
    ch_samplesheet = Channel.fromPath(params.input)
        .splitCsv(header: true)
        .map { row ->
            def meta = [:]
            meta.id = row.sample
            meta.platform = row.platform
            meta.single_end = row.fastq_2 ? false : true
            
            if (meta.single_end) {
                [meta, [file(row.fastq_1, checkIfExists: true)]]
            } else {
                [meta, [file(row.fastq_1, checkIfExists: true), file(row.fastq_2, checkIfExists: true)]]
            }
        }

    // Debug input channel
    ch_samplesheet.view { "Processing sample: $it" }

    // Run FastQC on raw reads
    FASTQC(ch_samplesheet)
    
    // Run Trimmomatic on Illumina paired-end reads
    TRIMMOMATIC(ch_samplesheet)
    
    // Create channel for trimmed reads + original nanopore reads
    // Illumina samples will use trimmed reads, Nanopore will use original
    ch_processed_reads = ch_samplesheet
        .join(TRIMMOMATIC.out.reads, remainder: true)
        .map { meta, original_reads, trimmed_reads ->
            if (trimmed_reads && meta.platform == 'illumina' && !meta.single_end) {
                [meta, trimmed_reads]
            } else {
                [meta, original_reads]
            }
        }
    
    // Debug processed reads channel
    ch_processed_reads.view { "Processed reads for downstream: $it" }
    
    // Run FastQC on processed reads (trimmed Illumina + original Nanopore)
    FASTQC_PROCESSED = FASTQC
    FASTQC_PROCESSED(ch_processed_reads)
    
    // Collect ALL FastQC outputs for MultiQC (raw + processed)
    ch_multiqc_files = FASTQC.out.html
        .mix(FASTQC.out.zip)
        .mix(FASTQC_PROCESSED.out.html)
        .mix(FASTQC_PROCESSED.out.zip)
        .map { meta, files -> files }
        .flatten()
        .collect()
    
    // Debug: Let's see what we're collecting
    ch_multiqc_files.view { "MultiQC input files: $it" }
    
    // Create proper empty channels for optional MultiQC inputs
    ch_multiqc_config = Channel.value([])
    ch_extra_multiqc_config = Channel.value([])
    ch_multiqc_logo = Channel.value([])
    
    // Run MultiQC with all QC results
    MULTIQC(
        ch_multiqc_files,
        ch_multiqc_config,
        ch_extra_multiqc_config,
        ch_multiqc_logo
    )
    
    // Emit outputs for potential downstream processes
    emit:
    raw_reads = ch_samplesheet
    processed_reads = ch_processed_reads
    trimmed_reads = TRIMMOMATIC.out.reads
    fastqc_raw_html = FASTQC.out.html
    fastqc_raw_zip = FASTQC.out.zip
    fastqc_processed_html = FASTQC_PROCESSED.out.html
    fastqc_processed_zip = FASTQC_PROCESSED.out.zip
    trimmomatic_log = TRIMMOMATIC.out.log
    multiqc_report = MULTIQC.out.report
    multiqc_data = MULTIQC.out.data
}