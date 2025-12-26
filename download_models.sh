#!/bin/bash
# Download models for CINDERGRACE on RunPod
# Run this on a CPU pod with Network Volume attached at /workspace

set -e

MODELS_PATH="/workspace/models"

echo "=========================================="
echo "  CINDERGRACE Model Downloader"
echo "=========================================="
echo ""

# Check if we're on a Network Volume
if [ ! -d "/workspace" ]; then
    echo "[ERROR] /workspace not found!"
    echo "        Make sure you have a Network Volume attached."
    exit 1
fi

# Install aria2 for fast downloads
if ! command -v aria2c &> /dev/null; then
    echo "Installing aria2..."
    apt-get update && apt-get install -y aria2
fi

# Create directories
echo "Creating model directories..."
mkdir -p "$MODELS_PATH/clip"
mkdir -p "$MODELS_PATH/vae"
mkdir -p "$MODELS_PATH/diffusion_models"
mkdir -p "$MODELS_PATH/unet"
mkdir -p "$MODELS_PATH/loras"
mkdir -p "$MODELS_PATH/audio_encoders"
mkdir -p "/workspace/input"
mkdir -p "/workspace/output"

# Download function
download() {
    local url="$1"
    local dir="$2"
    local filename="$3"
    local filepath="$dir/$filename"

    if [ -f "$filepath" ]; then
        echo "  [SKIP] $filename (already exists)"
    else
        echo "  [DOWN] $filename"
        aria2c -x 16 -s 16 -d "$dir" -o "$filename" "$url"
    fi
}

echo ""
echo "=========================================="
echo "Select model set:"
echo "=========================================="
echo "1) Minimal - Wan 2.2 I2V only (~36 GB)"
echo "2) Standard - Wan + Flux (~58 GB)"
echo "3) Full - Wan + Flux + S2V (~76 GB)"
echo ""
read -p "Enter choice [1-3]: " choice

echo ""
echo "Downloading models..."
echo ""

# ============================================
# CORE MODELS (always needed)
# ============================================

echo "--- Core Models ---"

# UMT5-XXL Text Encoder (required for Wan)
download \
    "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" \
    "$MODELS_PATH/clip" \
    "umt5_xxl_fp8_e4m3fn_scaled.safetensors"

# Wan 2.1 VAE
download \
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors" \
    "$MODELS_PATH/vae" \
    "wan_2.1_vae.safetensors"

# Wan 2.2 I2V HighNoise FP8
download \
    "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors" \
    "$MODELS_PATH/diffusion_models" \
    "wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors"

# Wan 2.2 I2V LowNoise FP8
download \
    "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_i2v_low_noise_14B_fp8_scaled.safetensors" \
    "$MODELS_PATH/diffusion_models" \
    "wan2.2_i2v_low_noise_14B_fp8_scaled.safetensors"

# ============================================
# FLUX MODELS (choice 2 or 3)
# ============================================

if [ "$choice" -ge 2 ]; then
    echo ""
    echo "--- Flux Models ---"

    # CLIP-L
    download \
        "https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/clip_l.safetensors" \
        "$MODELS_PATH/clip" \
        "clip_l.safetensors"

    # T5-XXL FP16
    download \
        "https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/t5xxl_fp16.safetensors" \
        "$MODELS_PATH/clip" \
        "t5xxl_fp16.safetensors"

    # Flux VAE
    download \
        "https://huggingface.co/ffxvs/vae-flux/resolve/main/ae.safetensors" \
        "$MODELS_PATH/vae" \
        "ae.safetensors"

    # Flux Dev FP8
    download \
        "https://huggingface.co/Kijai/flux-fp8/resolve/main/flux1-dev-fp8-e4m3fn.safetensors" \
        "$MODELS_PATH/unet" \
        "flux1-dev-fp8-e4m3fn.safetensors"
fi

# ============================================
# S2V MODELS (choice 3)
# ============================================

if [ "$choice" -ge 3 ]; then
    echo ""
    echo "--- S2V Models ---"

    # Wan 2.2 S2V
    download \
        "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_s2v_14B_fp8_scaled.safetensors" \
        "$MODELS_PATH/diffusion_models" \
        "wan2.2_s2v_14B_fp8_scaled.safetensors"

    # Audio Encoder
    download \
        "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/audio_encoders/wav2vec2_large_english_fp16.safetensors" \
        "$MODELS_PATH/audio_encoders" \
        "wav2vec2_large_english_fp16.safetensors"

    # LightX2V LoRA
    download \
        "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/loras/wan2.2_t2v_lightx2v_4steps_lora_v1.1_low_noise.safetensors" \
        "$MODELS_PATH/loras" \
        "wan2.2_t2v_lightx2v_4steps_lora_v1.1_low_noise.safetensors"
fi

echo ""
echo "=========================================="
echo "  Download Complete!"
echo "=========================================="
echo ""
echo "Disk usage:"
du -sh "$MODELS_PATH"/*
echo ""
echo "Total:"
du -sh "$MODELS_PATH"
echo ""
echo "Next steps:"
echo "1. Stop this CPU pod"
echo "2. Start a GPU pod with the same Network Volume"
echo "3. Use the CINDERGRACE ComfyUI template"
echo "4. Connect CINDERGRACE to the ComfyUI URL"
echo ""
