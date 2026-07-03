#!/usr/bin/env bash
# 下载 PixelWave SDXL 11 + sdxl_vae_fp16_fix 到外置 models_shared/
# 用法：./scripts/download_pixelwave.sh
# 支持断点续传（curl -C -），可重复执行。

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CKPT_DIR="${PROJECT_ROOT}/models_shared/checkpoints"
VAE_DIR="${PROJECT_ROOT}/models_shared/vae"

mkdir -p "${CKPT_DIR}" "${VAE_DIR}"

# ----- 资源清单 -----
PIXELWAVE_URL="https://civitai.com/api/download/models/542574"
PIXELWAVE_FILE="${CKPT_DIR}/pixelwave_sdxl11.safetensors"
PIXELWAVE_EXPECT_GB="6.4"   # ~6.46 GB

VAE_URL="https://huggingface.co/madebyollin/sdxl-vae-fp16-fix/resolve/main/sdxl_vae.safetensors"
VAE_FILE="${VAE_DIR}/sdxl_vae_fp16_fix.safetensors"
VAE_EXPECT_MB="335"          # ~335 MB（仓库里是 fp32 权重，名字 fp16-fix 指偏色修复，不是 fp16 文件）

echo "=========================================="
echo "  Downloading PixelWave SDXL 11 + VAE"
echo "  Project : ${PROJECT_ROOT}"
echo "=========================================="

# ----- 1) PixelWave SDXL 11 -----
if [[ -f "${PIXELWAVE_FILE}" ]]; then
  size_gb=$(du -sh "${PIXELWAVE_FILE}" | awk '{print $1}')
  echo "[1/2] PixelWave already exists (${size_gb}). Resuming if incomplete..."
fi
echo "[1/2] curl -> ${PIXELWAVE_FILE}"
curl -L -C - --fail --retry 5 --retry-delay 5 \
  --progress-bar \
  -o "${PIXELWAVE_FILE}" \
  "${PIXELWAVE_URL}"

# ----- 2) SDXL fp16-fix VAE -----
if [[ -f "${VAE_FILE}" ]]; then
  size_mb=$(du -sh "${VAE_FILE}" | awk '{print $1}')
  echo "[2/2] VAE already exists (${size_mb}). Resuming if incomplete..."
fi
echo "[2/2] curl -> ${VAE_FILE}"
curl -L -C - --fail --retry 5 --retry-delay 5 \
  --progress-bar \
  -o "${VAE_FILE}" \
  "${VAE_URL}"

echo ""
echo "=========================================="
echo "  Verifying downloads"
echo "=========================================="
ls -lh "${PIXELWAVE_FILE}" "${VAE_FILE}"

# 简单大小校验（防止半截文件）
pw_bytes=$(stat -f%z "${PIXELWAVE_FILE}")
vae_bytes=$(stat -f%z "${VAE_FILE}")

if (( pw_bytes < 6000000000 )); then
  echo "❌ PixelWave size suspicious: ${pw_bytes} bytes (expect ~6.4 GB)"
  exit 1
fi
if (( vae_bytes < 250000000 )); then
  echo "❌ VAE size suspicious: ${vae_bytes} bytes (expect ~335 MB)"
  exit 1
fi

echo "✅ Both files look good. PixelWave is ready."
echo ""
echo "Next steps:"
echo "  1) ./scripts/start_comfyui.sh"
echo "  2) Open http://127.0.0.1:8188"
echo "  3) Drag workflows/sdxl/pixelwave_test.json into ComfyUI"
