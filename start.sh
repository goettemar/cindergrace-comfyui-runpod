#!/bin/bash
# CINDERGRACE ComfyUI Startup Script for RunPod
# With Auto-Update, Custom Nodes Sync, and Toolkit Integration
# Includes error handling and logging for robustness

# Don't exit on error - we want to continue even if some steps fail
set +e

echo "==========================================="
echo "  CINDERGRACE ComfyUI for RunPod"
echo "==========================================="
echo ""

TOOLKIT_DIR="/workspace/cindergrace_toolkit"
TOOLKIT_REPO="https://github.com/goettemar/cindergrace_toolkit.git"
COMFYUI_DIR="/workspace/ComfyUI"
LOGS_DIR="$TOOLKIT_DIR/logs"
ERROR_LOG="$LOGS_DIR/startup_errors.log"

# Ensure logs directory exists
mkdir -p "$LOGS_DIR" 2>/dev/null || true

# Clear startup error log
> "$ERROR_LOG" 2>/dev/null || true

# Function to log errors
log_error() {
    local step="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$step] $message" >> "$ERROR_LOG" 2>/dev/null || true
    echo "      [ERROR] $message"
}

# ============================================
# 1. Cindergrace Toolkit Setup (FIRST - we need sync scripts)
# ============================================
echo "[1/6] Setting up Cindergrace Toolkit..."

TOOLKIT_OK=true

if [ -d "$TOOLKIT_DIR/.git" ]; then
    cd "$TOOLKIT_DIR"
    if timeout 60 git fetch --quiet 2>/dev/null; then
        LOCAL=$(git rev-parse HEAD 2>/dev/null)
        REMOTE=$(git rev-parse @{u} 2>/dev/null || echo "$LOCAL")

        if [ "$LOCAL" != "$REMOTE" ]; then
            if timeout 120 git pull --quiet 2>/dev/null; then
                pip install -q -r requirements.txt 2>/dev/null || true
                echo "      [OK] Toolkit updated"
            else
                log_error "TOOLKIT" "Git pull failed, using existing version"
            fi
        else
            echo "      [OK] Toolkit already up-to-date"
        fi
    else
        log_error "TOOLKIT" "Git fetch failed (timeout or network issue), using existing version"
    fi
else
    echo "      Cloning Cindergrace Toolkit..."
    if timeout 180 git clone --quiet --depth 1 "$TOOLKIT_REPO" "$TOOLKIT_DIR" 2>/dev/null; then
        cd "$TOOLKIT_DIR"
        pip install -q -r requirements.txt 2>/dev/null || true
        # Recreate logs directory after clone
        mkdir -p "$LOGS_DIR" 2>/dev/null || true
        echo "      [OK] Toolkit installed"
    else
        log_error "TOOLKIT" "Git clone failed - toolkit unavailable"
        TOOLKIT_OK=false
    fi
fi

# ============================================
# 2. ComfyUI Auto-Update
# ============================================
if [ "${SKIP_UPDATE:-false}" != "true" ]; then
    echo ""
    echo "[2/6] Updating ComfyUI..."
    cd "$COMFYUI_DIR"

    if timeout 60 git fetch --quiet 2>/dev/null; then
        LOCAL=$(git rev-parse HEAD 2>/dev/null)
        REMOTE=$(git rev-parse @{u} 2>/dev/null || echo "$LOCAL")

        if [ "$LOCAL" != "$REMOTE" ]; then
            echo "      New version available, pulling..."
            if timeout 120 git pull --quiet 2>/dev/null; then
                echo "      Installing requirements..."
                pip install -q -r requirements.txt 2>/dev/null || true
                echo "      [OK] ComfyUI updated"
            else
                log_error "COMFYUI" "Git pull failed, using existing version"
            fi
        else
            echo "      [OK] ComfyUI already up-to-date"
        fi
    else
        log_error "COMFYUI" "Git fetch failed (timeout or network issue), using existing version"
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
if [ "$TOOLKIT_OK" = true ] && [ -f "$SYNC_NODES_SCRIPT" ]; then
    if python "$SYNC_NODES_SCRIPT" --comfyui-path "$COMFYUI_DIR" --quiet 2>/dev/null; then
        echo "      [OK] Custom nodes synced"
    else
        log_error "NODES" "sync_nodes.py failed, check logs/sync_errors.log"
    fi
else
    if [ "$TOOLKIT_OK" != true ]; then
        echo "      [SKIP] Toolkit not available"
    else
        echo "      [WARN] sync_nodes.py not found, skipping"
    fi

    # Fallback: Update existing custom nodes manually
    if [ "${SKIP_UPDATE:-false}" != "true" ]; then
        echo "      Updating existing custom nodes..."
        cd "$COMFYUI_DIR/custom_nodes"
        UPDATE_COUNT=0
        ERROR_COUNT=0
        for dir in */; do
            if [ -d "$dir/.git" ]; then
                cd "$dir"
                if timeout 60 git fetch --quiet 2>/dev/null; then
                    LOCAL=$(git rev-parse HEAD 2>/dev/null)
                    REMOTE=$(git rev-parse @{u} 2>/dev/null || echo "$LOCAL")
                    if [ "$LOCAL" != "$REMOTE" ]; then
                        if timeout 120 git pull --quiet 2>/dev/null; then
                            if [ -f "requirements.txt" ]; then
                                pip install -q -r requirements.txt 2>/dev/null || true
                            fi
                            ((UPDATE_COUNT++)) || true
                        else
                            log_error "NODES" "Failed to update $dir"
                            ((ERROR_COUNT++)) || true
                        fi
                    fi
                else
                    log_error "NODES" "Failed to fetch $dir (timeout or network)"
                    ((ERROR_COUNT++)) || true
                fi
                cd ..
            fi
        done
        echo "      [OK] $UPDATE_COUNT nodes updated, $ERROR_COUNT errors"
    fi
fi

# ============================================
# 4. Sync Workflows from Toolkit
# ============================================
echo ""
echo "[4/6] Syncing Workflows..."

SYNC_WORKFLOWS_SCRIPT="$TOOLKIT_DIR/scripts/sync_workflows.py"
if [ "$TOOLKIT_OK" = true ] && [ -f "$SYNC_WORKFLOWS_SCRIPT" ]; then
    if python "$SYNC_WORKFLOWS_SCRIPT" --comfyui-path "$COMFYUI_DIR" --quiet 2>/dev/null; then
        echo "      [OK] Workflows synced"
    else
        log_error "WORKFLOWS" "sync_workflows.py failed"
    fi
else
    if [ "$TOOLKIT_OK" != true ]; then
        echo "      [SKIP] Toolkit not available"
    else
        echo "      [SKIP] sync_workflows.py not found"
    fi
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
if [ "${DISABLE_TOOLKIT:-false}" != "true" ] && [ "$TOOLKIT_OK" = true ]; then
    echo "Starting Cindergrace Toolkit on port 7861..."
    cd "$TOOLKIT_DIR"
    python app.py --port 7861 &
    TOOLKIT_PID=$!
    echo "  Toolkit PID: $TOOLKIT_PID"
elif [ "${DISABLE_TOOLKIT:-false}" = "true" ]; then
    echo "Toolkit disabled via DISABLE_TOOLKIT=true"
else
    echo "Toolkit not available (clone failed)"
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
