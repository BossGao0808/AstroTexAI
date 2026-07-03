# 整盘迁移指南（Migration Guide）

> 适用场景：把项目从一台 Apple Silicon Mac 完整搬到另一台 Apple Silicon Mac。
> 比"从零复刻 + 重下模型"快得多（节省几十 GB 下载流量）。

---

## 1. 迁移前检查清单（在**老机**执行）

```bash
# 1. 停止正在运行的 ComfyUI
pkill -f "ComfyUI/main.py" ; sleep 2 ; pgrep -fl "ComfyUI/main.py" || echo "已停止"

# 2. 确认项目大小（决定迁移方式）
du -sh /Users/gaotianyu/Documents/Astro_TEX_AI/

# 3. 刷新依赖锁文件（确保和当前环境一致）
source /opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh
conda activate comfyui
pip freeze > /Users/gaotianyu/Documents/Astro_TEX_AI/docs/requirements.lock.txt

# 4. 刷新 commit 信息
cd /Users/gaotianyu/Documents/Astro_TEX_AI/ComfyUI
git rev-parse HEAD > ../docs/comfyui.commit
cd custom_nodes/ComfyUI-Manager
git rev-parse HEAD > /Users/gaotianyu/Documents/Astro_TEX_AI/docs/manager.commit

# 5. 清理不需要带走的体积
find /Users/gaotianyu/Documents/Astro_TEX_AI -name __pycache__ -type d -exec rm -rf {} + 2>/dev/null
find /Users/gaotianyu/Documents/Astro_TEX_AI -name ".DS_Store" -delete 2>/dev/null
```

---

## 2. 迁移方式三选一

### 方式 A：rsync 直传（**推荐**，老新机同时在线）

在**新机**执行（可断点续传）：

```bash
mkdir -p ~/Documents
rsync -av --progress --partial --human-readable \
  --exclude='__pycache__' \
  --exclude='.DS_Store' \
  --exclude='outputs/.tmp_*' \
  老机用户名@老机IP:/Users/gaotianyu/Documents/Astro_TEX_AI/ \
  ~/Documents/Astro_TEX_AI/
```

> 千兆有线 6.5GB ≈ 1 分钟，Wi-Fi 5 ≈ 5–10 分钟。

### 方式 B：外接硬盘 / U 盘

```bash
# 老机：拷到外置盘
rsync -av --progress /Users/gaotianyu/Documents/Astro_TEX_AI/ /Volumes/外置盘名/Astro_TEX_AI/

# 新机：从外置盘拷回来
rsync -av --progress /Volumes/外置盘名/Astro_TEX_AI/ ~/Documents/Astro_TEX_AI/
```

### 方式 C：Apple "迁移助理"

整机迁移时项目自动跟着走，无需特别操作。但 **conda 环境不会迁过来**，仍然需要执行 §4 的环境重建。

---

## 3. 路径修正（**用户名变化时必做**）

如果新机用户名 **不是** `gaotianyu`，下面这个文件里写死的绝对路径必须改：

### 3.1 修 `ComfyUI/extra_model_paths.yaml`

```bash
# 假设新机项目根是 /Users/新用户名/Documents/Astro_TEX_AI
NEW_ROOT="$HOME/Documents/Astro_TEX_AI"
sed -i '' "s|/Users/gaotianyu/Documents/Astro_TEX_AI|${NEW_ROOT}|g" \
  ${NEW_ROOT}/ComfyUI/extra_model_paths.yaml

# 验证
grep base_path ${NEW_ROOT}/ComfyUI/extra_model_paths.yaml
```

### 3.2 检查 `scripts/*.sh`

脚本里项目根是动态计算的（`$(cd "$(dirname ...)/.." && pwd)`），**不需要改**。
但 conda 路径写死成 `/opt/homebrew/Caskroom/miniconda/base`，如果新机 conda 装在别处需要改：

```bash
NEW_CONDA=$(conda info --base)
sed -i '' "s|/opt/homebrew/Caskroom/miniconda/base|${NEW_CONDA}|g" \
  ${NEW_ROOT}/scripts/*.sh
```

### 3.3 检查 conda 环境路径（一般不用动）

`pip freeze` 里如果有 `@ file:///...` 形式的本地包路径会跟着用户名变。`bootstrap.sh` 重装环境时会自动从 PyPI 重新解析，所以问题不大。

---

## 4. 在新机重建 conda 环境

模型、ComfyUI 源码、自定义节点都已经随项目目录搬过来了，但 **Python 包不会跟过来**（在 `~/miniconda` 里）。所以新机上必须重建 conda 环境：

```bash
# 1) 安装 Miniconda（如未安装）
brew install --cask miniconda
conda init zsh && exec zsh

# 2) 重建环境
cd ~/Documents/Astro_TEX_AI
conda create -n comfyui python=3.11 -y
conda activate comfyui

# 3) 用锁定文件还原依赖（推荐）
pip install -r docs/requirements.lock.txt

# 4) 验证 MPS
python -c "import torch; print('mps:', torch.backends.mps.is_available())"
# 期望输出：mps: True
```

> 如果 `pip install -r docs/requirements.lock.txt` 报某个包冲突或找不到，回退用：
> ```bash
> pip install torch torchvision torchaudio
> pip install -r ComfyUI/requirements.txt
> ```

---

## 5. 启动验证

```bash
chmod +x ~/Documents/Astro_TEX_AI/scripts/*.sh
~/Documents/Astro_TEX_AI/scripts/start_comfyui.sh
```

启动日志应包含：

```
Adding extra search path checkpoints /Users/<新用户名>/Documents/Astro_TEX_AI/models_shared/checkpoints
...
Setting output directory to: /Users/<新用户名>/Documents/Astro_TEX_AI/outputs/2026-XX
...
To see the GUI go to: http://127.0.0.1:8188
```

浏览器打开后，`Load Checkpoint` 节点下拉框中应能看到 `sd_xl_base_1.0.safetensors`。

---

## 6. 网络快速检查（远程访问场景）

```bash
# 新机本地访问
curl -I http://127.0.0.1:8188/

# 局域网访问（需先把 start_comfyui.sh 中 --listen 改 0.0.0.0）
ifconfig | grep "inet " | grep -v 127.0.0.1     # 看本机 IP
# 在另一台设备打开 http://<新机IP>:8188
```

macOS 防火墙如果开了，第一次访问会弹窗"是否允许 python 接受网络连接"，选**允许**。

---

## 7. 迁移后清理（可选）

确认新机一切正常后，老机可以：

```bash
# 备份后删除
mv /Users/gaotianyu/Documents/Astro_TEX_AI ~/.Trash/Astro_TEX_AI_backup_$(date +%Y%m%d)
conda env remove -n comfyui
```

> 建议**至少保留一周**老机数据，万一新机出问题可回滚。

---

## 8. 故障速查

| 现象 | 处理 |
|---|---|
| `extra_model_paths.yaml` 中路径仍是老用户名 | 回到 §3.1 重做 sed |
| `Load Checkpoint` 看不到模型 | 确认 `models_shared/checkpoints/*.safetensors` 在新机存在；查启动日志 `Adding extra search path checkpoints ...` 是否指向正确路径 |
| `pip install -r requirements.lock.txt` 报版本冲突 | 删环境重来：`conda env remove -n comfyui && conda create -n comfyui python=3.11 -y` |
| 启动卡在 "ComfyUI-Manager: installing dependencies" | 等 30–90 秒，首次正常 |
| Apple 迁移助理迁过来后启动报 codesign / quarantine | `xattr -dr com.apple.quarantine ~/Documents/Astro_TEX_AI` |
| 8188 端口被占 | `lsof -i :8188` 杀掉，或改 `start_comfyui.sh` 中 `--port` |
