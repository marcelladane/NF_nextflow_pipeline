#!/bin/bash

# FOHM AMR Pipeline - Environment Setup Script
# This script sets up the complete environment for the pipeline

set -e  # Exit on any error

echo "============================================="
echo "FOHM AMR Pipeline - Environment Setup"
echo "============================================="

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
        echo "1. Creating conda environment from environment.yml..."
        
        if [ -f "environment.yml" ]; then
            $SETUP_METHOD env create -f environment.yml
            echo ""
            echo "✅ Environment created successfully!"
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
        echo "1. Creating Python virtual environment..."
        
        python3 -m venv fohm-amr-env
        source fohm-amr-env/bin/activate
        
        echo "2. Upgrading pip..."
        pip install --upgrade pip
        
        echo "3. Installing dependencies from requirements.txt..."
        if [ -f "requirements.txt" ]; then
            pip install -r requirements.txt
        else
            echo "❌ requirements.txt not found!"
            exit 1
        fi
        
        echo ""
        echo "✅ Virtual environment created successfully!"
        echo ""
        echo "To activate the environment:"
        echo "   source fohm-amr-env/bin/activate"
        echo ""
        echo "To run the pipeline:"
        echo "   source fohm-amr-env/bin/activate"
        echo "   nextflow run main.nf --input data/samplesheet.csv -profile local"
        echo ""
        echo "⚠️  Note: Some bioinformatics tools (FastQC, SPAdes, etc.) may need"
        echo "   to be installed separately via system package manager."
        ;;
esac

echo ""
echo "============================================="
echo "Quick Test"
echo "============================================="

echo "Testing critical components..."

# Test MultiQC specifically
if command -v multiqc &> /dev/null; then
    echo "✅ MultiQC: $(multiqc --version 2>/dev/null || echo 'installed but version check failed')"
else
    echo "❌ MultiQC: Not found in PATH"
fi

# Test FastQC
if command -v fastqc &> /dev/null; then
    echo "✅ FastQC: $(fastqc --version 2>/dev/null || echo 'installed')"
else
    echo "⚠️  FastQC: Not found in PATH (may need system installation)"
fi

# Test Nextflow
if command -v nextflow &> /dev/null; then
    echo "✅ Nextflow: $(nextflow -version 2>/dev/null | head -1 || echo 'installed')"
else
    echo "⚠️  Nextflow: Not found in PATH"
fi

echo ""
echo "Setup complete!"

# Additional system-level tool installation hints
echo ""
echo "============================================="
echo "Additional System Tools (if needed)"
echo "============================================="
echo ""
echo "If some bioinformatics tools are missing, install with:"
echo ""
echo "Ubuntu/Debian:"
echo "  sudo apt-get update"
echo "  sudo apt-get install fastqc trimmomatic"
echo ""
echo "macOS (with Homebrew):"
echo "  brew install fastqc"
echo ""
echo "Or use conda/mamba for everything:"
echo "  conda install -c bioconda fastqc spades flye rgi"