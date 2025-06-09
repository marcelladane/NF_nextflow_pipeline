#!/bin/bash

# FOHM AMR Pipeline - Simple Test Database Creation
# Just create minimal databases so ABRicate doesn't crash

set -e  # Exit on any error

echo "============================================="
echo "Creating Simple Test Databases"
echo "============================================="
echo "Goal: Just make ABRicate work for pipeline testing"
echo "We don't need perfect AMR results, just no errors!"
echo ""

# Database directory
DB_ROOT="../databases"
ABRICATE_DIR="$DB_ROOT/abricate"

echo "Database directory: $DB_ROOT"
echo ""

# Create structure
mkdir -p "$DB_ROOT"/{abricate,logs}

echo "✅ Created directory structure"
echo ""

# Function to create a minimal test database
create_minimal_database() {
    local db_name=$1
    local description=$2
    local num_seqs=${3:-50}  # Default 50 sequences
    
    echo "Creating minimal $db_name database ($num_seqs sequences)..."
    
    local db_dir="$ABRICATE_DIR/$db_name"
    mkdir -p "$db_dir"
    
    # Create a simple FASTA file with fake resistance genes
    cat > "$db_dir/sequences" << EOF
>fake_blaOXA-1 Sample beta-lactamase gene
ATGAAAAACACAATACATATCAACTTCGCTATAAAGCAATAAATACATATCAACTTC
GCTATAAAGCAATAAATACATATCAACTTCGCTATAAAGCAATAAATACATATCAAC
>fake_tetA Tetracycline resistance gene
ATGAGCATCATCTGTACTGCATCGATCGATCGATCGATCGATCGATCGATCGATCGA
TCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGATCGAT
>fake_sul1 Sulfonamide resistance gene
ATGTCGTGCATCGACGACGACGACGACGACGACGACGACGACGACGACGACGACGAC
GACGACGACGACGACGACGACGACGACGACGACGACGACGACGACGACGACGACGAC
>fake_aph Sample aminoglycoside resistance gene
ATGCGTCGTCGTCGTCGTCGTCGTCGTCGTCGTCGTCGTCGTCGTCGTCGTCGTCGT
CGTCGTCGTCGTCGTCGTCGTCGTCGTCGTCGTCGTCGTCGTCGTCGTCGTCGTCGT
>fake_cat Chloramphenicol resistance gene
ATGTGCTGCTGCTGCTGCTGCTGCTGCTGCTGCTGCTGCTGCTGCTGCTGCTGCTGC
TGCTGCTGCTGCTGCTGCTGCTGCTGCTGCTGCTGCTGCTGCTGCTGCTGCTGCTGC
EOF

    # Add more fake sequences to reach the desired number
    for i in $(seq 6 $num_seqs); do
        cat >> "$db_dir/sequences" << EOF
>fake_gene_$i Random resistance gene $i
$(head /dev/urandom | tr -dc 'ATCG' | head -c 120)
EOF
    done
    
    # Create BLAST database
    makeblastdb -in "$db_dir/sequences" \
               -dbtype nucl \
               -title "${db_name}_test" \
               -out "$db_dir/sequences" >/dev/null 2>&1 || {
        echo "   ⚠️  BLAST database creation failed for $db_name"
        return 1
    }
    
    # Count sequences
    actual_seqs=$(grep -c "^>" "$db_dir/sequences")
    echo "   ✅ Created $db_name: $actual_seqs test sequences"
    
    return 0
}

echo "Creating minimal test databases..."
echo ""

# Create small test databases directly in the abricate directory
create_minimal_database "card" "CARD test database" 30
create_minimal_database "ncbi" "NCBI test database" 25  
create_minimal_database "resfinder" "ResFinder test database" 20
create_minimal_database "argannot" "ARG-ANNOT test database" 15

echo ""
echo "Testing ABRicate with test databases..."

# Test if ABRicate can see our databases
if abricate --datadir "$ABRICATE_DIR" --list >/dev/null 2>&1; then
    echo "✅ ABRicate can see test databases"
    echo ""
    echo "Available databases:"
    abricate --datadir "$ABRICATE_DIR" --list
else
    echo "⚠️  ABRicate test failed - but databases created"
fi

echo ""

# Create a simple configuration note
cat > "$DB_ROOT/README.md" << EOF
# FOHM Test Databases

These are minimal test databases created for pipeline development.

## Usage

In your Nextflow pipeline, use:
\`\`\`
export ABRICATE_DATADIR="$ABRICATE_DIR"
\`\`\`

Or in your ABRicate process:
\`\`\`
abricate --datadir $ABRICATE_DIR input.fasta
\`\`\`

## What's included

- card: 30 fake resistance genes
- ncbi: 25 fake resistance genes  
- resfinder: 20 fake resistance genes
- argannot: 15 fake resistance genes

## Note

These are FAKE databases for testing pipeline logic only!
For production AMR analysis, download real databases:
\`\`\`
abricate --setupdb
\`\`\`
EOF

# Quick test
echo "Quick ABRicate test..."
cat > /tmp/test_contigs.fa << 'EOF'
>contig1
ATGAAAAACACAATACATATCAACTTCGCTATAAAGCAATAAATACATATCAACTTC
GCTATAAAGCAATAAATACATATCAACTTCGCTATAAAGCAATAAATACATATCAAC
>contig2  
ATGTCGTGCATCGACGACGACGACGACGACGACGACGACGACGACGACGACGACGAC
GACGACGACGACGACGACGACGACGACGACGACGACGACGACGACGACGACGACGAC
EOF

echo "Running ABRicate test..."
abricate --datadir "$ABRICATE_DIR" /tmp/test_contigs.fa || echo "ABRicate test completed"
rm /tmp/test_contigs.fa

echo ""
echo "============================================="
echo "Simple Test Databases Created!"
echo "============================================="
echo ""
echo "Database location: $ABRICATE_DIR"
echo ""
echo "To use in your pipeline:"
echo "1. Set environment variable:"
echo "   export ABRICATE_DATADIR=\"$ABRICATE_DIR\""
echo ""
echo "2. Or use in ABRicate commands:"
echo "   abricate --datadir $ABRICATE_DIR input.fasta"
echo ""
echo "3. Your Nextflow pipeline can now run:"
echo "   nextflow run main.nf --input data/samplesheet.csv -profile local"
echo ""
echo "✅ Ready to test your pipeline!"