/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    WORKFLOWS/MAIN.NF - Data Loading and Basic Pipeline Structure
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Check input file exists
def checkPathParamList = [ params.input ]
for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow FOHM_AMR {

    //
    // Create input channel from samplesheet
    //
    CREATE_INPUT_CHANNEL()
    ch_input = CREATE_INPUT_CHANNEL.out.reads

    //
    // Split input by sequencing platform
    //
    ch_input
        .branch {
            illumina: it[0].platform == "illumina"
            nanopore: it[0].platform == "nanopore"
        }
        .set { ch_platform_split }

    //
    // Print what we found for verification
    //
    ch_platform_split.illumina
        .view { meta, reads -> "Illumina sample: ${meta.id} with ${reads.size()} files" }
    
    ch_platform_split.nanopore
        .view { meta, reads -> "Nanopore sample: ${meta.id} with 1 file" }

    emit:
    illumina_reads = ch_platform_split.illumina
    nanopore_reads = ch_platform_split.nanopore
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CREATE INPUT CHANNEL FROM SAMPLESHEET
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow CREATE_INPUT_CHANNEL {
    
    main:
    Channel
        .fromPath(params.input)
        .splitCsv(header: true, strip: true)
        .map { row ->
            println "Raw row: ${row}"
            
            def meta = [:]
            def sample = row.sample?.toString()?.trim()
            def platform = row.platform?.toString()?.trim()
            def fastq_1 = row.fastq_1?.toString()?.trim()
            def fastq_2 = row.fastq_2?.toString()?.trim()
            
            println "Parsed - sample: '${sample}', platform: '${platform}'"
            
            if (!sample || sample.isEmpty()) {
                error "Sample name is required in samplesheet"
            }
            if (!platform || platform.isEmpty()) {
                error "Platform is required in samplesheet"
            }
            if (!fastq_1 || fastq_1.isEmpty()) {
                error "fastq_1 path is required in samplesheet"
            }
            
            meta.id = sample
            meta.platform = platform.toLowerCase()
            
            if (meta.platform == "illumina") {
                if (!fastq_2 || fastq_2.isEmpty()) {
                    error "fastq_2 is required for Illumina samples"
                }
                meta.single_end = false
                return [meta, [file(fastq_1, checkIfExists: true), file(fastq_2, checkIfExists: true)]]
            } else if (meta.platform == "nanopore") {
                meta.single_end = true
                return [meta, file(fastq_1, checkIfExists: true)]
            } else {
                error "Platform must be either 'illumina' or 'nanopore', got: '${meta.platform}'"
            }
        }
        .set { reads }

    emit:
    reads = reads
}