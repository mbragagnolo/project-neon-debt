"""Measure a reference screenshot: how dark it is and what colour its light is.

    python tools/art/ref_stats.py docs/art/refs/*.jpg

Letterbox bars are cropped (13% top and bottom). Luma bands are on 0..255:
dark < 30, mid 30..109, bright >= 110. Of the lit pixels (luma >= 60 and
saturation >= 0.25), warm is hue < 60 or > 330 degrees, cold is 160..260,
the rest is neutral or another hue. Use the numbers to set a room's
ambient level and its warm/cold budget (docs/art/environment.md).
"""
import colorsys
import sys

from PIL import Image


def stats(path: str) -> str:
    im = Image.open(path).convert("RGB")
    w, h = im.size
    im = im.crop((0, int(h * 0.13), w, int(h * 0.87))).resize((480, 200))
    px = list(im.get_flattened_data()) if hasattr(im, "get_flattened_data") else list(im.getdata())
    n = len(px)
    luma = [0.2126 * r + 0.7152 * g + 0.0722 * b for r, g, b in px]
    dark = sum(1 for l in luma if l < 30) / n
    mid = sum(1 for l in luma if 30 <= l < 110) / n
    bright = sum(1 for l in luma if l >= 110) / n
    warm = cold = other = 0
    for (r, g, b), l in zip(px, luma):
        if l < 60:
            continue
        hue, sat, _ = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
        deg = hue * 360
        if sat < 0.25:
            other += 1
        elif deg < 60 or deg > 330:
            warm += 1
        elif 160 <= deg <= 260:
            cold += 1
        else:
            other += 1
    lit = max(1, warm + cold + other)
    return (f"{path.split('/')[-1]:30s} dark {dark:4.0%}  mid {mid:4.0%}  bright {bright:4.0%}"
            f" | lit: warm {warm / lit:3.0%}  cold {cold / lit:3.0%}  other {other / lit:3.0%}")


if __name__ == "__main__":
    for p in sys.argv[1:]:
        print(stats(p.replace("\\", "/")))
