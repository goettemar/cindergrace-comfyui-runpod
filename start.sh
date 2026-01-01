#!/bin/bash
# CINDERGRACE ComfyUI Startup Script for RunPod
# With Auto-Update and Toolkit Integration

set -e

echo "=========================================="
echo "  CINDERGRACE ComfyUI for RunPod"
echo "=========================================="
echo ""

# ============================================
# 1. ComfyUI Auto-Update
# ============================================
if [ "${SKIP_UPDATE:-false}" != "true" ]; then
    echo "[1/4] Updating ComfyUI..."
    cd /workspace/ComfyUI

    # Fetch and check for updates
    git fetch --quiet
    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse @{u} 2>/dev/null || echo "$LOCAL")

    if [ "$LOCAL" != "$REMOTE" ]; then
        echo "      New version available, pulling..."
        git pull --quiet
        echo "      Installing requirements..."
        pip install -q -r requirements.txt
        echo "      [OK] ComfyUI updated"
    else
        echo "      [OK] ComfyUI already up-to-date"
    fi

    # Update custom nodes
    echo ""
    echo "[2/4] Updating custom nodes..."
    cd /workspace/ComfyUI/custom_nodes
    UPDATE_COUNT=0
    for dir in */; do
        if [ -d "$dir/.git" ]; then
            cd "$dir"
            git fetch --quiet 2>/dev/null || true
            LOCAL=$(git rev-parse HEAD 2>/dev/null)
            REMOTE=$(git rev-parse @{u} 2>/dev/null || echo "$LOCAL")
            if [ "$LOCAL" != "$REMOTE" ]; then
                git pull --quiet 2>/dev/null || true
                if [ -f "requirements.txt" ]; then
                    pip install -q -r requirements.txt 2>/dev/null || true
                fi
                ((UPDATE_COUNT++))
            fi
            cd ..
        fi
    done
    echo "      [OK] $UPDATE_COUNT nodes updated"
else
    echo "[1/4] Skipping ComfyUI update (SKIP_UPDATE=true)"
    echo "[2/4] Skipping custom nodes update"
fi

# ============================================
# 2. Cindergrace Toolkit Setup
# ============================================
echo ""
echo "[3/4] Setting up Cindergrace Toolkit..."

TOOLKIT_DIR="/workspace/cindergrace_toolkit"
TOOLKIT_REPO="https://github.com/cindergrace/cindergrace_toolkit.git"

if [ -d "$TOOLKIT_DIR/.git" ]; then
    # Update existing installation
    cd "$TOOLKIT_DIR"
    git fetch --quiet
    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse @{u} 2>/dev/null || echo "$LOCAL")

    if [ "$LOCAL" != "$REMOTE" ]; then
        git pull --quiet
        pip install -q -r requirements.txt
        echo "      [OK] Toolkit updated"
    else
        echo "      [OK] Toolkit already up-to-date"
    fi
else
    # Fresh clone
    echo "      Cloning Cindergrace Toolkit..."
    git clone --quiet "$TOOLKIT_REPO" "$TOOLKIT_DIR"
    cd "$TOOLKIT_DIR"
    pip install -q -r requirements.txt
    echo "      [OK] Toolkit installed"
fi

# ============================================
# 3. Model Linking
# ============================================
echo ""
echo "[4/4] Linking models..."

if [ -d "/workspace/models" ]; then
    /opt/cindergrace/link_models.sh
else
    echo "      [WARN] No models found at /workspace/models"
    echo "             Attach a Network Volume with your models."
fi

# ============================================
# 4. Start Services
# ============================================
echo ""
echo "=========================================="
echo "  Starting Services"
echo "=========================================="
echo ""

# Start Toolkit in background (Port 7861)
if [ "${DISABLE_TOOLKIT:-false}" != "true" ]; then
    echo "Starting Cindergrace Toolkit on port 7861..."
    cd "$TOOLKIT_DIR"
    python app.py --port 7861 &
    TOOLKIT_PID=$!
    echo "  Toolkit PID: $TOOLKIT_PID"
fi

# Display connection info
echo ""
echo "=========================================="
echo "  Connection URLs"
echo "=========================================="
echo ""
echo "  ComfyUI:  https://${RUNPOD_POD_ID}-8188.proxy.runpod.net"
echo "  Toolkit:  https://${RUNPOD_POD_ID}-7861.proxy.runpod.net"
echo ""
echo "=========================================="
echo ""

# Start ComfyUI (foreground)
cd /workspace/ComfyUI
exec python main.py \
    --listen 0.0.0.0 \
    --port 8188 \
    --enable-cors-header \
    --preview-method auto
