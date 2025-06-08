nextflow.enable.dsl=2

workflow illumina_pipeline(reads) {
    reads | view { "Illumina read pair: ${it}" }
}

workflow nanopore_pipeline(reads) {
    reads | view { "Nanopore single-end read: ${it}" }
}