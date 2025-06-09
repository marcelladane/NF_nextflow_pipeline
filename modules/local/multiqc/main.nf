process MULTIQC {
    tag "multiqc"
    label 'process_single'
    publishDir "${params.outdir}/multiqc", mode: 'copy'

    input:
    path multiqc_files
    val multiqc_config
    val extra_multiqc_config  
    val multiqc_logo

    output:
    path "*multiqc_report.html", emit: report
    path "*_data"              , emit: data
    path "*_plots"             , optional:true, emit: plots
    path "versions.yml"        , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    echo "========================================"
    echo "MULTIQC REPORT GENERATION"
    echo "========================================"
    echo "Scanning for analysis files..."
    echo ""
    
    # Debug: Show what files are available in the working directory
    echo "Working directory: \$(pwd)"
    echo "Available files:"
    ls -la
    echo ""
    
    echo "FastQC files found:"
    find . -name "*fastqc*" -type f
    echo ""
    
    echo "ZIP files found:"
    find . -name "*.zip" -type f
    echo ""
    
    echo "HTML files found:"
    find . -name "*.html" -type f
    echo ""
    
    # Run MultiQC with verbose output to see what it finds
    echo "Running MultiQC..."
    multiqc \\
        --force \\
        --verbose \\
        $args \\
        .
    
    echo ""
    echo "MultiQC execution completed."
    echo "Generated files:"
    ls -la
    echo ""
    
    # Check if report was generated
    if ls *multiqc_report.html 1> /dev/null 2>&1; then
        echo "✅ MultiQC report generated successfully!"
        for file in *multiqc_report.html; do
            echo "Report: \$file (size: \$(stat -c%s \$file) bytes)"
        done
    else
        echo "❌ WARNING: No MultiQC report generated"
        echo "This indicates MultiQC couldn't find or process the input files"
        
        # Additional debugging
        echo ""
        echo "Debugging information:"
        echo "MultiQC version: \$(multiqc --version)"
        echo "Available MultiQC modules:"
        multiqc --list-modules | head -10
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        multiqc: \$( multiqc --version | sed 's/multiqc, version //' )
    END_VERSIONS
    """

    stub:
    """
    echo "STUB: Creating placeholder MultiQC files"
    touch multiqc_report.html
    mkdir multiqc_data
    mkdir multiqc_plots

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        multiqc: \$( multiqc --version | sed 's/multiqc, version //' )
    END_VERSIONS
    """
}