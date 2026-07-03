#!/usr/bin/env bash
# 批量出 10 张"泥土材质六棱柱"——通过同一 prompt + 不同 seed 横向对比
set -euo pipefail

COMFY_URL="http://127.0.0.1:8188"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

POSITIVE="single hexagonal prism made of dirt and earth, top-down isometric game tile, soil texture with small pebbles and grass tufts on top, vibrant 2D game asset, clean silhouette, transparent background, JRPG roguelike art style, detailed pixel-craft, soft natural lighting"
NEGATIVE="blurry, photorealistic, 3d render, low quality, watermark, signature, deformed, multiple objects, scattered, cluttered, jpeg artifacts, oversaturated"

CKPT="pixelwave_sdxl11.safetensors"
VAE="sdxl_vae_fp16_fix.safetensors"

# 10 个不同 seed
SEEDS=(101 202 303 404 505 606 707 808 909 1010)

echo "=========================================="
echo "  泥土六棱柱 × 10  →  ComfyUI"
echo "=========================================="

for i in "${!SEEDS[@]}"; do
  seed="${SEEDS[$i]}"
  idx=$(printf "%02d" $((i+1)))
  name="hex_dirt_${idx}_seed${seed}"

  PAYLOAD=$(jq -n \
    --arg ckpt "${CKPT}" --arg vae "${VAE}" \
    --arg pos "${POSITIVE}" --arg neg "${NEGATIVE}" \
    --arg name "${name}" --argjson seed "${seed}" \
    '{
      prompt: {
        "3":  { class_type: "CheckpointLoaderSimple", inputs: { ckpt_name: $ckpt } },
        "4":  { class_type: "CLIPTextEncode",          inputs: { text: $pos, clip: ["3", 1] } },
        "5":  { class_type: "CLIPTextEncode",          inputs: { text: $neg, clip: ["3", 1] } },
        "6":  { class_type: "EmptyLatentImage",        inputs: { width: 1024, height: 1024, batch_size: 1 } },
        "7":  { class_type: "KSampler",                inputs: { model: ["3", 0], positive: ["4", 0], negative: ["5", 0], latent_image: ["6", 0], seed: $seed, steps: 20, cfg: 5.5, sampler_name: "dpmpp_sde", scheduler: "karras", denoise: 1.0 } },
        "10": { class_type: "VAELoader",               inputs: { vae_name: $vae } },
        "8":  { class_type: "VAEDecode",               inputs: { samples: ["7", 0], vae: ["10", 0] } },
        "9":  { class_type: "SaveImage",               inputs: { filename_prefix: $name, images: ["8", 0] } }
      }
    }')

  RESP=$(curl -s -X POST -H "Content-Type: application/json" -d "${PAYLOAD}" "${COMFY_URL}/prompt")
  PID=$(echo "${RESP}" | jq -r '.prompt_id // "ERR"')
  echo "  [$((i+1))/10] seed=${seed}  prompt_id=${PID}"
done

echo ""
echo "✅ 全部 10 个任务已提交到队列"
