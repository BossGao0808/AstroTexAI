#!/usr/bin/env bash
# ============================================================================
#  Astro_TEX_AI · Bootstrap
#  在新设备上一键复刻 ComfyUI 工作环境（不含模型下载）。
#  使用前置条件：
#    - macOS（Apple Silicon），已装 Xcode CLT、Homebrew、Miniconda
#    - 已把 docs/ scripts/ workflows/ .gitignore 拷到目标目录
#  使用：
#    cd <项目根>
#    chmod +x scripts/*.sh
#    ./scripts/bootstrap.sh
# ============================================================================
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_NAME="comfyui"
PY_VER="3.11"

cd "${PROJECT_ROOT}"

echo "============================================================"
echo "  Astro_TEX_AI bootstrap"
echo "  Project root : ${PROJECT_ROOT}"
echo "============================================================"

# --- 1) 校验前置 ---------------------------------------------------------------
command -v conda >/dev/null 2>&1 || { echo "[ERR] conda 未安装。请先 brew install --cask miniconda"; exit 1; }
command -v git   >/dev/null 2>&1 || { echo "[ERR] git 未安装"; exit 1; }
[ "$(uname -m)" = "arm64" ]      || { echo "[ERR] 仅支持 Apple Silicon (arm64)"; exit 1; }

CONDA_BASE="$(conda info --base)"
# shellcheck disable=SC1091
source "${CONDA_BASE}/etc/profile.d/conda.sh"

# --- 2) 创建项目目录骨架 ------------------------------------------------------
echo "==> [1/6] 创建目录骨架 ..."
mkdir -p models_shared/{checkpoints,vae,loras,controlnet,clip,clip_vision,unet,upscale_models,embeddings,ipadapter,style_models}
mkdir -p workflows/{basic,sdxl,flux,controlnet,upscale}
mkdir -p outputs inputs

# --- 3) 创建/复用 conda 环境 --------------------------------------------------
echo "==> [2/6] 准备 conda 环境 '${ENV_NAME}' (Python ${PY_VER}) ..."
if conda env list | awk '{print $1}' | grep -qx "${ENV_NAME}"; then
  echo "    环境已存在，跳过创建。"
else
  conda create -n "${ENV_NAME}" python="${PY_VER}" -y
fi
conda activate "${ENV_NAME}"
pip install --upgrade pip >/dev/null

# --- 4) 安装 Python 依赖 ------------------------------------------------------
echo "==> [3/6] 安装 Python 依赖 ..."
if [ -f "docs/requirements.lock.txt" ]; then
  echo "    使用锁定文件 docs/requirements.lock.txt"
  pip install -r docs/requirements.lock.txt
else
  echo "    [warn] 未找到 docs/requirements.lock.txt，使用最新版"
  pip install torch torchvision torchaudio
fi

# 验证 MPS
python - <<'PY'
import torch, sys
ok = torch.backends.mps.is_available() and torch.backends.mps.is_built()
print(f"  torch={torch.__version__}  mps={ok}")
sys.exit(0 if ok else 1)
PY

# --- 5) 克隆/还原 ComfyUI 主程序 ----------------------------------------------
echo "==> [4/6] 准备 ComfyUI 主程序 ..."
if [ -d "ComfyUI/.git" ]; then
  echo "    已存在 ComfyUI/，执行 git fetch ..."
  git -C ComfyUI fetch --all --tags --prune
else
  git clone https://github.com/comfyanonymous/ComfyUI.git ComfyUI
fi
if [ -f "docs/comfyui.commit" ]; then
  TARGET_COMMIT="$(cat docs/comfyui.commit | tr -d '[:space:]')"
  echo "    checkout 到锁定 commit: ${TARGET_COMMIT}"
  git -C ComfyUI checkout "${TARGET_COMMIT}" 2>/dev/null || \
    echo "    [warn] commit 不存在，保持当前 HEAD"
fi
pip install -r ComfyUI/requirements.txt

# --- 6) 安装 ComfyUI-Manager --------------------------------------------------
echo "==> [5/6] 准备 ComfyUI-Manager ..."
MANAGER_DIR="ComfyUI/custom_nodes/ComfyUI-Manager"
if [ -d "${MANAGER_DIR}/.git" ]; then
  git -C "${MANAGER_DIR}" fetch --all --tags --prune
else
  git clone https://github.com/ltdrdata/ComfyUI-Manager.git "${MANAGER_DIR}"
fi
if [ -f "docs/manager.commit" ]; then
  TARGET_COMMIT="$(cat docs/manager.commit | tr -d '[:space:]')"
  git -C "${MANAGER_DIR}" checkout "${TARGET_COMMIT}" 2>/dev/null || \
    echo "    [warn] Manager commit 不存在，保持当前 HEAD"
fi
[ -f "${MANAGER_DIR}/requirements.txt" ] && pip install -r "${MANAGER_DIR}/requirements.txt"

# --- 7) 写入 extra_model_paths.yaml ------------------------------------------
echo "==> [6/6] 写入 ComfyUI/extra_model_paths.yaml ..."
cat > ComfyUI/extra_model_paths.yaml <<YAML
## 自动由 bootstrap.sh 生成
## 把模型路径指向外置 models_shared/，输出/输入由启动脚本传参重定向。

astro_local:
  base_path: ${PROJECT_ROOT}/

  is_default: true

  checkpoints:      models_shared/checkpoints/
  vae:              models_shared/vae/
  loras:            models_shared/loras/
  controlnet:       models_shared/controlnet/
  clip:             models_shared/clip/
  clip_vision:      models_shared/clip_vision/
  unet:             models_shared/unet/
  diffusion_models: models_shared/unet/
  upscale_models:   models_shared/upscale_models/
  embeddings:       models_shared/embeddings/
  ipadapter:        models_shared/ipadapter/
  style_models:     models_shared/style_models/
YAML

chmod +x scripts/*.sh

echo
echo "============================================================"
echo "  ✅ Bootstrap 完成"
echo "============================================================"
echo "下一步："
echo "  1) 把模型放到 models_shared/checkpoints/ 等子目录（参考 docs/MODELS.md）"
echo "     最低限度：sd_xl_base_1.0.safetensors （SDXL Base，~6.5GB）"
echo "  2) 启动："
echo "     ./scripts/start_comfyui.sh"
echo "  3) 浏览器：http://127.0.0.1:8188"
echo
