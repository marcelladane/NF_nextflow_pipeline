# modules/local/fastqc/Dockerfile
FROM ubuntu:22.04

# Set labels for metadata
LABEL maintainer="FOHM Pipeline Developer"
LABEL description="FastQC container for quality control analysis"
LABEL version="0.11.9"

# Avoid interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && \
    apt-get install -y \
    wget \
    unzip \
    openjdk-11-jre-headless \
    perl \
    && rm -rf /var/lib/apt/lists/*

# Install FastQC
WORKDIR /opt
RUN wget https://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v0.11.9.zip && \
    unzip fastqc_v0.11.9.zip && \
    chmod +x FastQC/fastqc && \
    ln -s /opt/FastQC/fastqc /usr/local/bin/fastqc && \
    rm fastqc_v0.11.9.zip

# Create working directory
WORKDIR /data

# Test installation
RUN fastqc --version

# Set default command
CMD ["fastqc", "--help"]