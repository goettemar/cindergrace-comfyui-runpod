# CINDERGRACE ComfyUI RunPod Template
# Based on ai-dock/comfyui - optimized for cloud deployment
# Adds CINDERGRACE-specific custom nodes
FROM ghcr.io/ai-dock/comfyui:v2-cuda-12.1.1-base-22.04-v0.3.20

# Environment
ENV PYTHONUNBUFFERED=1

# ============================================
# Custom Nodes for CINDERGRACE
# ============================================

WORKDIR /opt/ComfyUI/custom_nodes

# Video/Wan Support (essential for CINDERGRACE)
RUN git clone https://github.com/kijai/ComfyUI-WanVideoWrapper.git && \
    cd ComfyUI-WanVideoWrapper && pip install -r requirements.txt || true

# Florence-2 (Image Analysis)
RUN git clone https://github.com/kijai/ComfyUI-Florence2.git && \
    cd ComfyUI-Florence2 && pip install -r requirements.txt || true

# GGUF Support (Quantized Models)
RUN git clone https://github.com/city96/ComfyUI-GGUF.git || true

# Video Helper Suite
RUN git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git && \
    cd ComfyUI-VideoHelperSuite && pip install -r requirements.txt || true

# LTX-Video Support
RUN git clone https://github.com/Lightricks/ComfyUI-LTXVideo.git && \
    cd ComfyUI-LTXVideo && pip install -r requirements.txt || true

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

# Start command
CMD ["/workspace/start.sh"]
