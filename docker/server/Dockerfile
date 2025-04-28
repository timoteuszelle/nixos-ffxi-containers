FROM ubuntu:24.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Create ffxi user and group
RUN groupadd -g 1003 ffxi && \
    useradd -u 1003 -g 1003 -s /bin/false -d /srv/ffxi ffxi

# Install common dependencies
RUN apt-get update && apt-get install -y \
    software-properties-common \
    git \
    wget \
    curl \
    gnupg \
    python3 \
    python3-pip \
    net-tools \
    nano \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    gcc \
    g++ \
    cmake \
    make \
    libmariadb-dev-compat \
    libmariadb-dev \
    libluajit-5.1-dev \
    libzmq3-dev \
    zlib1g-dev \
    libssl-dev \
    binutils-dev \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Clone the LandSandBoat repository
RUN git clone --recursive https://github.com/LandSandBoat/server.git .

# Install Python requirements
RUN pip3 install --break-system-packages -r tools/requirements.txt

# Download CPM.cmake for dependency management
RUN mkdir -p cmake && \
    wget -O cmake/CPM.cmake https://github.com/cpm-cmake/CPM.cmake/releases/download/v0.38.7/CPM.cmake

# Build the server
RUN mkdir -p build && \
    cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release && \
    cmake --build . -j$(nproc) && \
    ls -l /app/xi_connect || exit 1

# Copy settings and set ownership
RUN mkdir -p /server/log /server/settings /app/log && \
    cp -r settings/* /server/settings && \
    chown -R ffxi:ffxi /server /app/log && \
    chmod -R 770 /server/log /app/log

# Expose default FFXI server ports
EXPOSE 54230 54231 54001 54002 51220

# Set environment variables (can be overridden)
ENV DB_HOST=ffxi-mysql \
    DB_PORT=3306 \
    DB_USER=xiuser \
    DB_NAME=xidb

# No entrypoint; will be mounted
