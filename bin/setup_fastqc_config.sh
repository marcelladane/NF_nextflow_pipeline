#!/bin/bash

# Create proper FastQC configuration files
echo "Setting up FastQC configuration..."

# Create the FastQC config directory
sudo mkdir -p /etc/fastqc/Configuration

# Create proper limits.txt (tab-separated, no headers)
sudo tee /etc/fastqc/Configuration/limits.txt > /dev/null << 'LIMITS_EOF'
per_base_quality	10	5
per_tile_quality	10	5
per_sequence_quality	10	5
per_base_sequence_content	10	5
per_sequence_gc_content	15	5
per_base_n_content	20	5
sequence_duplication_levels	70	20
overrepresented_sequences	0.1	1
adapter_content	10	5
kmer_content	2	5
n_content	5	20
LIMITS_EOF

# Create proper adapter_list.txt (tab-separated: name<TAB>sequence)
sudo tee /etc/fastqc/Configuration/adapter_list.txt > /dev/null << 'ADAPTERS_EOF'
Illumina Universal Adapter	AGATCGGAAGAG
Illumina Small RNA 3' Adapter	TGGAATTCTCGG
Illumina Small RNA 5' Adapter	GATCGTCGGACT
Nextera Transposase Sequence	CTGTCTCTTATA
SOLID Small RNA Adapter	CGCCTTGGCCGT
ADAPTERS_EOF

echo "FastQC configuration created successfully"
echo "Config directory: /etc/fastqc/Configuration"
echo "Files created:"
echo "  - limits.txt (quality thresholds)"
echo "  - adapter_list.txt (known adapters)"

# Test the configuration
echo ""
echo "Testing FastQC with new configuration..."
fastqc --version

echo "Configuration setup complete!"
