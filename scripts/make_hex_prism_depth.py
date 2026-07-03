"""
合成 isometric 六棱柱深度图（灰度，越亮越近）
- top-down isometric 视角，平顶六棱柱
- 顶面整体最亮（255），侧面三个面按朝向给三个不同灰度（明暗渐变）
- 1024×1024，黑底（背景=远处=0）
- 支持水平拉伸（stretch_x），用于做长条形 tile

ControlNet Depth 习惯：白色 = 镜头近，黑色 = 远。
游戏 tile 规范：顶面始终亮，侧面较暗。

用法:
    python make_hex_prism_depth.py [输出路径] [stretch_x]
默认输出: inputs/depth_hex_prism.png
默认 stretch_x: 1.0（正六边形）；4.0 = 长宽 4:1
"""
from PIL import Image, ImageDraw
import math
import sys
from pathlib import Path

W = H = 1024

# 六棱柱几何
RADIUS_TOP = 200               # 顶面外接圆半径（基准；拉伸后实际宽度会变）
HEIGHT = 220                   # 柱体厚度（向上的延伸）
ISO_SQUASH = 0.55              # isometric 顶面纵向压扁系数（越小越"俯视压扁"）

# 灰度（深度值）
DEPTH_TOP        = 255         # 顶面：最近
DEPTH_BG         = 0           # 背景

# 侧面三个可见面（按朝向）：左前、正前、右前
DEPTH_SIDE_FRONT = 170
DEPTH_SIDE_LEFT  = 130
DEPTH_SIDE_RIGHT = 145


def hex_top_vertices(cx, cy, r, squash=1.0, stretch_x=1.0):
    """flat-top 六边形 6 个顶点（按角度逆时针），可垂直压扁模拟 isometric，可水平拉伸模拟长 tile."""
    pts = []
    for i in range(6):
        a = math.radians(60 * i)        # flat-top: 0, 60, 120... 顶点在水平方向
        x = cx + r * math.cos(a) * stretch_x
        y = cy + r * math.sin(a) * squash
        pts.append((x, y))
    return pts


def main(out_path: str, stretch_x: float = 1.0):
    img = Image.new("L", (W, H), DEPTH_BG)
    draw = ImageDraw.Draw(img)

    # 中心位置（拉长版要居中，给上下留空）
    cx = W // 2
    cy = H // 2 + 60

    # 顶面 6 个顶点（按 isometric 压扁 + 水平拉伸后）
    top = hex_top_vertices(cx, cy, RADIUS_TOP, ISO_SQUASH, stretch_x)
    # 底面 = 顶面整体下移 HEIGHT 像素
    bot = [(x, y + HEIGHT) for (x, y) in top]

    # ---- 1) 先画三个可见侧面（在底面以下/前方）----
    # flat-top 六边形顶点编号（逆时针，从右开始）：
    #   0: 右      (a=0°)
    #   1: 右下    (a=60°)
    #   2: 左下    (a=120°)
    #   3: 左      (a=180°)
    #   4: 左上    (a=240°)
    #   5: 右上    (a=300°)
    # 三个朝下/朝前的面：(0,1)-右下, (1,2)-正下, (2,3)-左下

    # 右前侧面（顶 0→1，底 1'→0'）
    quad_right = [top[0], top[1], bot[1], bot[0]]
    draw.polygon(quad_right, fill=DEPTH_SIDE_RIGHT)

    # 正前侧面（中央，最大）
    quad_front = [top[1], top[2], bot[2], bot[1]]
    draw.polygon(quad_front, fill=DEPTH_SIDE_FRONT)

    # 左前侧面
    quad_left = [top[2], top[3], bot[3], bot[2]]
    draw.polygon(quad_left, fill=DEPTH_SIDE_LEFT)

    # ---- 2) 顶面（覆盖在最上层，盖住 quads 的上沿）----
    draw.polygon(top, fill=DEPTH_TOP)

    out = Path(out_path)
    out.parent.mkdir(parents=True, exist_ok=True)
    # 保存为 RGB 让 ControlNet 节点直接接受
    img.convert("RGB").save(out, optimize=True)
    print(f"✅ 深度图已生成: {out}")
    print(f"   尺寸: {W}x{H}, stretch_x={stretch_x}, 顶面=255, 侧面=170/130/145, 背景=0")


if __name__ == "__main__":
    out_path = sys.argv[1] if len(sys.argv) > 1 else "inputs/depth_hex_prism.png"
    stretch_x = float(sys.argv[2]) if len(sys.argv) > 2 else 1.0
    main(out_path, stretch_x)
