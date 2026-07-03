#!/usr/bin/env bash
# 一键启动 ComfyUI（Apple Silicon / MPS）
# 用法：./scripts/start_comfyui.sh [extra args...]

set -euo pipefail

# --- 项目根目录（脚本所在目录的上级） ---
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMFY_DIR="${PROJECT_ROOT}/ComfyUI"
OUTPUT_DIR="${PROJECT_ROOT}/outputs/AITex"
INPUT_DIR="${PROJECT_ROOT}/inputs"

# --- 激活 conda 环境 ---
# shellcheck disable=SC1091
source /opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh
conda activate comfyui

# --- 按日期归档输出 ---
DATE_DIR="${OUTPUT_DIR}/$(date +%Y-%m-%d)"
mkdir -p "${DATE_DIR}" "${INPUT_DIR}"

cd "${COMFY_DIR}"

echo "============================================"
echo "  ComfyUI starting on Apple Silicon (MPS)"
echo "  Project : ${PROJECT_ROOT}"
echo "  Output  : ${DATE_DIR}"
echo "  URL     : http://127.0.0.1:8188"
echo "============================================"

# --force-fp16    : Apple Silicon 上 fp16 性能最佳
# --listen 127... : 仅本机访问（如需局域网访问改为 0.0.0.0）
# --preview-method auto : 采样过程中显示预览
exec python main.py \
  --force-fp16 \
  --listen 127.0.0.1 \
  --port 8188 \
  --preview-method auto \
  --output-directory "${DATE_DIR}" \
  --input-directory "${INPUT_DIR}" \
  "$@"
