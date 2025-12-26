# CINDERGRACE ComfyUI RunPod Template
# Optimized for Wan 2.2 FP8, Flux, and video generation workflows
# CUDA 12.4 for broad GPU support (RTX 30xx/40xx/50xx, A100, H100)
FROM nvidia/cuda:12.4.1-cudnn-runtime-ubuntu22.04

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

# Install PyTorch FIRST (before ComfyUI requirements)
RUN pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124

# Create workspace
WORKDIR /workspace

# Clone ComfyUI and install remaining requirements
RUN git clone https://github.com/comfyanonymous/ComfyUI.git && \
    cd ComfyUI && \
    pip install -r requirements.txt

# ============================================
# Custom Nodes for CINDERGRACE
# ============================================

WORKDIR /workspace/ComfyUI/custom_nodes

# ComfyUI Manager (essential)
RUN git clone https://github.com/ltdrdata/ComfyUI-Manager.git

# Video/Wan Support
RUN git clone https://github.com/kijai/ComfyUI-WanVideoWrapper.git && \
    cd ComfyUI-WanVideoWrapper && pip install -r requirements.txt

# Florence-2 (Image Analysis)
RUN git clone https://github.com/kijai/ComfyUI-Florence2.git && \
    cd ComfyUI-Florence2 && pip install -r requirements.txt

# GGUF Support (Quantized Models)
RUN git clone https://github.com/city96/ComfyUI-GGUF.git

# Custom Scripts (ShowText etc)
RUN git clone https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git

# Video Helper Suite
RUN git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git && \
    cd ComfyUI-VideoHelperSuite && pip install -r requirements.txt

# LTX-Video Support
RUN git clone https://github.com/Lightricks/ComfyUI-LTXVideo.git && \
    cd ComfyUI-LTXVideo && pip install -r requirements.txt || true

# Impact Pack (useful utilities)
RUN git clone https://github.com/ltdrdata/ComfyUI-Impact-Pack.git && \
    cd ComfyUI-Impact-Pack && pip install -r requirements.txt || true

# ============================================
# Create model directories
# ============================================

WORKDIR /workspace/ComfyUI

RUN mkdir -p models/checkpoints \
    models/clip \
    models/vae \
    models/unet \
    models/diffusion_models \
    models/loras \
    models/audio_encoders

# ============================================
# Startup Scripts
# ============================================

WORKDIR /workspace

# Copy startup scripts
COPY start.sh /workspace/start.sh
COPY link_models.sh /workspace/link_models.sh
RUN chmod +x /workspace/start.sh /workspace/link_models.sh

# Expose ComfyUI port
EXPOSE 8188

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s \
    CMD curl -f http://localhost:8188/system_stats || exit 1

# Start command
CMD ["/workspace/start.sh"]
