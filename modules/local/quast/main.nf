process QUAST {
    tag "$meta.id"
    label 'process_medium'
    publishDir "${params.outdir}/quast", mode: 'copy'

    input:
    tuple val(meta), path(assembly)

    output:
    tuple val(meta), path("*_quast"), emit: results
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when
    // Only run QUAST on Illumina samples for now (skip Nanopore until Flye is fixed)
    meta.platform == 'illumina'

    script:
    def args = task.ext.args ?: '--fast --no-plots --no-html'
    def prefix = task.ext.prefix ?: "${meta.id}_quast"
    
    """
    echo "========================================"
    echo "QUAST ASSEMBLY QUALITY ASSESSMENT - ${meta.id}"
    echo "========================================"
    echo "Platform: ${meta.platform}"
    echo "Input files: ${assembly}"
    echo ""
    
    # Select assembly file - prefer contigs
    assembly_file=""
    if ls *contigs*.fasta >/dev/null 2>&1; then
        assembly_file=\$(ls *contigs*.fasta | head -1)
        echo "Using contigs file: \$assembly_file"
    elif ls *.fasta >/dev/null 2>&1; then
        assembly_file=\$(ls *.fasta | head -1)
        echo "Using first FASTA file: \$assembly_file"
    else
        echo "No FASTA files found"
        assembly_file="none"
    fi
    
    # Create output directory
    mkdir -p ${prefix}
    
    if [ "\$assembly_file" = "none" ] || [ ! -f "\$assembly_file" ]; then
        echo "No assembly file found - creating minimal report"
        echo "No assembly file found" > ${prefix}/report.txt
        echo -e "Assembly\\tTotal_length\\tContigs\\nNo_assembly\\t0\\t0" > ${prefix}/report.tsv
        echo "<html><body><h1>QUAST Report</h1><p>No assembly file</p></body></html>" > ${prefix}/report.html
        
    elif [ ! -s "\$assembly_file" ]; then
        echo "Empty assembly file - creating minimal report"
        echo "Empty assembly file" > ${prefix}/report.txt
        echo -e "Assembly\\tTotal_length\\tContigs\\nEmpty_assembly\\t0\\t0" > ${prefix}/report.tsv
        echo "<html><body><h1>QUAST Report</h1><p>Empty assembly</p></body></html>" > ${prefix}/report.html
        
    else
        contig_count=\$(grep -c "^>" "\$assembly_file")
        echo "Assembly: \$assembly_file"
        echo "Contigs: \$contig_count"
        
        if [ "\$contig_count" -eq 0 ]; then
            echo "No contigs in assembly - creating minimal report"
            echo "No contigs found" > ${prefix}/report.txt
            echo -e "Assembly\\tTotal_length\\tContigs\\nNo_contigs\\t0\\t0" > ${prefix}/report.tsv
            echo "<html><body><h1>QUAST Report</h1><p>No contigs</p></body></html>" > ${prefix}/report.html
        else
            echo "Running QUAST..."
            
            # Run QUAST and let it create its own outputs
            quast.py \\
                $args \\
                --output-dir ${prefix} \\
                --threads $task.cpus \\
                "\$assembly_file" \\
                2>&1 | tee ${prefix}/quast.log || {
                echo "QUAST failed - creating manual stats"
                
                # Manual fallback only if QUAST completely fails
                awk '/^>/ {if (seq) print length(seq); seq=""} !/^>/ {seq=seq\$0} END {if (seq) print length(seq)}' "\$assembly_file" | sort -nr > ${prefix}/lengths.tmp
                total_len=\$(awk '{sum+=\$1} END {print sum}' ${prefix}/lengths.tmp)
                max_len=\$(head -1 ${prefix}/lengths.tmp)
                
                echo "Manual QUAST statistics" > ${prefix}/report.txt
                echo "Assembly: \$assembly_file" >> ${prefix}/report.txt
                echo "Total length: \$total_len" >> ${prefix}/report.txt
                echo "Contigs: \$contig_count" >> ${prefix}/report.txt
                echo "Largest contig: \$max_len" >> ${prefix}/report.txt
                
                echo -e "Assembly\\tTotal_length\\tContigs\\tLargest_contig\\n\$assembly_file\\t\$total_len\\t\$contig_count\\t\$max_len" > ${prefix}/report.tsv
                echo "<html><body><h1>Manual QUAST Report</h1><p>QUAST failed, manual stats generated</p></body></html>" > ${prefix}/report.html
                
                rm -f ${prefix}/lengths.tmp
            }
            
            echo "QUAST completed"
        fi
    fi
    
    echo ""
    echo "=== QUAST Results ==="
    echo "Output directory: ${prefix}"
    ls -la ${prefix}/ 2>/dev/null || echo "No output directory"
    
    if [ -f "${prefix}/report.txt" ]; then
        echo "Report generated successfully"
        echo "Contents of report.txt:"
        head -10 ${prefix}/report.txt
    else
        echo "No report found"
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        quast: \$(quast.py --version 2>&1 | sed 's/QUAST v//' || echo "unknown")
    END_VERSIONS
    """

    stub:
    """
    mkdir -p ${prefix}
    echo "STUB report" > ${prefix}/report.txt
    echo -e "Assembly\\tTotal_length\\tContigs\\nstub\\t1000000\\t10" > ${prefix}/report.tsv
    echo "<html><body><h1>STUB</h1></body></html>" > ${prefix}/report.html

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        quast: \$(quast.py --version 2>&1 | sed 's/QUAST v//' || echo "5.0.2")
    END_VERSIONS
    """
}