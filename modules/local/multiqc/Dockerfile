# modules/local/multiqc/Dockerfile
FROM python:3.9-slim

LABEL maintainer="FOHM Pipeline Developer"
LABEL description="MultiQC container for quality control reporting"
LABEL version="1.19"

# Install system dependencies
RUN apt-get update && \
    apt-get install -y \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install MultiQC
RUN pip install --no-cache-dir multiqc==1.19

# Create working directory
WORKDIR /data

# Test installation
RUN multiqc --version

CMD ["multiqc", "--help"]