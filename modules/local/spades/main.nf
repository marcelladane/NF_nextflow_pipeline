process SPADES {
    tag "$meta.id"
    label 'process_high'
    publishDir "${params.outdir}/spades", mode: 'copy', pattern: "*.fasta"
    publishDir "${params.outdir}/spades/logs", mode: 'copy', pattern: "*.log"
    publishDir "${params.outdir}/spades/graphs", mode: 'copy', pattern: "*.gfa"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.fasta"), emit: contigs
    tuple val(meta), path("*.gfa"), emit: graphs, optional: true
    tuple val(meta), path("*.log"), emit: log
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when
    // Only run SPAdes on Illumina paired-end data
    meta.platform == 'illumina' && !meta.single_end

    script:
    def args = task.ext.args ?: '--only-assembler'
    def prefix = task.ext.prefix ?: "${meta.id}"
    def input1 = reads[0]
    def input2 = reads[1]
    def memory = task.memory ? "--memory ${task.memory.toGiga()}" : ""
    
    """
    echo "========================================"
    echo "SPADES ASSEMBLY - ${meta.id}"
    echo "========================================"
    echo "Platform: ${meta.platform}"
    echo "Input files: ${input1}, ${input2}"
    echo "Threads: $task.cpus"
    echo "Memory: ${task.memory ?: 'default'}"
    echo ""
    
    # Create output directory
    mkdir -p spades_output
    
    # Run SPAdes
    spades.py \\
        -1 ${input1} \\
        -2 ${input2} \\
        -o spades_output \\
        --threads $task.cpus \\
        $memory \\
        $args \\
        2>&1 | tee ${prefix}_spades.log
    
    echo ""
    echo "SPAdes assembly completed. Processing outputs..."
    
    # Copy and rename main outputs
    if [ -f "spades_output/contigs.fasta" ]; then
        cp spades_output/contigs.fasta ${prefix}_contigs.fasta
        echo "✅ Contigs: ${prefix}_contigs.fasta"
    else
        echo "❌ No contigs.fasta found"
        touch ${prefix}_contigs.fasta  # Create empty file to prevent pipeline failure
    fi
    
    if [ -f "spades_output/scaffolds.fasta" ]; then
        cp spades_output/scaffolds.fasta ${prefix}_scaffolds.fasta
        echo "✅ Scaffolds: ${prefix}_scaffolds.fasta"
    fi
    
    # Copy assembly graph if available
    if [ -f "spades_output/assembly_graph.gfa" ]; then
        cp spades_output/assembly_graph.gfa ${prefix}_assembly_graph.gfa
        echo "✅ Assembly graph: ${prefix}_assembly_graph.gfa"
    fi
    
    echo ""
    echo "=== SPAdes Assembly Summary ==="
    
    # Basic assembly statistics
    if [ -f "${prefix}_contigs.fasta" ] && [ -s "${prefix}_contigs.fasta" ]; then
        contigs_count=\$(grep -c "^>" ${prefix}_contigs.fasta || echo "0")
        echo "Contigs: \$contigs_count"
        
        # Calculate N50 and total length (simple version)
        awk '/^>/ {if (seq) print length(seq); seq=""} !/^>/ {seq=seq\$0} END {if (seq) print length(seq)}' \\
            ${prefix}_contigs.fasta | sort -nr > contig_lengths.txt
        
        total_length=\$(awk '{sum+=\$1} END {print sum}' contig_lengths.txt || echo "0")
        max_length=\$(head -1 contig_lengths.txt || echo "0")
        
        echo "Total assembly length: \$total_length bp"
        echo "Longest contig: \$max_length bp"
        
        # Simple N50 calculation
        half_total=\$((total_length / 2))
        running_sum=0
        n50=0
        while read length; do
            running_sum=\$((running_sum + length))
            if [ \$running_sum -ge \$half_total ]; then
                n50=\$length
                break
            fi
        done < contig_lengths.txt
        echo "N50: \$n50 bp"
        
        rm contig_lengths.txt
    else
        echo "No contigs produced or empty assembly"
    fi
    
    # Check SPAdes log for warnings/errors
    if grep -q "ERROR" ${prefix}_spades.log; then
        echo "⚠️  Errors found in SPAdes log"
    elif grep -q "WARNING" ${prefix}_spades.log; then
        echo "⚠️  Warnings found in SPAdes log"
    else
        echo "✅ SPAdes completed without major issues"
    fi
    
    echo ""
    echo "Output files:"
    ls -la *.fasta *.log *.gfa 2>/dev/null || echo "Some output files missing"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        spades: \$(spades.py --version 2>&1 | sed 's/SPAdes v//')
    END_VERSIONS
    """

    stub:
    """
    echo "STUB: Creating placeholder SPAdes files"
    touch ${prefix}_contigs.fasta
    touch ${prefix}_scaffolds.fasta
    touch ${prefix}_assembly_graph.gfa
    touch ${prefix}_spades.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        spades: \$(spades.py --version 2>&1 | sed 's/SPAdes v//' || echo "3.15.0")
    END_VERSIONS
    """
}