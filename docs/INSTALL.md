# 安装记录（已完成）

> 自动化部署执行时间：2026-05-11

## 1. 系统环境

- macOS 15.2 / Apple M4 Pro / 64GB / arm64
- conda: `/opt/homebrew/Caskroom/miniconda/base`

## 2. 创建 conda 环境

```bash
conda create -n comfyui python=3.11 -y
conda activate comfyui
```

## 3. 安装 PyTorch (MPS)

```bash
pip install --upgrade pip
pip install torch torchvision torchaudio
# 安装得到 torch 2.12.0；mps available = True
```

## 4. 克隆 ComfyUI 并安装依赖

```bash
cd /Users/gaotianyu/Documents/Astro_TEX_AI
git clone --depth 1 https://github.com/comfyanonymous/ComfyUI.git
cd ComfyUI
pip install -r requirements.txt
```

## 5. 配置外部模型路径

编辑 `ComfyUI/extra_model_paths.yaml`，将所有模型类目录指向项目级 `models_shared/`。

## 6. 安装 ComfyUI-Manager

```bash
cd ComfyUI/custom_nodes
git clone --depth 1 https://github.com/ltdrdata/ComfyUI-Manager.git
```

启动后会在 Web 界面右上角出现 **Manager** 按钮，可视化安装其它自定义节点 / 模型。

## 7. 下载首个主模型

SDXL Base 1.0 (~6.5GB) → `models_shared/checkpoints/sd_xl_base_1.0.safetensors`

```bash
cd models_shared/checkpoints
curl -L -C - -o sd_xl_base_1.0.safetensors \
  "https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors?download=true"
```

下载支持断点续传（`-C -`）。如果速度慢可改用镜像（替换 `huggingface.co` 为 `hf-mirror.com`）。

## 8. 一键启动

```bash
chmod +x scripts/*.sh
./scripts/start_comfyui.sh
```

访问 http://127.0.0.1:8188
