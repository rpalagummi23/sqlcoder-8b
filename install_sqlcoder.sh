#!/bin/bash

# =============================================================================
# SQLCoder-8B Installation Script for Ubuntu
# Model: defog/sqlcoder-8b with FP16 precision
# Deployment: vLLM with OpenAI-compatible API
# =============================================================================

set -e  # Exit on any error

echo "=============================================="
echo "SQLCoder-8B Installation Script"
echo "=============================================="

# -----------------------------------------------------------------------------
# STEP 1: System Update
# -----------------------------------------------------------------------------
echo ""
echo "[1/7] Updating system packages..."
sudo apt update && sudo apt upgrade -y

# -----------------------------------------------------------------------------
# STEP 2: Install Essential Dependencies
# -----------------------------------------------------------------------------
echo ""
echo "[2/7] Installing essential dependencies..."
sudo apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    git \
    curl \
    wget \
    build-essential

# -----------------------------------------------------------------------------
# STEP 3: Check NVIDIA Driver and CUDA
# -----------------------------------------------------------------------------
echo ""
echo "[3/7] Checking NVIDIA driver and CUDA..."

if ! command -v nvidia-smi &> /dev/null; then
    echo "NVIDIA driver not found. Installing..."
    sudo apt install -y nvidia-driver-535
    echo "⚠️  NVIDIA driver installed. Please REBOOT and re-run this script."
    exit 1
else
    echo "✅ NVIDIA driver found:"
    nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv
fi

# Check CUDA
if ! command -v nvcc &> /dev/null; then
    echo "Installing CUDA toolkit..."
    sudo apt install -y nvidia-cuda-toolkit
fi

# -----------------------------------------------------------------------------
# STEP 4: Create Python Virtual Environment
# -----------------------------------------------------------------------------
echo ""
echo "[4/7] Creating Python virtual environment..."

VENV_DIR="$HOME/sqlcoder-venv"

if [ -d "$VENV_DIR" ]; then
    echo "Virtual environment already exists at $VENV_DIR"
else
    python3 -m venv "$VENV_DIR"
    echo "✅ Virtual environment created at $VENV_DIR"
fi

# Activate virtual environment
source "$VENV_DIR/bin/activate"

# Upgrade pip
pip install --upgrade pip

# -----------------------------------------------------------------------------
# STEP 5: Install vLLM and Dependencies
# -----------------------------------------------------------------------------
echo ""
echo "[5/7] Installing vLLM and dependencies..."

pip install vllm
pip install huggingface_hub

# -----------------------------------------------------------------------------
# STEP 6: Download SQLCoder-8B Model
# -----------------------------------------------------------------------------
echo ""
echo "[6/7] Downloading SQLCoder-8B model..."
echo "This may take a while depending on your internet speed (~16GB download)..."

# Pre-download the model to cache
python3 -c "
from huggingface_hub import snapshot_download
snapshot_download(
    repo_id='defog/sqlcoder-8b',
    local_dir_use_symlinks=False
)
print('✅ Model downloaded successfully!')
"

# -----------------------------------------------------------------------------
# STEP 7: Create Startup Script
# -----------------------------------------------------------------------------
echo ""
echo "[7/7] Creating startup script..."

STARTUP_SCRIPT="$HOME/start_sqlcoder.sh"

cat > "$STARTUP_SCRIPT" << 'EOF'
#!/bin/bash

# Activate virtual environment
source "$HOME/sqlcoder-venv/bin/activate"

echo "=============================================="
echo "Starting SQLCoder-8B Server"
echo "=============================================="
echo ""
echo "Model: defog/sqlcoder-8b"
echo "Precision: FP16 (float16)"
echo "API: OpenAI-compatible at http://localhost:8000"
echo ""
echo "To test, use:"
echo "  curl http://localhost:8000/v1/models"
echo ""
echo "Press Ctrl+C to stop the server"
echo "=============================================="
echo ""

# Start vLLM server with SQLCoder-8B
python -m vllm.entrypoints.openai.api_server \
    --model defog/sqlcoder-8b \
    --dtype float16 \
    --host 0.0.0.0 \
    --port 8000 \
    --max-model-len 4096 \
    --gpu-memory-utilization 0.85
EOF

chmod +x "$STARTUP_SCRIPT"

# -----------------------------------------------------------------------------
# DONE
# -----------------------------------------------------------------------------
echo ""
echo "=============================================="
echo "✅ INSTALLATION COMPLETE!"
echo "=============================================="
echo ""
echo "To start SQLCoder-8B server, run:"
echo "  $STARTUP_SCRIPT"
echo ""
echo "The server will be available at:"
echo "  http://localhost:8000"
echo ""
echo "API Endpoints:"
echo "  - POST /v1/completions     (text completion)"
echo "  - POST /v1/chat/completions (chat format)"
echo "  - GET  /v1/models          (list models)"
echo ""
echo "=============================================="

