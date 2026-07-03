#!/usr/bin/env bash
# 批量跑 PixelWave 测试矩阵（4 张不同主题图）
# 前提：ComfyUI 已启动在 http://127.0.0.1:8188
# 用法：./scripts/run_pixelwave_matrix.sh

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MATRIX_FILE="${PROJECT_ROOT}/workflows/sdxl/pixelwave_matrix.json"
COMFY_URL="http://127.0.0.1:8188"

# 检查 ComfyUI 是否在跑
if ! curl -s -f -o /dev/null "${COMFY_URL}/system_stats"; then
  echo "❌ ComfyUI 未启动。先跑：./scripts/start_comfyui.sh"
  exit 1
fi

# 需要 jq 解析矩阵
if ! command -v jq &> /dev/null; then
  echo "❌ 需要 jq。安装：brew install jq"
  exit 1
fi

echo "=========================================="
echo "  PixelWave Test Matrix → ComfyUI"
echo "=========================================="

# 共享参数
NEGATIVE=$(jq -r '.shared.negative' "${MATRIX_FILE}")
CKPT=$(jq -r '.shared.checkpoint' "${MATRIX_FILE}")
VAE=$(jq -r '.shared.vae' "${MATRIX_FILE}")
SAMPLER=$(jq -r '.shared.sampler' "${MATRIX_FILE}")
SCHEDULER=$(jq -r '.shared.scheduler' "${MATRIX_FILE}")
STEPS=$(jq -r '.shared.steps' "${MATRIX_FILE}")
CFG=$(jq -r '.shared.cfg' "${MATRIX_FILE}")
W=$(jq -r '.shared.width' "${MATRIX_FILE}")
H=$(jq -r '.shared.height' "${MATRIX_FILE}")

# 遍历矩阵
COUNT=$(jq '.matrix | length' "${MATRIX_FILE}")
for ((i=0; i<COUNT; i++)); do
  name=$(jq -r ".matrix[${i}].name" "${MATRIX_FILE}")
  positive=$(jq -r ".matrix[${i}].positive" "${MATRIX_FILE}")
  seed=$(jq -r ".matrix[${i}].seed" "${MATRIX_FILE}")

  echo ""
  echo "[$((i+1))/${COUNT}] Submitting: ${name} (seed=${seed})"

  PAYLOAD=$(jq -n \
    --arg ckpt "${CKPT}" \
    --arg vae "${VAE}" \
    --arg pos "${positive}" \
    --arg neg "${NEGATIVE}" \
    --arg sampler "${SAMPLER}" \
    --arg scheduler "${SCHEDULER}" \
    --arg name "${name}" \
    --argjson seed "${seed}" \
    --argjson steps "${STEPS}" \
    --argjson cfg "${CFG}" \
    --argjson w "${W}" \
    --argjson h "${H}" \
    '{
      prompt: {
        "3": { class_type: "CheckpointLoaderSimple", inputs: { ckpt_name: $ckpt } },
        "4": { class_type: "CLIPTextEncode", inputs: { text: $pos, clip: ["3", 1] } },
        "5": { class_type: "CLIPTextEncode", inputs: { text: $neg, clip: ["3", 1] } },
        "6": { class_type: "EmptyLatentImage", inputs: { width: $w, height: $h, batch_size: 1 } },
        "7": { class_type: "KSampler", inputs: { model: ["3", 0], positive: ["4", 0], negative: ["5", 0], latent_image: ["6", 0], seed: $seed, steps: $steps, cfg: $cfg, sampler_name: $sampler, scheduler: $scheduler, denoise: 1.0 } },
        "10": { class_type: "VAELoader", inputs: { vae_name: $vae } },
        "8": { class_type: "VAEDecode", inputs: { samples: ["7", 0], vae: ["10", 0] } },
        "9": { class_type: "SaveImage", inputs: { filename_prefix: ("pixelwave_" + $name), images: ["8", 0] } }
      }
    }')

  RESP=$(curl -s -X POST -H "Content-Type: application/json" \
    -d "${PAYLOAD}" \
    "${COMFY_URL}/prompt")
  PID=$(echo "${RESP}" | jq -r '.prompt_id // "ERROR"')
  echo "  prompt_id: ${PID}"
done

echo ""
echo "✅ 全部 ${COUNT} 个任务已提交。"
echo "   查看进度：浏览器开 ${COMFY_URL}"
echo "   产物在：outputs/$(date +%Y-%m)/pixelwave_*"
