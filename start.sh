#!/bin/bash
# CINDERGRACE ComfyUI Startup Script for RunPod
# With Auto-Update, Custom Nodes Sync, and Toolkit Integration

set -e

echo "==========================================="
echo "  CINDERGRACE ComfyUI for RunPod"
echo "==========================================="
echo ""

TOOLKIT_DIR="/workspace/cindergrace_toolkit"
TOOLKIT_REPO="https://github.com/goettemar/cindergrace_toolkit.git"
COMFYUI_DIR="/workspace/ComfyUI"

# ============================================
# 1. Cindergrace Toolkit Setup (FIRST - we need sync scripts)
# ============================================
echo "[1/6] Setting up Cindergrace Toolkit..."

if [ -d "$TOOLKIT_DIR/.git" ]; then
    cd "$TOOLKIT_DIR"
    git fetch --quiet
    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse @{u} 2>/dev/null || echo "$LOCAL")

    if [ "$LOCAL" != "$REMOTE" ]; then
        git pull --quiet
        pip install -q -r requirements.txt 2>/dev/null || true
        echo "      [OK] Toolkit updated"
    else
        echo "      [OK] Toolkit already up-to-date"
    fi
else
    echo "      Cloning Cindergrace Toolkit..."
    git clone --quiet "$TOOLKIT_REPO" "$TOOLKIT_DIR"
    cd "$TOOLKIT_DIR"
    pip install -q -r requirements.txt 2>/dev/null || true
    echo "      [OK] Toolkit installed"
fi

# ============================================
# 2. ComfyUI Auto-Update
# ============================================
if [ "${SKIP_UPDATE:-false}" != "true" ]; then
    echo ""
    echo "[2/6] Updating ComfyUI..."
    cd "$COMFYUI_DIR"

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
else
    echo ""
    echo "[2/6] Skipping ComfyUI update (SKIP_UPDATE=true)"
fi

# ============================================
# 3. Sync Custom Nodes from Toolkit Config
# ============================================
echo ""
echo "[3/6] Syncing Custom Nodes..."

SYNC_NODES_SCRIPT="$TOOLKIT_DIR/scripts/sync_nodes.py"
if [ -f "$SYNC_NODES_SCRIPT" ]; then
    python "$SYNC_NODES_SCRIPT" --comfyui-path "$COMFYUI_DIR" --quiet
    echo "      [OK] Custom nodes synced"
else
    echo "      [WARN] sync_nodes.py not found, skipping"

    # Fallback: Update existing custom nodes manually
    if [ "${SKIP_UPDATE:-false}" != "true" ]; then
        echo "      Updating existing custom nodes..."
        cd "$COMFYUI_DIR/custom_nodes"
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
                    ((UPDATE_COUNT++)) || true
                fi
                cd ..
            fi
        done
        echo "      [OK] $UPDATE_COUNT nodes updated"
    fi
fi

# ============================================
# 4. Sync Workflows from Toolkit
# ============================================
echo ""
echo "[4/6] Syncing Workflows..."

SYNC_WORKFLOWS_SCRIPT="$TOOLKIT_DIR/scripts/sync_workflows.py"
if [ -f "$SYNC_WORKFLOWS_SCRIPT" ]; then
    python "$SYNC_WORKFLOWS_SCRIPT" --comfyui-path "$COMFYUI_DIR" --quiet
    echo "      [OK] Workflows synced"
else
    echo "      [SKIP] sync_workflows.py not found"
fi

# ============================================
# 5. Model Linking
# ============================================
echo ""
echo "[5/6] Linking models..."

if [ -d "/workspace/models" ]; then
    /opt/cindergrace/link_models.sh
else
    echo "      [WARN] No models found at /workspace/models"
    echo "             Attach a Network Volume with your models."
fi

# ============================================
# 6. Start Services
# ============================================
echo ""
echo "==========================================="
echo "  Starting Services"
echo "==========================================="
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
echo "==========================================="
echo "  Connection URLs"
echo "==========================================="
echo ""
echo "  ComfyUI:  https://${RUNPOD_POD_ID}-8188.proxy.runpod.net"
echo "  Toolkit:  https://${RUNPOD_POD_ID}-7861.proxy.runpod.net"
echo ""
echo "==========================================="
echo ""

# Start ComfyUI (foreground)
cd "$COMFYUI_DIR"
exec python main.py \
    --listen 0.0.0.0 \
    --port 8188 \
    --enable-cors-header \
    --preview-method auto
