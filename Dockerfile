FROM nvcr.io/nvidia/cuda:13.0.2-cudnn-devel-ubuntu24.04

# Install uv by coping binaries
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# For development: Install convenient packages
ENV TZ=Asia/Seoul
RUN apt update && DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends \
    build-essential \
    cmake \
    git \
    curl \
    tzdata \
    tmux \
    openssh-client \
    wget \
    unzip \
    pkg-config \
    libx11-dev \
    libxext-dev \
    libxfixes-dev \
    libxrandr-dev \
    libxrender-dev \
    libxcomposite-dev \
    libxdamage-dev \
    libxss-dev \
    libxtst-dev \
    libnss3-dev \
    libatk-bridge2.0-dev \
    libcups2-dev \
    libcupsimage2-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy this repository to the image & install via uv
COPY . /mypkg
WORKDIR /mypkg
RUN /bin/uv sync \
    && echo 'source /mypkg/.venv/bin/activate' >> /etc/bash.bashrc
