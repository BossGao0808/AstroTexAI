# Astro_TEX_AI · 本地 ComfyUI 部署

基于 **Apple Silicon (M4 Pro) / macOS / MPS** 的本地 Stable Diffusion 出图工作台。

## 目录结构

```
Astro_TEX_AI/
├── ComfyUI/                # ComfyUI 主程序（git 管理）
├── models_shared/          # 所有模型外置存放（与 ComfyUI 解耦）
│   ├── checkpoints/  vae/  loras/  controlnet/
│   ├── clip/  clip_vision/  unet/  upscale_models/
│   └── embeddings/  ipadapter/  style_models/
├── workflows/              # 工作流 JSON（按主题分类）
├── outputs/                # 生成图（按月归档 YYYY-MM/）
├── inputs/                 # 输入素材（图生图、ControlNet 参考图）
├── scripts/                # 启动 / 更新 / 下载脚本
└── docs/                   # 项目文档
```

模型/输出路径通过 `ComfyUI/extra_model_paths.yaml` 与启动参数 `--output-directory` `--input-directory` 重定向到上述外置目录。

## 环境

| 组件 | 版本 |
|---|---|
| macOS | 15.2 (Sequoia) |
| Chip | Apple M4 Pro |
| RAM | 64 GB（统一内存） |
| Python | 3.11 (conda env: `comfyui`) |
| PyTorch | 2.12 + MPS |

## 一键启动

```bash
cd /Users/gaotianyu/Documents/Astro_TEX_AI
./scripts/start_comfyui.sh
```

启动后访问 http://127.0.0.1:8188

如需局域网访问，编辑 `scripts/start_comfyui.sh` 把 `--listen 127.0.0.1` 改为 `--listen 0.0.0.0`。

## 更新

```bash
./scripts/update_comfyui.sh
```

会自动更新 ComfyUI 主程序、所有 `custom_nodes/*` 以及 Python 依赖。

## 模型下载

首批模型清单见 [`MODELS.md`](./MODELS.md)。建议通过 **ComfyUI-Manager**（已预装，启动后右上角点 "Manager"）的 *Model Manager* 下载，会自动放到外置 `models_shared/` 对应子目录。

也可手动放置：
- 主模型 (`*.safetensors`) → `models_shared/checkpoints/`
- LoRA → `models_shared/loras/`
- VAE → `models_shared/vae/`
- ControlNet → `models_shared/controlnet/`

## 性能调优 (MPS)

启动脚本已使用 `--force-fp16`。其它常用参数：

| 参数 | 作用 |
|---|---|
| `--lowvram` | 极低显存模式（M4 Pro 64GB 一般不需要） |
| `--cpu` | 强制 CPU 推理（调试用） |
| `--disable-smart-memory` | 出现 OOM 或内存波动时尝试 |
| `--use-pytorch-cross-attention` | 默认开启，MPS 上最稳 |

## 常见问题

1. **首次出图非常慢**：MPS 需要编译 Metal kernel，第二次起会快很多。
2. **生成全黑/NaN**：SDXL 需要使用 `sdxl_vae_fp16_fix.safetensors`（放 `models_shared/vae/`），并在工作流中显式加载。
3. **磁盘占用快速增长**：模型本身大；`outputs/` 已按月分目录，可定期归档/清理旧月。
