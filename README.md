# SQLCoder-8B Local Deployment Guide

Deploy SQLCoder-8B with FP16 precision using vLLM on Ubuntu.

## System Requirements

| Component | Minimum | Your System |
|-----------|---------|-------------|
| GPU VRAM | 16 GB | RTX 4000 ADA (20 GB) ✅ |
| RAM | 32 GB | 128 GB ✅ |
| Storage | 30 GB free | - |
| OS | Ubuntu 20.04+ | - |

## Quick Start

### 1. Install Everything

```bash
chmod +x install_sqlcoder.sh
./install_sqlcoder.sh
```

> **Note:** If NVIDIA drivers are not installed, the script will install them and ask you to reboot. After reboot, run the script again.

### 2. Start the Server

```bash
~/start_sqlcoder.sh
```

The server will start at `http://localhost:8000` with an OpenAI-compatible API.

### 3. Test the Installation

```bash
# In a new terminal
source ~/sqlcoder-venv/bin/activate
python test_sqlcoder.py
```

## API Usage

### Check Server Status

```bash
curl http://localhost:8000/v1/models
```

### Generate SQL (cURL)

```bash
curl -X POST http://localhost:8000/v1/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "defog/sqlcoder-8b",
    "prompt": "### Task\nGenerate a SQL query to answer: How many users signed up last month?\n\n### Schema\nCREATE TABLE users (id INT, name VARCHAR, created_at TIMESTAMP);\n\n### SQL\n",
    "max_tokens": 256,
    "temperature": 0
  }'
```

### Generate SQL (Python)

```python
import requests

response = requests.post(
    "http://localhost:8000/v1/completions",
    json={
        "model": "defog/sqlcoder-8b",
        "prompt": "Your prompt here...",
        "max_tokens": 256,
        "temperature": 0
    }
)
sql = response.json()["choices"][0]["text"]
```

## Configuration Options

### Adjust GPU Memory Usage

Edit `~/start_sqlcoder.sh` and modify `--gpu-memory-utilization`:

```bash
--gpu-memory-utilization 0.85  # Uses 85% of VRAM (default)
--gpu-memory-utilization 0.70  # Uses 70% of VRAM (more headroom)
```

### Change Port

```bash
--port 8000  # Default
--port 8080  # Alternative
```

## Supported Databases

SQLCoder-8B generates SQL for:

- ✅ PostgreSQL
- ✅ MySQL
- ✅ SQL Server
- ✅ SQLite
- ✅ SAP HANA
- ✅ Snowflake
- ✅ BigQuery
- ✅ Oracle

Just include the appropriate schema in your prompt, and the model will generate dialect-appropriate SQL.

## Troubleshooting

### "CUDA out of memory"

Reduce memory utilization:
```bash
--gpu-memory-utilization 0.70
```

Or use quantization (edit start script):
```bash
--dtype float16  # Change to:
--dtype auto --quantization awq  # For 4-bit quantization
```

### Server won't start

1. Check NVIDIA driver: `nvidia-smi`
2. Check CUDA: `nvcc --version`
3. Verify vLLM installation: `pip show vllm`

### Slow first response

The first request after server start is slow because the model needs to warm up. Subsequent requests will be much faster.

## Files Created

| File | Purpose |
|------|---------|
| `install_sqlcoder.sh` | One-time installation script |
| `~/start_sqlcoder.sh` | Server startup script |
| `~/sqlcoder-venv/` | Python virtual environment |
| `test_sqlcoder.py` | Test script with examples |

## Performance Tips

1. **Keep the server running** — Starting up takes time, so leave it running
2. **Use temperature=0** — For deterministic, accurate SQL
3. **Provide complete schemas** — More context = better SQL
4. **Batch requests** — vLLM handles concurrent requests efficiently

