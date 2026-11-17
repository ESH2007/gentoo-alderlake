#!/usr/bin/env python3
"""Genera los fondos originales de cada tema a partir de sus colores (Pillow).
Uso: python3 themes/make-wallpapers.py   → themes/<tema>/wallpaper.png
"""
import math, pathlib
from PIL import Image, ImageDraw, ImageFilter

W, H = 1920, 1080
root = pathlib.Path(__file__).resolve().parent

def hexrgb(h):
    h = h.lstrip('#'); return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

def mix(a, b, t):
    return tuple(round(x + (y - x) * t) for x, y in zip(a, b))

for env in sorted(root.glob('*/theme.env')):
    t = dict(l.split('=', 1) for l in env.read_text().splitlines()
             if '=' in l and not l.startswith('#'))
    bg, alt, acc, acc2 = (hexrgb(t[k]) for k in ('BG', 'BG_ALT', 'ACCENT', 'ACCENT2'))
    img = Image.new('RGB', (W, H))
    d = ImageDraw.Draw(img)
    for y in range(H):  # degradado vertical
        d.line([(0, y), (W, y)], fill=mix(bg, alt, y / H))
    # curvas de nivel: ondas concéntricas suaves alrededor de un punto
    glow = Image.new('RGB', (W, H), (0, 0, 0))
    g = ImageDraw.Draw(glow)
    cx, cy = W * 0.72, H * 0.62
    for i in range(1, 26):
        r = i * 46
        pts = []
        for k in range(181):
            a = k / 180 * 2 * math.pi
            rr = r * (1 + 0.07 * math.sin(3 * a + i * 0.5) + 0.04 * math.sin(5 * a - i))
            pts.append((cx + rr * math.cos(a), cy + rr * 0.62 * math.sin(a)))
        col = mix(acc, acc2, i / 25)
        fade = max(0.0, 1 - i / 26)
        g.line(pts, fill=tuple(round(c * fade * 0.55) for c in col), width=2)
    glow = glow.filter(ImageFilter.GaussianBlur(0.8))
    if t.get('MODE') == 'light':
        # en temas claros las líneas oscurecen en vez de iluminar
        from PIL import ImageChops
        inv = ImageChops.invert(glow)
        img = ImageChops.multiply(img, Image.blend(Image.new('RGB', (W, H), (255,)*3), inv, 0.35))
    else:
        from PIL import ImageChops
        img = ImageChops.add(img, glow)
    out = env.parent / 'wallpaper.png'
    img.quantize(colors=128, dither=Image.Dither.NONE).save(out, optimize=True)
    print(out, out.stat().st_size // 1024, 'KiB')
