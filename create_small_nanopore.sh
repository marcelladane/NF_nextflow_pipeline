#!/bin/bash

# Create smaller Nanopore dataset only (keep Illumina files unchanged)

echo "============================================="
echo "Creating Smaller Nanopore Test Dataset"
echo "============================================="
echo "This will create 25% (1/4) subset of Nanopore data only"
echo "Illumina files will remain unchanged (they work fine)"
echo ""

# Check current file sizes
echo "Current file sizes:"
ls -lh data/*.fastq.gz

echo ""

# Function to create nanopore subset
create_nanopore_subset() {
    local input_file="data/nanopore.fastq.gz"
    local output_file="data/nanopore_subset.fastq.gz"
    local percentage=25  # 1/4 = 25%
    
    if [ ! -f "$input_file" ]; then
        echo "❌ $input_file not found!"
        exit 1
    fi
    
    echo "Creating 25% subset of Nanopore data:"
    echo "  Input: $input_file"
    echo "  Output: $output_file"
    
    # Get original file info
    original_size=$(ls -lh "$input_file" | awk '{print $5}')
    echo "  Original size: $original_size"
    
    # For FASTQ files, we need to keep complete records (4 lines each)
    total_lines=$(zcat "$input_file" | wc -l)
    subset_lines=$((total_lines * percentage / 100))
    # Round to nearest multiple of 4 (complete FASTQ records)
    subset_lines=$(( (subset_lines / 4) * 4 ))
    
    echo "  Total lines: $total_lines"
    echo "  Subset lines: $subset_lines (25%)"
    echo ""
    echo "Creating subset... (this may take a moment)"
    
    # Create 25% subset
    zcat "$input_file" | head -n $subset_lines | gzip > "$output_file"
    
    # Verify results
    subset_size=$(ls -lh "$output_file" | awk '{print $5}')
    subset_reads=$(zcat "$output_file" | wc -l | awk '{print $1/4}')
    original_reads=$(echo "$total_lines / 4" | bc)
    
    echo "✅ Nanopore subset created successfully!"
    echo "  Original: $original_size ($original_reads reads)"
    echo "  Subset: $subset_size ($subset_reads reads)"
    echo ""
}

# Create the nanopore subset
create_nanopore_subset

# Update samplesheet to use subset nanopore data
echo "Updating samplesheet to use subset Nanopore data..."

# Backup original samplesheet
if [ -f "data/samplesheet.csv" ]; then
    cp data/samplesheet.csv data/samplesheet_original.csv
    echo "✅ Backed up original samplesheet to data/samplesheet_original.csv"
fi

# Create updated samplesheet
cat > data/samplesheet.csv << 'EOF'
sample,platform,fastq_1,fastq_2
illumina_sample,illumina,data/illumina_R1.fastq.gz,data/illumina_R2.fastq.gz
nanopore_sample,nanopore,data/nanopore_subset.fastq.gz,
EOF

echo "✅ Updated data/samplesheet.csv to use nanopore_subset.fastq.gz"
echo ""

echo "============================================="
echo "Setup Complete!"
echo "============================================="
echo ""
echo "File summary:"
echo "✅ Illumina files: UNCHANGED (working fine)"
echo "✅ Nanopore file: REDUCED to 25% (should work with 16GB RAM)"
echo "✅ Samplesheet: UPDATED to use subset"
echo ""
echo "Test your pipeline:"
echo "  nextflow run main.nf --input data/samplesheet.csv -profile local"
echo ""
echo "Expected benefits:"
echo "✅ Flye should work with 25% Nanopore data"
echo "✅ Much faster Nanopore assembly"
echo "✅ SPAdes continues to work as before"
echo "✅ Complete end-to-end pipeline testing"
echo ""
echo "To restore original:"
echo "  mv data/samplesheet_original.csv data/samplesheet.csv"
echo ""
echo "Ready for testing! 🧬"