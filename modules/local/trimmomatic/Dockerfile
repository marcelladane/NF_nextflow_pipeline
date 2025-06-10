# modules/local/trimmomatic/Dockerfile
FROM openjdk:11-jre-slim

LABEL maintainer="FOHM Pipeline Developer"
LABEL description="Trimmomatic container for read quality trimming"
LABEL version="0.39"

# Install dependencies
RUN apt-get update && \
    apt-get install -y \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install Trimmomatic
WORKDIR /opt
RUN wget http://www.usadellab.org/cms/uploads/supplementary/Trimmomatic/Trimmomatic-0.39.zip && \
    unzip Trimmomatic-0.39.zip && \
    ln -s /opt/Trimmomatic-0.39/trimmomatic-0.39.jar /opt/trimmomatic.jar && \
    rm Trimmomatic-0.39.zip

# Create wrapper script
RUN echo '#!/bin/bash\njava -jar /opt/trimmomatic.jar "$@"' > /usr/local/bin/trimmomatic && \
    chmod +x /usr/local/bin/trimmomatic

# Create working directory
WORKDIR /data

# Test installation
RUN trimmomatic -version

CMD ["trimmomatic"]