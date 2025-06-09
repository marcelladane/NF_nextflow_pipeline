process TRIMMOMATIC {
    tag "$meta.id"
    label 'process_medium'
    publishDir "${params.outdir}/trimmomatic", mode: 'copy', pattern: "*.fastq.gz"
    publishDir "${params.outdir}/trimmomatic/logs", mode: 'copy', pattern: "*.log"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*_trimmed_R*.fastq.gz"), emit: reads
    tuple val(meta), path("*_unpaired_R*.fastq.gz"), emit: unpaired, optional: true
    tuple val(meta), path("*.log"), emit: log
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when
    // Only run Trimmomatic on Illumina paired-end data
    meta.platform == 'illumina' && !meta.single_end

    script:
    def args = task.ext.args ?: 'ILLUMINACLIP:TruSeq3-PE.fa:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36'
    def prefix = task.ext.prefix ?: "${meta.id}"
    def input1 = reads[0]
    def input2 = reads[1]
    def trimmed1 = "${prefix}_trimmed_R1.fastq.gz"
    def trimmed2 = "${prefix}_trimmed_R2.fastq.gz"
    def unpaired1 = "${prefix}_unpaired_R1.fastq.gz"
    def unpaired2 = "${prefix}_unpaired_R2.fastq.gz"
    def log_file = "${prefix}_trimmomatic.log"
    
    """
    echo "========================================"
    echo "TRIMMOMATIC QUALITY TRIMMING - ${meta.id}"
    echo "========================================"
    echo "Platform: ${meta.platform}"
    echo "Input files: ${input1}, ${input2}"
    echo "Output files: ${trimmed1}, ${trimmed2}"
    echo ""
    
    # Run Trimmomatic
    trimmomatic PE \\
        -threads $task.cpus \\
        -phred33 \\
        $input1 $input2 \\
        $trimmed1 $unpaired1 \\
        $trimmed2 $unpaired2 \\
        $args \\
        2>&1 | tee $log_file
    
    echo ""
    echo "Trimmomatic completed. Generated files:"
    ls -la *.fastq.gz *.log
    
    # Summary statistics
    echo ""
    echo "=== Trimmomatic Summary ==="
    echo "Input reads:"
    echo "  R1: \$(zcat $input1 | wc -l | awk '{print \$1/4}')"
    echo "  R2: \$(zcat $input2 | wc -l | awk '{print \$1/4}')"
    echo ""
    echo "Trimmed reads:"
    echo "  R1: \$(zcat $trimmed1 | wc -l | awk '{print \$1/4}')"
    echo "  R2: \$(zcat $trimmed2 | wc -l | awk '{print \$1/4}')"
    echo ""
    echo "Log file: $log_file"
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        trimmomatic: \$(trimmomatic -version 2>&1 | sed 's/Trimmomatic//' | sed 's/^[ ]*//')
    END_VERSIONS
    """

    stub:
    """
    echo "STUB: Creating placeholder Trimmomatic files"
    touch ${prefix}_trimmed_R1.fastq.gz
    touch ${prefix}_trimmed_R2.fastq.gz
    touch ${prefix}_unpaired_R1.fastq.gz
    touch ${prefix}_unpaired_R2.fastq.gz
    touch ${prefix}_trimmomatic.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        trimmomatic: \$(trimmomatic -version 2>&1 | sed 's/Trimmomatic//' | sed 's/^[ ]*//' || echo "0.39")
    END_VERSIONS
    """
}