# CINDERGRACE ComfyUI RunPod Template
# Minimal image - Custom nodes installed dynamically via Toolkit
# CUDA 12.8 + PyTorch 2.9.1 for RTX 50xx (Blackwell) support
FROM nvidia/cuda:12.8.0-cudnn-runtime-ubuntu22.04

# Build args
ARG DEBIAN_FRONTEND=noninteractive

# Environment
ENV PYTHONUNBUFFERED=1
ENV PIP_NO_CACHE_DIR=1
ENV COMFY_ROOT=/workspace/ComfyUI
ENV MODEL_DIR=/workspace/models

# System dependencies
RUN apt-get update && apt-get install -y \
    git \
    python3.11 \
    python3-pip \
    python3.11-venv \
    ffmpeg \
    wget \
    curl \
    aria2 \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    && rm -rf /var/lib/apt/lists/*

# Set Python 3.11 as default
RUN ln -sf /usr/bin/python3.11 /usr/bin/python && \
    ln -sf /usr/bin/python3.11 /usr/bin/python3

# Upgrade pip
RUN python -m pip install --upgrade pip

# Install PyTorch 2.9.1 with CUDA 12.8 FIRST (required for RTX 50xx Blackwell)
RUN pip install torch==2.9.1 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

# Create workspace
WORKDIR /workspace

# Clone ComfyUI and install requirements
RUN git clone https://github.com/comfyanonymous/ComfyUI.git && \
    cd ComfyUI && \
    pip install -r requirements.txt

# ============================================
# Only ComfyUI-Manager pre-installed (required)
# All other nodes installed dynamically via Toolkit
# ============================================

WORKDIR /workspace/ComfyUI/custom_nodes

# ComfyUI Manager (essential - required for node management)
RUN git clone https://github.com/ltdrdata/ComfyUI-Manager.git

# ============================================
# Create model directories
# ============================================

WORKDIR /workspace/ComfyUI

RUN mkdir -p models/checkpoints \
    models/clip \
    models/clip_vision \
    models/vae \
    models/unet \
    models/diffusion_models \
    models/loras \
    models/text_encoders \
    models/audio_encoders

# ============================================
# Startup Scripts (in /opt to survive volume mount)
# ============================================

# Copy startup scripts to /opt (won't be overwritten by volume)
COPY start.sh /opt/cindergrace/start.sh
COPY link_models.sh /opt/cindergrace/link_models.sh
RUN chmod +x /opt/cindergrace/start.sh /opt/cindergrace/link_models.sh

WORKDIR /workspace

# Expose ports (ComfyUI + Toolkit)
EXPOSE 8188 7861

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s \
    CMD curl -f http://localhost:8188/system_stats || exit 1

# Start command
CMD ["/opt/cindergrace/start.sh"]
