#!/bin/bash
# Link models from Network Volume to ComfyUI

VOLUME_MODELS="/workspace/models"
COMFY_MODELS="/workspace/ComfyUI/models"

echo "Linking models from $VOLUME_MODELS to $COMFY_MODELS"

# Function to create symlinks for all files in a folder
link_folder() {
    local src="$1"
    local dst="$2"
    local name="$3"
    local count=0

    if [ -d "$src" ]; then
        mkdir -p "$dst"
        for file in "$src"/*; do
            if [ -f "$file" ]; then
                filename=$(basename "$file")
                if [ ! -e "$dst/$filename" ]; then
                    ln -sf "$file" "$dst/$filename"
                    ((count++))
                fi
            fi
        done
        echo "  [OK] $name: $count files linked"
    else
        echo "  [--] $name: folder not found"
    fi
}

# Link all model folders
link_folder "$VOLUME_MODELS/clip" "$COMFY_MODELS/clip" "clip"
link_folder "$VOLUME_MODELS/vae" "$COMFY_MODELS/vae" "vae"
link_folder "$VOLUME_MODELS/diffusion_models" "$COMFY_MODELS/diffusion_models" "diffusion_models"
link_folder "$VOLUME_MODELS/unet" "$COMFY_MODELS/unet" "unet"
link_folder "$VOLUME_MODELS/loras" "$COMFY_MODELS/loras" "loras"
link_folder "$VOLUME_MODELS/audio_encoders" "$COMFY_MODELS/audio_encoders" "audio_encoders"
link_folder "$VOLUME_MODELS/checkpoints" "$COMFY_MODELS/checkpoints" "checkpoints"

# Link input/output folders for persistence
if [ -d "$VOLUME_MODELS/../input" ]; then
    ln -sf "$VOLUME_MODELS/../input" "/workspace/ComfyUI/input_volume"
    echo "  [OK] input folder linked"
fi

if [ -d "$VOLUME_MODELS/../output" ]; then
    rm -rf "/workspace/ComfyUI/output" 2>/dev/null || true
    ln -sf "$VOLUME_MODELS/../output" "/workspace/ComfyUI/output"
    echo "  [OK] output folder linked (persistent)"
else
    mkdir -p "$VOLUME_MODELS/../output"
    rm -rf "/workspace/ComfyUI/output" 2>/dev/null || true
    ln -sf "$VOLUME_MODELS/../output" "/workspace/ComfyUI/output"
    echo "  [OK] output folder created & linked"
fi

echo ""
echo "Model Summary:"
echo "  clip:             $(ls -1 $COMFY_MODELS/clip 2>/dev/null | wc -l) files"
echo "  vae:              $(ls -1 $COMFY_MODELS/vae 2>/dev/null | wc -l) files"
echo "  diffusion_models: $(ls -1 $COMFY_MODELS/diffusion_models 2>/dev/null | wc -l) files"
echo "  unet:             $(ls -1 $COMFY_MODELS/unet 2>/dev/null | wc -l) files"
echo "  loras:            $(ls -1 $COMFY_MODELS/loras 2>/dev/null | wc -l) files"
echo "  audio_encoders:   $(ls -1 $COMFY_MODELS/audio_encoders 2>/dev/null | wc -l) files"
echo ""
