FROM python:3.12-slim

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Create ffxi user and group
RUN groupadd -g 1003 ffxi && \
    useradd -u 1003 -g 1003 -s /bin/bash -d /app ffxi

# Install system dependencies for pandas, sqlalchemy, and yq
RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    libpq-dev \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install yq
RUN wget -O /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/v4.44.3/yq_linux_amd64 && \
    chmod +x /usr/local/bin/yq

# Set working directory
WORKDIR /app

# Clone ffxiahbot repository
RUN git clone https://github.com/AdamGagorik/ffxiahbot.git .

# Install ffxiahbot package and dependencies
RUN pip install --no-cache-dir .

# Set ownership
RUN chown -R ffxi:ffxi /app && \
    chmod -R 770 /app

# Run as ffxi user
USER ffxi

# Command to run the bot (defaults to scrubbing prices)
CMD ["ffxiahbot", "scrub"]
