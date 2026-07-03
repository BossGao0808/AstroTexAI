# 模型清单

> 路径均位于 `models_shared/<类型>/` 下，由 `ComfyUI/extra_model_paths.yaml` 透传。

## ✅ 已下载

| 名称 | 类型 | 子目录 | 大小 | 用途 |
|---|---|---|---|---|
| sd_xl_base_1.0.safetensors | Checkpoint | `checkpoints/` | ~6.5 GB | SDXL 通用文生图主模型 |
| pixelwave_sdxl11.safetensors | Checkpoint | `checkpoints/` | ~6.5 GB | 像素风/2D 游戏资产专用（PixelWave SDXL 11，作者 mnemic） |
| sdxl_vae_fp16_fix.safetensors | VAE | `vae/` | ~335 MB | SDXL fp16 修正 VAE，避免偏色/全黑 |
| controlnet-depth-sdxl-1.0.safetensors | ControlNet | `controlnet/` | ~2.5 GB | xinsir 出品；用深度图约束生成形状（六棱柱、tile 等几何严格资产必备） |
| Realistic_Vision_V5.1.safetensors | Checkpoint | `checkpoints/` | ~4.3 GB | 写实人像标杆，人脸和皮肤质感极佳；推荐搭配 VAE mse-840000 |
| vae-ft-mse-840000-ema-pruned.safetensors | VAE | `vae/` | ~335 MB | Realistic Vision 配套推荐 VAE，SD1.5 写实模型通用 |

## 🎮 2D 游戏开发推荐

| 名称 | 类型 | 子目录 | 大小 | 链接 / 备注 |
|---|---|---|---|---|
| Animagine XL 4.0 | Checkpoint | `checkpoints/` | ~6.5 GB | 动漫立绘第一梯队，danbooru tag 完整 |
| Illustrious XL v2.0 | Checkpoint | `checkpoints/` | ~6.5 GB | 比 Animagine 更画风化，复杂构图更稳 |
| ControlNet OpenPose (SDXL) | ControlNet | `controlnet/` | ~2.5 GB | 角色多姿态生成，必备 |
| ControlNet Canny (SDXL) | ControlNet | `controlnet/` | ~2.5 GB | 从草图/Godot 占位图迭代 |
| IP-Adapter Plus (SDXL) | IPAdapter | `ipadapter/` | ~700 MB | 风格/角色一致性的基石 |
| 4x-UltraSharp.pth | Upscale | `upscale_models/` | ~67 MB | 通用高清放大 |

## 📌 通用补充

| 名称 | 类型 | 子目录 | 大小 | 链接 |
|---|---|---|---|---|
| sd_xl_refiner_1.0.safetensors | Checkpoint | `checkpoints/` | ~6 GB | https://huggingface.co/stabilityai/stable-diffusion-xl-refiner-1.0 |
| RealESRGAN_x4plus.pth | Upscale | `upscale_models/` | ~67 MB | https://github.com/xinntao/Real-ESRGAN/releases |

## 🔮 进阶

| 名称 | 类型 | 子目录 | 大小 | 备注 |
|---|---|---|---|---|
| flux1-dev-fp8.safetensors | UNet/Diffusion | `unet/` | ~12 GB | 当前最强开源；64GB 内存可流畅运行 |
| t5xxl_fp8_e4m3fn.safetensors | CLIP/T5 | `clip/` | ~5 GB | Flux 必需 |
| clip_l.safetensors | CLIP | `clip/` | ~250 MB | Flux 必需 |
| ae.safetensors | VAE | `vae/` | ~335 MB | Flux 配套 VAE |

## 下载方式

1. **首选**：在 ComfyUI Web UI → 右上角 **Manager → Model Manager** 中搜索安装。
2. **手动**：使用 `curl -L -C -` 或 `wget -c` 断点续传到对应子目录。
3. **加速**：国内可把 `huggingface.co` 替换为 `hf-mirror.com`。
