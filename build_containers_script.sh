#!/bin/bash
# build_containers.sh - Build Docker containers for FOHM AMR pipeline
# Demonstrates containerization strategy with focus on core QC tools

set -e  # Exit on error

echo "========================================"
echo "FOHM AMR Pipeline - Container Builder"
echo "========================================"
echo "Building Docker containers for pipeline modules..."
echo "Strategy: Focus on core QC tools for demonstration"
echo ""

# Define container registry/prefix (change as needed)
REGISTRY="fohm-amr"
TAG="latest"

# Function to build a container
build_container() {
    local module=$1
    local image_name="${REGISTRY}/${module}:${TAG}"
    
    echo "Building ${module} container..."
    echo "Docker image: ${image_name}"
    echo "Dockerfile: modules/local/${module}/Dockerfile"
    echo ""
    
    if [ -f "modules/local/${module}/Dockerfile" ]; then
        echo "📦 Starting build for ${module}..."
        docker build \
            -t "${image_name}" \
            -f "modules/local/${module}/Dockerfile" \
            modules/local/${module}/
        
        echo "✅ ${module} container built successfully!"
        echo "Image: ${image_name}"
        
        # Test the container
        echo "🧪 Testing container..."
        case "${module}" in
            "fastqc")
                docker run --rm "${image_name}" fastqc --version
                ;;
            "multiqc")
                docker run --rm "${image_name}" multiqc --version
                ;;
            "trimmomatic")
                docker run --rm "${image_name}" trimmomatic -version
                ;;
            *)
                echo "ℹ️  No specific test for ${module}"
                ;;
        esac
        echo ""
    else
        echo "❌ Dockerfile not found for ${module}"
        echo "Expected: modules/local/${module}/Dockerfile"
        echo ""
    fi
}

# Function to explain why a container wasn't built
explain_skipped() {
    local module=$1
    local reason=$2
    echo "⏭️  Skipping ${module}: ${reason}"
}

# Test Docker installation
echo "Testing Docker installation..."
if ! command -v docker &> /dev/null; then
    echo "❌ Docker not found. Please install Docker first."
    echo "Installation guide: https://docs.docker.com/get-docker/"
    exit 1
fi

if ! docker info &> /dev/null; then
    echo "❌ Docker daemon not running or permission denied."
    echo "Try: sudo systemctl start docker"
    echo "Or add user to docker group: sudo usermod -aG docker $USER"
    echo "Then logout and login again."
    exit 1
fi

echo "✅ Docker is ready"
echo "Docker version: $(docker --version)"
echo ""

echo "========================================"
echo "PHASE 1: Core QC Tools (Demonstration)"
echo "========================================"
echo "Building lightweight containers for quality control..."
echo ""

# Build core QC containers (fast and reliable)
build_container "fastqc"
build_container "multiqc" 
build_container "trimmomatic"

echo ""
echo "========================================"
echo "PHASE 2: Complex Assembly Tools"
echo "========================================"
echo "Production strategy for complex bioinformatics tools:"
echo ""

# Explain production strategy for complex tools
explain_skipped "spades" "Complex dependencies, production uses conda-based approach"
explain_skipped "flye" "Memory-intensive tool, optimized for HPC environments"
explain_skipped "abricate" "Requires BLAST+ databases, containerized in production with pre-loaded DBs"
explain_skipped "quast" "Python plotting dependencies, production uses biocontainers"

echo ""
echo "🏗️  Production Implementation Strategy:"
echo "   • Complex tools: Use proven biocontainers (quay.io/biocontainers)"
echo "   • Custom optimization: Conda-based multi-stage builds"
echo "   • Database tools: Pre-loaded containers with updated databases"
echo "   • CI/CD integration: Automated builds with security scanning"
echo ""

echo "========================================"
echo "Container Build Summary"
echo "========================================"

# List built images
echo "Successfully built containers:"
docker images | grep "^${REGISTRY}" | while read repo tag id created size; do
    echo "  📦 ${repo}:${tag} (${size}, created ${created})"
done

echo ""
echo "Available for production deployment:"
echo "  🌐 biocontainers/fastqc:v0.11.9_cv8"
echo "  🌐 quay.io/biocontainers/spades:3.15.5--h95f258a_1" 
echo "  🌐 quay.io/biocontainers/abricate:1.0.1--ha8f3691_1"
echo "  🌐 quay.io/biocontainers/quast:5.2.0--py39pl5321h2add14b_1"
echo "  🌐 quay.io/biocontainers/multiqc:1.19--pyhdfd78af_0"

echo ""
echo "🎉 Container build phase completed!"
echo ""
echo "========================================"
echo "Next Steps & Usage"
echo "========================================"
echo ""
echo "1. Test individual containers:"
echo "   docker run ${REGISTRY}/fastqc:${TAG} fastqc --version"
echo "   docker run ${REGISTRY}/multiqc:${TAG} multiqc --version"
echo "   docker run ${REGISTRY}/trimmomatic:${TAG} trimmomatic -version"
echo ""
echo "2. Run pipeline with custom containers:"
echo "   nextflow run main.nf -profile docker --input data/samplesheet.csv"
echo ""
echo "3. Run pipeline with biocontainers (full functionality):"
echo "   nextflow run main.nf -profile docker_public --input data/samplesheet.csv"
echo ""
echo "4. Hybrid approach (recommended for production):"
echo "   nextflow run main.nf -profile local_docker --input data/samplesheet.csv"
echo ""
echo "📋 Documentation: See documentation/DOCKER_STRATEGY.md for detailed implementation plan"
echo ""