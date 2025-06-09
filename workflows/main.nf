// workflows/main.nf - ROBUST PIPELINE WITH GRACEFUL FLYE HANDLING
// Shows complete implementation with proper error handling

include { FASTQC }      from '../modules/local/fastqc/main'
include { TRIMMOMATIC } from '../modules/local/trimmomatic/main'
include { SPADES }      from '../modules/local/spades/main'
include { FLYE }        from '../modules/local/flye/main'
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

    // Run FastQC on RAW reads
    FASTQC(ch_samplesheet)
    
    // Run Trimmomatic on Illumina paired-end reads only
    TRIMMOMATIC(ch_samplesheet)
    
    // Create channel for processed reads (trimmed Illumina + original Nanopore)
    ch_processed_reads = ch_samplesheet
        .join(TRIMMOMATIC.out.reads, remainder: true)
        .map { meta, original_reads, trimmed_reads ->
            if (trimmed_reads && meta.platform == 'illumina' && !meta.single_end) {
                // Use trimmed reads for Illumina paired-end
                [meta, trimmed_reads]
            } else {
                // Use original reads for Nanopore
                [meta, original_reads]
            }
        }
    
    // Debug processed reads channel
    ch_processed_reads.view { "Processed reads for downstream: $it" }
    
    // Split channels by platform
    ch_illumina_reads = ch_processed_reads.filter { meta, reads -> 
        meta.platform == 'illumina' && !meta.single_end 
    }
    
    ch_nanopore_reads = ch_processed_reads.filter { meta, reads -> 
        meta.platform == 'nanopore' && meta.single_end 
    }
    
    // Run SPAdes assembly on Illumina samples (reliable)
    SPADES(ch_illumina_reads)
    SPADES.out.contigs.view { "SPAdes contigs: $it" }
    
    // Run Flye assembly on Nanopore samples (may fail due to memory constraints)
    // Pipeline continues even if Flye fails
    FLYE(ch_nanopore_reads)
    FLYE.out.contigs.view { "Flye contigs (may be empty if failed): $it" }
    
    // Collect all successful assemblies for downstream analysis
    // This combines SPAdes (working) + Flye (if successful)
    ch_assemblies = SPADES.out.contigs
        .mix(FLYE.out.contigs)
        .filter { meta, contigs ->
            // Only pass assemblies that have actual content (not empty files)
            contigs.size() > 1000  // Filter out empty/tiny files (<1KB)
        }
    
    ch_assemblies.view { "Valid assemblies for ABRicate: $it" }
    
    // Collect FastQC results for MultiQC
    ch_multiqc_files = FASTQC.out.html
        .mix(FASTQC.out.zip)
        .map { meta, files -> files }
        .flatten()
        .collect()
    
    // Create proper empty channels for optional MultiQC inputs
    ch_multiqc_config = Channel.value([])
    ch_extra_multiqc_config = Channel.value([])
    ch_multiqc_logo = Channel.value([])
    
    // Run MultiQC with QC results
    MULTIQC(
        ch_multiqc_files,
        ch_multiqc_config,
        ch_extra_multiqc_config,
        ch_multiqc_logo
    )
    
    // Emit outputs for downstream processes
    emit:
    raw_reads = ch_samplesheet
    processed_reads = ch_processed_reads
    assemblies = ch_assemblies                    // Only successful assemblies for ABRicate
    valid_assemblies = ch_assemblies              // Assemblies that passed quality filter
    trimmed_reads = TRIMMOMATIC.out.reads
    spades_contigs = SPADES.out.contigs          // SPAdes results (reliable)
    spades_graphs = SPADES.out.graphs
    spades_log = SPADES.out.log
    flye_contigs = FLYE.out.contigs              // Flye results (may be empty)
    flye_graphs = FLYE.out.graphs
    flye_info = FLYE.out.info
    flye_log = FLYE.out.log
    fastqc_html = FASTQC.out.html
    fastqc_zip = FASTQC.out.zip
    trimmomatic_log = TRIMMOMATIC.out.log
    multiqc_report = MULTIQC.out.report
    multiqc_data = MULTIQC.out.data
}