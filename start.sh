#!/bin/bash
# CINDERGRACE ComfyUI Startup Script for RunPod

set -e

echo "=========================================="
echo "  CINDERGRACE ComfyUI for RunPod"
echo "=========================================="
echo ""

# Check for Network Volume
if [ -d "/workspace/models" ]; then
    echo "[OK] Network Volume detected at /workspace/models"

    # Link models from Network Volume
    echo ""
    echo "Linking models from Network Volume..."
    /opt/cindergrace/link_models.sh
else
    echo "[WARN] No models found at /workspace/models"
    echo "       Please attach a Network Volume with your models."
    echo ""
    echo "       Expected structure:"
    echo "       /workspace/models/"
    echo "       ├── clip/"
    echo "       ├── vae/"
    echo "       ├── diffusion_models/"
    echo "       ├── unet/"
    echo "       ├── loras/"
    echo "       └── audio_encoders/"
fi

# Update custom nodes (optional)
if [ "${UPDATE_NODES:-false}" = "true" ]; then
    echo ""
    echo "Updating custom nodes..."
    cd /workspace/ComfyUI/custom_nodes
    for dir in */; do
        if [ -d "$dir/.git" ]; then
            echo "  Updating $dir..."
            cd "$dir"
            git pull --quiet || true
            cd ..
        fi
    done
fi

# Display connection info
echo ""
echo "=========================================="
echo "  ComfyUI is starting..."
echo "=========================================="
echo ""
echo "CINDERGRACE Settings:"
echo "  ComfyUI URL: https://${RUNPOD_POD_ID}-8188.proxy.runpod.net"
echo ""
echo "Copy this URL into CINDERGRACE → Settings → ComfyUI URL"
echo ""
echo "=========================================="
echo ""

# Start ComfyUI
cd /workspace/ComfyUI

exec python main.py \
    --listen 0.0.0.0 \
    --port 8188 \
    --enable-cors-header \
    --preview-method auto
