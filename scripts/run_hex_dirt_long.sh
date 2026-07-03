#!/usr/bin/env bash
# 用拉长版深度图 (4:1) 出 3 张对比图
set -euo pipefail

COMFY_URL="http://127.0.0.1:8188"
DEPTH_IMAGE="depth_hex_prism_long4x1.png"

POSITIVE="long horizontal hexagonal prism platform made of dirt and earth, top-down isometric game tile, soil texture with small pebbles and grass tufts on top, vibrant 2D game asset, clean silhouette, JRPG roguelike art style, soft natural lighting"
NEGATIVE="blurry, photorealistic, 3d render, low quality, watermark, signature, deformed, multiple objects, scattered, cluttered, jpeg artifacts"

CKPT="pixelwave_sdxl11.safetensors"
VAE="sdxl_vae_fp16_fix.safetensors"
CN="controlnet-depth-sdxl-1.0.safetensors"

# 3 个 seed 横向对比
SEEDS=(505 707 909)

echo "=========================================="
echo "  泥土六棱柱 4:1 长条 × 3"
echo "  depth: ${DEPTH_IMAGE}"
echo "=========================================="

for i in "${!SEEDS[@]}"; do
  seed="${SEEDS[$i]}"
  idx=$(printf "%02d" $((i+1)))
  name="hex_dirt_long_${idx}_seed${seed}"

  PAYLOAD=$(jq -n \
    --arg ckpt "${CKPT}" --arg vae "${VAE}" --arg cn "${CN}" \
    --arg pos "${POSITIVE}" --arg neg "${NEGATIVE}" \
    --arg name "${name}" --arg img "${DEPTH_IMAGE}" \
    --argjson seed "${seed}" \
    '{
      prompt: {
        "3":  { class_type: "CheckpointLoaderSimple", inputs: { ckpt_name: $ckpt } },
        "4":  { class_type: "CLIPTextEncode",          inputs: { text: $pos, clip: ["3", 1] } },
        "5":  { class_type: "CLIPTextEncode",          inputs: { text: $neg, clip: ["3", 1] } },
        "11": { class_type: "LoadImage",               inputs: { image: $img, upload: "image" } },
        "12": { class_type: "ControlNetLoader",        inputs: { control_net_name: $cn } },
        "13": { class_type: "ControlNetApplyAdvanced", inputs: { positive: ["4", 0], negative: ["5", 0], control_net: ["12", 0], image: ["11", 0], strength: 0.9, start_percent: 0.0, end_percent: 1.0 } },
        "6":  { class_type: "EmptyLatentImage",        inputs: { width: 1024, height: 1024, batch_size: 1 } },
        "7":  { class_type: "KSampler",                inputs: { model: ["3", 0], positive: ["13", 0], negative: ["13", 1], latent_image: ["6", 0], seed: $seed, steps: 28, cfg: 5.5, sampler_name: "dpmpp_sde", scheduler: "karras", denoise: 1.0 } },
        "10": { class_type: "VAELoader",               inputs: { vae_name: $vae } },
        "8":  { class_type: "VAEDecode",               inputs: { samples: ["7", 0], vae: ["10", 0] } },
        "9":  { class_type: "SaveImage",               inputs: { filename_prefix: $name, images: ["8", 0] } }
      }
    }')

  RESP=$(curl -s -X POST -H "Content-Type: application/json" -d "${PAYLOAD}" "${COMFY_URL}/prompt")
  PID=$(echo "${RESP}" | jq -r '.prompt_id // "ERR"')
  ERRORS=$(echo "${RESP}" | jq -c '.node_errors')
  echo "  [$((i+1))/3] seed=${seed}  id=${PID}  errors=${ERRORS}"
done

echo ""
echo "✅ 已提交 3 张到队列"
