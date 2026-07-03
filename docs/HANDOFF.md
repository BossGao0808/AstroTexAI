# 接管文档 / Handoff Guide

> 让另一个人或另一台设备能在最短时间内接手本项目（本地 ComfyUI 出图工作台）。
> 本文是**唯一的入口文档**，按场景跳到对应章节即可。
>
> **生成时间**：2026-05-27
> **当前所在主机**：Mac mini (M4 Pro, 64GB, macOS 15.2)
> **当前项目根**：`/Users/gaotianyu/Documents/Astro_TEX_AI`

---

## 0. TL;DR — 三种接管场景

| 场景 | 你应该做什么 | 跳转 |
|---|---|---|
| **A. 新 Mac，从零重建** | 装 conda → 跑 `bootstrap.sh` → 重新下模型 | [§3](#3-场景-a从零在新设备上复刻) |
| **B. 老 Mac → 新 Mac，整盘搬迁** | 直接 rsync 整个项目目录，激活环境即可 | [§4](#4-场景-b整盘迁移最快) |
| **C. 同一台机器，只是换个人接手** | 看 §1 §2，知道怎么启动/更新就行 | [§1](#1-项目结构速览) |

> ⚠️ **重要前提**：
> - 仅支持 **Apple Silicon Mac**（M1/M2/M3/M4 系列）。Intel Mac 与 Windows/Linux 不在本文档范围。
> - 至少 **16GB 内存**（推荐 32GB+，跑 Flux 需 64GB）。
> - 至少 **50GB** 可用磁盘（仅 SDXL 一套 ~10GB；加 Flux 全家桶 ~40GB）。

---

## 1. 项目结构速览

```
Astro_TEX_AI/
├── ComfyUI/                       # ComfyUI 主程序，git 管理（不要手动改文件）
│   ├── custom_nodes/
│   │   └── ComfyUI-Manager/       # 图形化节点/模型管理器
│   └── extra_model_paths.yaml     # ★ 把模型/路径重定向到外置 models_shared/
│
├── models_shared/                 # ★ 所有模型外置（即使删了 ComfyUI/ 也不丢）
│   ├── checkpoints/  vae/  loras/  controlnet/
│   ├── clip/  clip_vision/  unet/  upscale_models/
│   └── embeddings/  ipadapter/  style_models/
│
├── workflows/                     # 工作流 JSON（建议进 git）
│   └── basic/ sdxl/ flux/ controlnet/ upscale/
├── outputs/                       # 生成图，按月归档（YYYY-MM/）
├── inputs/                        # 输入素材
│
├── scripts/
│   ├── start_comfyui.sh           # 一键启动
│   ├── update_comfyui.sh          # 一键更新（主程序 + 全部节点 + 依赖）
│   └── bootstrap.sh               # ★ 新设备一键复刻（场景 A 用）
│
├── docs/
│   ├── HANDOFF.md                 # 你正在看的文档
│   ├── MIGRATION.md               # 整盘迁移详细步骤（场景 B）
│   ├── INSTALL.md                 # 历史安装记录（仅参考）
│   ├── MODELS.md                  # 模型清单
│   ├── requirements.lock.txt      # ★ pip 依赖锁定快照
│   ├── comfyui.commit             # ★ ComfyUI 当前 git commit hash
│   └── manager.commit             # ★ ComfyUI-Manager 当前 git commit hash
│
└── .gitignore
```

### 设计原则

1. **`ComfyUI/` 由 git 管理** — 升级 / 重装时整目录可被替换，损失为零。
2. **`models_shared/` 外置** — 模型文件巨大（单个 6–24GB），与代码解耦，可被多个前端复用。
3. **`outputs/` `inputs/` 外置** — 防止 ComfyUI 内部目录撑爆。
4. **`workflows/` `scripts/` `docs/` 进 git** — 这是项目的真正资产。

---

## 2. 日常使用（最小集）

### 2.1 启动

```bash
cd /Users/gaotianyu/Documents/Astro_TEX_AI
./scripts/start_comfyui.sh
```

启动后访问 http://127.0.0.1:8188

> 日志在前台输出。Ctrl+C 停止。
> 如需后台运行：`nohup ./scripts/start_comfyui.sh > /tmp/comfy.log 2>&1 &`

### 2.2 停止

```bash
# 找到进程
pgrep -fl "ComfyUI/main.py"
# 杀掉
pkill -f "ComfyUI/main.py"
```

### 2.3 更新

```bash
./scripts/update_comfyui.sh
```

### 2.4 局域网/远程访问

编辑 `scripts/start_comfyui.sh`，把 `--listen 127.0.0.1` 改为 `--listen 0.0.0.0`，然后：

```bash
ifconfig | grep "inet " | grep -v 127.0.0.1   # 看本机 IP
# 在另一台设备打开 http://<本机IP>:8188
```

---

## 3. 场景 A：从零在新设备上复刻

适用于：**新买的 Mac、清空过的 Mac、不同账号的 Mac**。

### 3.1 前置准备（手动）

```bash
# 1) 安装 Xcode Command Line Tools
xcode-select --install

# 2) 安装 Homebrew（已装可跳）
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 3) 安装 Miniconda（已装可跳）
brew install --cask miniconda
conda init zsh && exec zsh
```

> 验证：`conda --version && python3 --version`

### 3.2 把项目代码搬过来

只需要这些（**不需要拷贝模型和 ComfyUI/，bootstrap 会重新拉**）：

```
docs/
scripts/
workflows/
.gitignore
```

如果项目托管在 git 仓库：

```bash
mkdir -p ~/Documents && cd ~/Documents
git clone <你的仓库地址> Astro_TEX_AI
```

如果没仓库，从老机器 scp/rsync：

```bash
# 在新机器执行
rsync -av --progress \
  老机用户名@老机IP:/Users/gaotianyu/Documents/Astro_TEX_AI/{docs,scripts,workflows,.gitignore} \
  ~/Documents/Astro_TEX_AI/
```

### 3.3 跑 bootstrap 一键复刻

```bash
cd ~/Documents/Astro_TEX_AI
chmod +x scripts/*.sh
./scripts/bootstrap.sh
```

`bootstrap.sh` 会自动完成：
1. 创建/重建项目目录骨架
2. 创建 `comfyui` conda 环境（Python 3.11）
3. 安装 PyTorch 2.12（MPS）+ ComfyUI 全部依赖（按 `docs/requirements.lock.txt` 锁定版本）
4. 克隆 ComfyUI 到 `docs/comfyui.commit` 记录的同一个 commit
5. 克隆 ComfyUI-Manager 到 `docs/manager.commit` 记录的同一个 commit
6. 写入 `extra_model_paths.yaml`

### 3.4 下载模型

模型 6.5GB+ 起，不在 bootstrap 里跑，避免阻塞。看 [`MODELS.md`](./MODELS.md)：

```bash
# 最低限度：SDXL Base 1.0
cd models_shared/checkpoints
curl -L -C - -o sd_xl_base_1.0.safetensors \
  "https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors?download=true"
```

国内速度慢可把 `huggingface.co` 替换为 `hf-mirror.com`。

或：启动 ComfyUI 后，在 Web UI 右上角 **Manager → Model Manager** 里点选下载，会自动落到 `models_shared/` 对应子目录。

### 3.5 启动验证

```bash
./scripts/start_comfyui.sh
```

浏览器开 http://127.0.0.1:8188，`Load Checkpoint` 节点能看到 `sd_xl_base_1.0.safetensors` 即成功。

---

## 4. 场景 B：整盘迁移（最快）

适用于：**老 Mac 直接搬到新 Mac**（同账号或不同账号都行）。

详细步骤见 [`MIGRATION.md`](./MIGRATION.md)。最简版：

```bash
# 在老机执行：先停 ComfyUI
pkill -f "ComfyUI/main.py"

# 在新机执行：拉走整个项目（含模型、ComfyUI 仓库、所有产物）
rsync -av --progress --partial \
  老机用户名@老机IP:/Users/gaotianyu/Documents/Astro_TEX_AI/ \
  ~/Documents/Astro_TEX_AI/

# 在新机：装 Miniconda（同 §3.1），然后只重建 conda 环境
cd ~/Documents/Astro_TEX_AI
conda create -n comfyui python=3.11 -y
conda activate comfyui
pip install -r docs/requirements.lock.txt

# 启动
./scripts/start_comfyui.sh
```

> ⚠️ **如果新机用户名 ≠ `gaotianyu`**：项目根路径会变，需要调整两个文件里的绝对路径，详见 `MIGRATION.md` §3。

---

## 5. 关键版本信息（接管时核对）

| 组件 | 版本 / Commit |
|---|---|
| macOS | 15.2 (Sequoia) |
| Chip | Apple M4 Pro |
| Python | **3.11.15** (conda env: `comfyui`) |
| PyTorch | **2.12.0** + MPS |
| torchvision | 0.27.0 |
| transformers | 5.8.1 |
| safetensors | 0.7.0 |
| comfyui-frontend-package | 1.43.18 |
| ComfyUI | commit `7c4d95d1bc2ef178937d203aa81070db0b172a92` (2026-05-16) |
| ComfyUI-Manager | commit `a2c41a2a21ffff3c8f1dfc6da2010967ef87538e` |

> 这些信息也存在 `docs/comfyui.commit`、`docs/manager.commit`、`docs/requirements.lock.txt` 中，由 `bootstrap.sh` 自动读取。

### 路径相关常量（搬迁时关注）

| 路径 | 出现位置 |
|---|---|
| `/opt/homebrew/Caskroom/miniconda/base` | conda 安装根，`scripts/start_comfyui.sh`、`scripts/update_comfyui.sh`、`scripts/bootstrap.sh` |
| `/Users/gaotianyu/Documents/Astro_TEX_AI` | 项目根，`ComfyUI/extra_model_paths.yaml` 里写死 |

`scripts/*.sh` 内部都用 `$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)` 自动算项目根，**搬到任何路径都不用改**。
但 `extra_model_paths.yaml` 里的 `base_path` 是绝对路径，**换路径必须改**。

---

## 6. 当前项目状态盘点（接管时心中有数）

| 目录 | 占用 | 内容 |
|---|---|---|
| `ComfyUI/` | ~80 MB | 主程序源码（不含模型、不含 .git pack） |
| `models_shared/checkpoints/` | 6.5 GB | 仅 `sd_xl_base_1.0.safetensors` |
| `models_shared/`（其它） | 0 | 暂未下载 VAE/LoRA/ControlNet |
| `workflows/` | 0 | 子目录已建，暂无 JSON |
| `outputs/` | 0 | 暂无生成 |
| `inputs/` | 0 | 暂无素材 |

### 已完成 ✅
- 项目骨架、conda 环境、PyTorch MPS、ComfyUI、Manager 全部就绪
- SDXL Base 1.0 已下载并验证
- HTTP 服务 200 OK（曾在 PID 39129 验证过）

### 待办（建议接手者优先做）
1. 下载 **`sdxl_vae_fp16_fix.safetensors`** 到 `models_shared/vae/`，避免 SDXL 偶发偏色
2. 在 `workflows/sdxl/` 沉淀一个标准 SDXL 工作流 JSON（出图后右键 *Save (API Format)*）
3. 把 `workflows/`、`scripts/`、`docs/` 提交到 git 仓库（远程备份）

详见 [`MODELS.md`](./MODELS.md)。

---

## 7. 常见问题排查

| 现象 | 原因 / 处理 |
|---|---|
| 浏览器显示 "ComfyApp graph accessed before initialization" | 首次访问页面没等服务就绪。等 5 秒强制刷新即可。 |
| 启动后端口 8188 占用 | `lsof -i :8188` 找到 PID 杀掉，或改 `start_comfyui.sh` 里的 `--port` |
| 出图全黑 / NaN | SDXL 需要 fp16-fix VAE，下载并在工作流中显式加载 |
| Manager 一直 "installing dependencies" | 首次启动正常行为，等 30–90 秒会自动好 |
| `mps available: False` | PyTorch 装错了或 macOS < 12.3。重装：`pip install --force-reinstall torch torchvision torchaudio` |
| 模型在下拉框里看不到 | 检查 `extra_model_paths.yaml` 中 `base_path` 是否还指向正确路径；模型扩展名是否为 `.safetensors`/`.ckpt` |
| `conda: command not found` | shell rc 没初始化。重跑 `conda init zsh && exec zsh` |

---

## 8. 联系交接清单

接手前请向上一任确认：

- [ ] 是否有远程 git 仓库？地址是？
- [ ] HuggingFace token 是否需要（下载受限模型时用）？
- [ ] 哪些 LoRA / 自定义节点是当前工作流必需的？（场景 A 复刻时要补装）
- [ ] `outputs/` 中哪些是要保留的产物？（迁移时筛选）
- [ ] 是否配置了远程访问？端口是否在防火墙开放？

---

**文档结束。** 还有问题先看 [`MIGRATION.md`](./MIGRATION.md) → [`INSTALL.md`](./INSTALL.md) → [`MODELS.md`](./MODELS.md)。
