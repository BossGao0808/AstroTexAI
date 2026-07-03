#!/usr/bin/env bash
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

CKPT_DIR="${PROJECT_ROOT}/models_shared/checkpoints"
VAE_DIR="${PROJECT_ROOT}/models_shared/vae"

mkdir -p "${CKPT_DIR}" "${VAE_DIR}"

# --- Realistic Vision V5.1 checkpoint (~4.27 GB) ---
echo "=== Downloading Realistic Vision V5.1 (checkpoint) ==="
curl -L -C - --fail --retry 5 --retry-delay 5 --progress-bar \
  -o "${CKPT_DIR}/Realistic_Vision_V5.1.safetensors" \
  "https://huggingface.co/SG161222/Realistic_Vision_V5.1_noVAE/resolve/main/Realistic_Vision_V5.1.safetensors"

echo ""
bytes=$(stat -f%z "${CKPT_DIR}/Realistic_Vision_V5.1.safetensors")
(( bytes < 4000000000 )) && { echo "❌ Realistic Vision V5.1 size suspicious: ${bytes} bytes"; exit 1; }
echo "✅ Realistic Vision V5.1: ${bytes} bytes OK"

# --- Recommended VAE (~335 MB) ---
if [ ! -f "${VAE_DIR}/vae-ft-mse-840000-ema-pruned.safetensors" ]; then
  echo ""
  echo "=== Downloading recommended VAE (mse-840000) ==="
  curl -L -C - --fail --retry 5 --retry-delay 5 --progress-bar \
    -o "${VAE_DIR}/vae-ft-mse-840000-ema-pruned.safetensors" \
    "https://huggingface.co/stabilityai/sd-vae-ft-mse-original/resolve/main/vae-ft-mse-840000-ema-pruned.safetensors"

  bytes=$(stat -f%z "${VAE_DIR}/vae-ft-mse-840000-ema-pruned.safetensors")
  (( bytes < 300000000 )) && { echo "❌ VAE size suspicious: ${bytes} bytes"; exit 1; }
  echo "✅ VAE mse-840000: ${bytes} bytes OK"
else
  echo "✅ VAE already exists, skipping"
fi

echo ""
echo "=== All downloads complete ==="
