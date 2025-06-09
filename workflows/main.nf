// workflows/main.nf - COMPLETE FIXED VERSION for MultiQC

include { FASTQC }  from '../modules/local/fastqc/main'
include { MULTIQC } from '../modules/local/multiqc/main'

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

    // Run FastQC
    FASTQC(ch_samplesheet)
    
    // FIXED: Properly collect ALL FastQC outputs for MultiQC
    // Method 1: Simple and reliable approach
    ch_multiqc_files = FASTQC.out.html
        .mix(FASTQC.out.zip)
        .map { meta, files -> files }
        .flatten()
        .collect()
    
    // Alternative method (comment out method 1 and use this if needed):
    // ch_multiqc_files = Channel.empty()
    //     .mix(FASTQC.out.html.map{ meta, files -> files }.flatten())
    //     .mix(FASTQC.out.zip.map{ meta, files -> files }.flatten())
    //     .collect()
    
    // Debug: Let's see what we're collecting
    ch_multiqc_files.view { "MultiQC input files: $it" }
    
    // Create proper empty channels for optional MultiQC inputs
    // Use Channel.value() for empty values instead of []
    ch_multiqc_config = Channel.value([])
    ch_extra_multiqc_config = Channel.value([])
    ch_multiqc_logo = Channel.value([])
    
    // Run MultiQC with the collected files
    MULTIQC(
        ch_multiqc_files,
        ch_multiqc_config,
        ch_extra_multiqc_config,
        ch_multiqc_logo
    )
    
    // Emit outputs for potential downstream processes
    emit:
    fastqc_html = FASTQC.out.html
    fastqc_zip = FASTQC.out.zip
    multiqc_report = MULTIQC.out.report
    multiqc_data = MULTIQC.out.data
}