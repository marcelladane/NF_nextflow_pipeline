process EXPORT_CSV {
    tag "export_results"
    label 'process_single'
    publishDir "${params.outdir}/export", mode: 'copy'

    input:
    path abricate_reports
    path quast_reports
    val run_info

    output:
    path "amr_results.csv", emit: csv
    path "assembly_stats.csv", emit: assembly_stats
    path "export_summary.txt", emit: summary
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def timestamp = new Date().format('yyyy-MM-dd HH:mm:ss')
    """
    echo "========================================"
    echo "EXPORTING RESULTS TO CSV FORMAT"
    echo "========================================"
    echo "Timestamp: ${timestamp}"
    echo "Run info: ${run_info}"
    echo ""

    # Create AMR results CSV
    echo "sample_id,platform,gene,resistance,coverage,identity,database,accession,product,sequence,start,end,timestamp,run_id" > amr_results.csv

    # Process ABRicate files
    echo "Processing ABRicate results..."
    for tsv_file in *_abricate.tsv; do
        if [ -f "\$tsv_file" ]; then
            sample_id=\$(basename "\$tsv_file" _abricate.tsv)
            echo "Processing \$sample_id..."
            
            # Check if file has content beyond header
            line_count=\$(wc -l < "\$tsv_file")
            if [ "\$line_count" -gt 1 ]; then
                # Has actual results
                tail -n +2 "\$tsv_file" | while IFS=\$'\\t' read -r file sequence start end strand gene coverage coverage_map gaps pcov pid database accession product resistance; do
                    if [ -n "\$gene" ] && [ "\$gene" != "" ]; then
                        echo "\$sample_id,illumina,\$gene,\$resistance,\$pcov,\$pid,\$database,\$accession,\$product,\$sequence,\$start,\$end,${timestamp},${run_info}" >> amr_results.csv
                    fi
                done
            else
                # No AMR genes found
                echo "\$sample_id,illumina,None detected,Sensitive,0,0,card,,,,0,0,${timestamp},${run_info}" >> amr_results.csv
            fi
        fi
    done

    # Create Assembly stats CSV
    echo "sample_id,platform,total_length,contigs,n50,largest_contig,gc_content,status,timestamp,run_id" > assembly_stats.csv

    # Process QUAST results
    echo "Processing QUAST results..."
    for quast_dir in *_quast; do
        if [ -d "\$quast_dir" ]; then
            sample_id=\$(basename "\$quast_dir" _quast)
            echo "Processing QUAST for \$sample_id..."
            
            report_file="\$quast_dir/report.tsv"
            if [ -f "\$report_file" ] && [ -s "\$report_file" ]; then
                # Extract values from QUAST report
                total_length=\$(grep "Total length" "\$report_file" | cut -f2 || echo "0")
                contigs=\$(grep "# contigs" "\$report_file" | cut -f2 || echo "0")
                n50=\$(grep "N50" "\$report_file" | cut -f2 || echo "0")
                largest=\$(grep "Largest contig" "\$report_file" | cut -f2 || echo "0")
                gc=\$(grep "GC" "\$report_file" | cut -f2 || echo "0")
                
                echo "\$sample_id,illumina,\$total_length,\$contigs,\$n50,\$largest,\$gc,Success,${timestamp},${run_info}" >> assembly_stats.csv
            else
                echo "\$sample_id,illumina,0,0,0,0,0,Failed,${timestamp},${run_info}" >> assembly_stats.csv
            fi
        fi
    done

    # Create summary report
    echo "Creating summary report..."
    cat > export_summary.txt << EOF
AMR Pipeline Export Summary
==========================================
Timestamp: ${timestamp}
Run ID: ${run_info}

Files Generated:
- amr_results.csv: AMR gene detection results
- assembly_stats.csv: Assembly quality metrics

AMR Results Summary:
EOF

    # Count AMR results
    amr_samples=\$(tail -n +2 amr_results.csv | wc -l)
    resistant_samples=\$(tail -n +2 amr_results.csv | grep -v "None detected" | wc -l)
    
    echo "  Total samples analyzed: \$amr_samples" >> export_summary.txt
    echo "  Samples with resistance genes: \$resistant_samples" >> export_summary.txt
    
    if [ "\$resistant_samples" -gt 0 ]; then
        echo "  Top resistance genes:" >> export_summary.txt
        tail -n +2 amr_results.csv | grep -v "None detected" | cut -d',' -f3 | sort | uniq -c | sort -nr | head -5 | while read count gene; do
            echo "    \$gene: \$count" >> export_summary.txt
        done
    fi

    echo "" >> export_summary.txt
    echo "Assembly Quality Summary:" >> export_summary.txt
    
    # Count assembly results
    assembly_samples=\$(tail -n +2 assembly_stats.csv | wc -l)
    successful_assemblies=\$(tail -n +2 assembly_stats.csv | grep "Success" | wc -l)
    
    echo "  Total samples: \$assembly_samples" >> export_summary.txt
    echo "  Successful assemblies: \$successful_assemblies" >> export_summary.txt
    
    if [ "\$successful_assemblies" -gt 0 ]; then
        avg_contigs=\$(tail -n +2 assembly_stats.csv | grep "Success" | cut -d',' -f4 | awk '{sum+=\$1} END {print int(sum/NR)}')
        echo "  Average contigs per sample: \$avg_contigs" >> export_summary.txt
    fi

    echo "" >> export_summary.txt
    echo "Export completed successfully!" >> export_summary.txt
    echo "CSV files are ready for analysis and database import." >> export_summary.txt

    echo ""
    echo "=== Export Results ==="
    echo "Generated files:"
    ls -la *.csv *.txt 2>/dev/null || echo "Some files missing"
    
    echo ""
    echo "CSV file previews:"
    echo "AMR Results (first 3 lines):"
    head -3 amr_results.csv 2>/dev/null || echo "No AMR results"
    
    echo ""
    echo "Assembly Stats (first 3 lines):"
    head -3 assembly_stats.csv 2>/dev/null || echo "No assembly stats"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bash: \$(echo \$BASH_VERSION)
    END_VERSIONS
    """

    stub:
    """
    echo "sample_id,platform,gene,resistance,coverage,identity,database,accession,product,sequence,start,end,timestamp,run_id" > amr_results.csv
    echo "stub_sample,illumina,stub_gene,stub_resistance,100,95,card,stub_acc,stub_product,stub_seq,1,100,2024-01-01,stub_run" >> amr_results.csv
    
    echo "sample_id,platform,total_length,contigs,n50,largest_contig,gc_content,status,timestamp,run_id" > assembly_stats.csv
    echo "stub_sample,illumina,1000000,10,50000,100000,45.5,Success,2024-01-01,stub_run" >> assembly_stats.csv
    
    echo "Stub export summary" > export_summary.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bash: "5.0.0"
    END_VERSIONS
    """
}