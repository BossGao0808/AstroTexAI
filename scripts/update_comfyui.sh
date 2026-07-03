#!/usr/bin/env bash
# 更新 ComfyUI 主程序与所有自定义节点，并刷新依赖
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMFY_DIR="${PROJECT_ROOT}/ComfyUI"

# shellcheck disable=SC1091
source /opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh
conda activate comfyui

echo "==> Updating ComfyUI core ..."
cd "${COMFY_DIR}"
git pull --ff-only || echo "[warn] git pull failed (可能本地有改动)"

echo "==> Updating custom nodes ..."
for d in "${COMFY_DIR}"/custom_nodes/*/; do
  if [ -d "${d}/.git" ]; then
    echo "  -- $(basename "${d}")"
    git -C "${d}" pull --ff-only || echo "    [warn] update skipped"
  fi
done

echo "==> Reinstalling requirements ..."
pip install -r "${COMFY_DIR}/requirements.txt" --upgrade

# 安装/更新各自定义节点的 requirements（如有）
for r in "${COMFY_DIR}"/custom_nodes/*/requirements.txt; do
  [ -f "${r}" ] && pip install -r "${r}" || true
done

echo "==> Done."
