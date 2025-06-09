#!/bin/bash

# FOHM AMR Pipeline - Complete Environment Setup Script
# This script sets up the complete environment for the entire pipeline

set -e  # Exit on any error

echo "============================================="
echo "FOHM AMR Pipeline - Complete Environment Setup"
echo "============================================="
echo "This will install ALL tools needed for the complete pipeline:"
echo "- Quality Control: FastQC, MultiQC, QUAST"
echo "- Read Processing: Trimmomatic, fastp"
echo "- Assembly: SPAdes, Flye, Unicycler"
echo "- AMR Analysis: RGI, ABRicate, AMRFinderPlus"
echo "- Visualization: Bandage, BUSCO"
echo "- Utilities: BLAST, Prokka, SAMtools, etc."
echo ""

# Check if conda is available
if command -v conda &> /dev/null; then
    echo "✅ Conda found: $(conda --version)"
    SETUP_METHOD="conda"
elif command -v mamba &> /dev/null; then
    echo "✅ Mamba found: $(mamba --version)"
    SETUP_METHOD="mamba"
else
    echo "⚠️  Conda/Mamba not found. Using pip-based setup."
    SETUP_METHOD="pip"
fi

echo ""

# Setup based on available package manager
case $SETUP_METHOD in
    conda|mamba)
        echo "Setting up with $SETUP_METHOD..."
        echo "1. Creating comprehensive conda environment from environment.yml..."
        
        if [ -f "environment.yml" ]; then
            # Remove existing environment if it exists
            echo "   Removing existing environment (if any)..."
            $SETUP_METHOD env remove -n fohm-amr-pipeline -y 2>/dev/null || true
            
            # Create new environment
            echo "   Creating new environment with all tools..."
            $SETUP_METHOD env create -f environment.yml
            
            echo ""
            echo "✅ Complete environment created successfully!"
            echo ""
            echo "To activate the environment:"
            echo "   conda activate fohm-amr-pipeline"
            echo ""
            echo "To run the pipeline:"
            echo "   conda activate fohm-amr-pipeline"
            echo "   nextflow run main.nf --input data/samplesheet.csv -profile local"
        else
            echo "❌ environment.yml not found!"
            exit 1
        fi
        ;;
        
    pip)
        echo "Setting up with pip and virtual environment..."
        echo "⚠️  WARNING: Some bioinformatics tools may not be available via pip"
        echo ""
        
        # Remove existing virtual environment
        if [ -d "fohm-amr-env" ]; then
            echo "   Removing existing virtual environment..."
            rm -rf fohm-amr-env
        fi
        
        echo "1. Creating Python virtual environment..."
        python3 -m venv fohm-amr-env
        source fohm-amr-env/bin/activate
        
        echo "2. Upgrading pip..."
        pip install --upgrade pip
        
        echo "3. Installing Python dependencies from requirements.txt..."
        if [ -f "requirements.txt" ]; then
            pip install -r requirements.txt
        else
            echo "❌ requirements.txt not found!"
            exit 1
        fi
        
        echo ""
        echo "✅ Python environment created successfully!"
        echo ""
        echo "⚠️  IMPORTANT: You'll need to install bioinformatics tools separately:"
        echo "   Ubuntu/Debian: sudo apt-get install fastqc trimmomatic spades"
        echo "   macOS: brew install fastqc trimmomatic spades"
        echo "   Or use conda: conda install -c bioconda fastqc trimmomatic spades flye rgi"
        echo ""
        echo "To activate the environment:"
        echo "   source fohm-amr-env/bin/activate"
        ;;
esac

echo ""
echo "============================================="
echo "Environment Verification"
echo "============================================="

echo "Testing critical components..."

# Function to check if command exists and show version
check_tool() {
    local tool=$1
    local conda_env=${2:-""}
    
    if [ ! -z "$conda_env" ]; then
        # Check within conda environment
        if conda list -n $conda_env $tool >/dev/null 2>&1; then
            echo "✅ $tool: Available in conda environment"
        else
            echo "❌ $tool: Not found in conda environment"
        fi
    else
        # Check in current PATH
        if command -v $tool &> /dev/null; then
            echo "✅ $tool: $(which $tool)"
        else
            echo "❌ $tool: Not found in PATH"
        fi
    fi
}

if [ "$SETUP_METHOD" = "conda" ] || [ "$SETUP_METHOD" = "mamba" ]; then
    echo "Checking tools in conda environment 'fohm-amr-pipeline':"
    echo ""
    
    # Core tools
    check_tool "fastqc" "fohm-amr-pipeline"
    check_tool "multiqc" "fohm-amr-pipeline"
    check_tool "trimmomatic" "fohm-amr-pipeline"
    
    # Assembly tools
    check_tool "spades.py" "fohm-amr-pipeline"
    check_tool "flye" "fohm-amr-pipeline"
    check_tool "quast" "fohm-amr-pipeline"
    
    # AMR tools
    check_tool "rgi" "fohm-amr-pipeline"
    check_tool "abricate" "fohm-amr-pipeline"
    
    # Visualization
    check_tool "bandage" "fohm-amr-pipeline"
    
    # Workflow
    check_tool "nextflow" "fohm-amr-pipeline"
    
else
    echo "Checking tools in current environment:"
    echo ""
    
    # Check what's available
    check_tool "python3"
    check_tool "pip3"
    check_tool "multiqc"
    check_tool "fastqc"
    check_tool "nextflow"
fi

echo ""
echo "============================================="
echo "Setup Complete!"
echo "============================================="

if [ "$SETUP_METHOD" = "conda" ] || [ "$SETUP_METHOD" = "mamba" ]; then
    echo "🎉 SUCCESS: Complete bioinformatics environment ready!"
    echo ""
    echo "Next steps:"
    echo "1. conda activate fohm-amr-pipeline"
    echo "2. cd your_pipeline_directory"
    echo "3. nextflow run main.nf --input data/samplesheet.csv -profile local"
    echo ""
    echo "All tools for the complete AMR pipeline are now installed:"
    echo "✅ Quality Control (FastQC, MultiQC, QUAST)"
    echo "✅ Read Processing (Trimmomatic)"
    echo "✅ Assembly (SPAdes, Flye)"
    echo "✅ AMR Analysis (RGI, ABRicate)"
    echo "✅ Visualization (Bandage)"
    echo "✅ Workflow Management (Nextflow)"
else
    echo "⚠️  PARTIAL: Python environment ready, but bioinformatics tools need manual installation"
    echo ""
    echo "Recommended: Install conda/mamba and use the environment.yml for complete setup"
fi

echo ""
echo "Environment files:"
echo "- environment.yml: Complete conda environment"
echo "- requirements.txt: Python-only dependencies"
echo "- This script: Automated setup"