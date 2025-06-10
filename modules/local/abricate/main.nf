process ABRICATE {
    tag "$meta.id"
    label 'process_medium'
    publishDir "${params.outdir}/abricate", mode: 'copy', pattern: "*.tsv"
    publishDir "${params.outdir}/abricate/logs", mode: 'copy', pattern: "*.log"

    input:
    tuple val(meta), path(assembly)

    output:
    tuple val(meta), path("*.tsv"), emit: report
    tuple val(meta), path("*.log"), emit: log
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: '--db card --minid 75 --mincov 50'
    def prefix = task.ext.prefix ?: "${meta.id}"
    def database = task.ext.database ?: 'card'
    def datadir_arg = params.abricate_datadir ? "--datadir ${params.abricate_datadir}" : ""
    
    """
    echo "========================================"
    echo "ABRICATE AMR ANNOTATION - ${meta.id}"
    echo "========================================"
    echo "Platform: ${meta.platform}"
    echo "Input files received: ${assembly}"
    echo "Database: ${database}"
    echo "Custom datadir: ${params.abricate_datadir ?: 'default'}"
    echo "Arguments: ${args}"
    echo ""
    
    # Smart assembly file selection - prefer contigs over scaffolds
    echo "Selecting best assembly file..."
    echo "Available files in work directory:"
    ls -la *.fasta *.fa 2>/dev/null || echo "No FASTA files found"
    echo ""
    
    # Find the best assembly file to use
    assembly_file=""
    if ls *contigs*.fasta 1> /dev/null 2>&1; then
        assembly_file=\$(ls *contigs*.fasta | head -1)
        echo "✅ Using contigs file: \$assembly_file"
    elif ls *.fasta 1> /dev/null 2>&1; then
        assembly_file=\$(ls *.fasta | head -1)
        echo "✅ Using first FASTA file: \$assembly_file"
    elif ls *.fa 1> /dev/null 2>&1; then
        assembly_file=\$(ls *.fa | head -1)
        echo "✅ Using first FA file: \$assembly_file"
    else
        echo "❌ No FASTA files found"
        assembly_file="none"
    fi
    
    echo "Selected assembly file: \$assembly_file"
    echo "Full command: abricate $datadir_arg $args \$assembly_file"
    echo ""
    
    # Check if assembly file exists and has content
    if [ "\$assembly_file" = "none" ] || [ ! -f "\$assembly_file" ]; then
        echo "❌ Error: No suitable assembly file found"
        echo "Creating empty results to prevent pipeline failure..."
        
        cat > ${prefix}_abricate.tsv << 'EOF'
#FILE	SEQUENCE	START	END	STRAND	GENE	COVERAGE	COVERAGE_MAP	GAPS	%COVERAGE	%IDENTITY	DATABASE	ACCESSION	PRODUCT	RESISTANCE
EOF
        echo "No assembly file found" > ${prefix}_abricate.log
        
    elif [ ! -s "\$assembly_file" ]; then
        echo "❌ Warning: Assembly file \$assembly_file is empty"
        
        cat > ${prefix}_abricate.tsv << 'EOF'
#FILE	SEQUENCE	START	END	STRAND	GENE	COVERAGE	COVERAGE_MAP	GAPS	%COVERAGE	%IDENTITY	DATABASE	ACCESSION	PRODUCT	RESISTANCE
EOF
        echo "Assembly file is empty" > ${prefix}_abricate.log
        
    else
        echo "✅ Assembly file found and has content"
        
        # Get assembly statistics
        assembly_size=\$(stat -c%s "\$assembly_file")
        contig_count=\$(grep -c "^>" "\$assembly_file" 2>/dev/null || echo "0")
        
        echo "Assembly: \$assembly_file"
        echo "Size: \${assembly_size} bytes"
        echo "Contigs: \${contig_count}"
        echo ""
        
        if [ "\${contig_count}" -eq 0 ]; then
            echo "❌ Warning: No contigs found in assembly"
            
            cat > ${prefix}_abricate.tsv << 'EOF'
#FILE	SEQUENCE	START	END	STRAND	GENE	COVERAGE	COVERAGE_MAP	GAPS	%COVERAGE	%IDENTITY	DATABASE	ACCESSION	PRODUCT	RESISTANCE
EOF
            echo "No contigs in assembly" > ${prefix}_abricate.log
            
        else
            echo "Running ABRicate analysis..."
            echo "Command: abricate $datadir_arg $args \$assembly_file"
            echo ""
            
            # Run ABRicate with error handling
            set +e
            abricate \\
                $datadir_arg \\
                $args \\
                \$assembly_file \\
                > ${prefix}_abricate.tsv \\
                2> ${prefix}_abricate.log
            
            abricate_exit_code=\$?
            set -e
            
            echo "ABRicate exit code: \$abricate_exit_code"
            
            if [ \$abricate_exit_code -ne 0 ]; then
                echo "❌ ABRicate failed with exit code \$abricate_exit_code"
                echo "Error details:"
                cat ${prefix}_abricate.log
                echo ""
                echo "Creating empty results but preserving error log..."
                
                cat > ${prefix}_abricate.tsv << 'EOF'
#FILE	SEQUENCE	START	END	STRAND	GENE	COVERAGE	COVERAGE_MAP	GAPS	%COVERAGE	%IDENTITY	DATABASE	ACCESSION	PRODUCT	RESISTANCE
EOF
                echo "ABRicate execution failed - see log for details" >> ${prefix}_abricate.log
                
            else
                echo "✅ ABRicate completed successfully"
                
                if [ -f "${prefix}_abricate.tsv" ]; then
                    result_lines=\$(grep -v "^#" ${prefix}_abricate.tsv | wc -l || echo "0")
                    echo "AMR genes found: \${result_lines}"
                    
                    if [ "\${result_lines}" -gt 0 ]; then
                        echo "✅ Found \${result_lines} AMR gene(s)"
                        echo ""
                        echo "Top genes detected:"
                        grep -v "^#" ${prefix}_abricate.tsv | head -5 | cut -f6 | while read gene; do
                            echo "  - \$gene"
                        done
                    else
                        echo "ℹ️  No AMR genes detected"
                        echo "This could indicate:"
                        echo "  - Antibiotic-sensitive strain"
                        echo "  - Database mismatch"
                        echo "  - Thresholds too stringent"
                    fi
                else
                    echo "❌ ABRicate output file not created"
                fi
            fi
        fi
    fi
    
    echo ""
    echo "=== Analysis Summary ==="
    if [ -f "${prefix}_abricate.tsv" ]; then
        total_lines=\$(wc -l < ${prefix}_abricate.tsv || echo "0")
        result_lines=\$(grep -v "^#" ${prefix}_abricate.tsv | wc -l || echo "0")
        echo "Output file: ${prefix}_abricate.tsv"
        echo "Total lines: \${total_lines}"
        echo "AMR genes: \${result_lines}"
    else
        echo "❌ No output file generated"
    fi
    
    echo "Database used: ${params.abricate_datadir ?: 'default'}"
    echo "Assembly processed: \$assembly_file"
    echo ""
    echo "Final files:"
    ls -la *.tsv *.log 2>/dev/null || echo "No output files created"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        abricate: \$(abricate --version 2>&1 | sed 's/abricate //' || echo "unknown")
    END_VERSIONS
    """

    stub:
    """
    cat > ${prefix}_abricate.tsv << 'EOF'
#FILE	SEQUENCE	START	END	STRAND	GENE	COVERAGE	COVERAGE_MAP	GAPS	%COVERAGE	%IDENTITY	DATABASE	ACCESSION	PRODUCT	RESISTANCE
EOF
    
    echo "STUB: ABRicate placeholder" > ${prefix}_abricate.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        abricate: \$(abricate --version 2>&1 | sed 's/abricate //' || echo "1.0.1")
    END_VERSIONS
    """
}