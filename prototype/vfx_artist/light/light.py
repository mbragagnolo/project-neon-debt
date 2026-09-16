"""The light spike driver: shoot 14-C through light_shot.gd in each mode,
measure every shot with the level-artist's ref_stats (the budget) and a
halo width on the window and the notice, and lay the crops side by side.

    python light.py                # every variant below
    python light.py --only today,glow_soft
"""
import argparse
import os
import shutil
import subprocess
import sys

import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
GAME = os.path.normpath(os.path.join(HERE, "..", "..", "..", "game"))
OUT = os.path.join(HERE, "out")
sys.path.insert(0, r"F:\Projects\Coding Projects\kiln\skills\level-artist\scripts")
import ref_stats  # noqa: E402

PLAYER = "330,900"
VARIANTS = {
    "today": {"mode": "today"},
    "hdr_only": {"mode": "glow", "hdr": "1", "intensity": "0.0"},
    "glow_soft": {"mode": "glow", "hdr": "1", "threshold": "0.7", "intensity": "0.6", "strength": "0.9", "bloom": "0.0", "blend": "softlight", "levels": "3,5"},
    "glow_add_hdr": {"mode": "glow", "hdr": "1", "threshold": "0.45", "intensity": "0.8", "strength": "1.0", "bloom": "0.1", "blend": "additive", "levels": "3,5,7"},
    "glow_add_ldr": {"mode": "glow", "hdr": "0", "threshold": "0.45", "intensity": "0.8", "strength": "1.0", "bloom": "0.1", "blend": "additive", "levels": "3,5,7"},
    "glow_screen_ldr": {"mode": "glow", "hdr": "0", "threshold": "0.4", "intensity": "0.7", "strength": "1.0", "bloom": "0.05", "blend": "screen", "levels": "2,4,6"},
    "shaft_ldr": {"mode": "shaft", "hdr": "0", "threshold": "0.45", "intensity": "0.8", "strength": "1.0", "bloom": "0.1", "blend": "additive", "levels": "3,5,7",
                  "shaft_alpha": "0.28", "shaft_lean": "220", "shaft_spread": "80"},
    "shaft_faint_ldr": {"mode": "shaft", "hdr": "0", "threshold": "0.45", "intensity": "0.8", "strength": "1.0", "bloom": "0.1", "blend": "additive", "levels": "3,5,7",
                        "shaft_alpha": "0.16", "shaft_lean": "260", "shaft_spread": "60"},
    "glow_low_ldr": {"mode": "glow", "hdr": "0", "threshold": "0.25", "intensity": "1.4", "strength": "1.0", "bloom": "0.2", "blend": "additive", "levels": "2,3,5"},
    "glow_hot_hdr": {"mode": "glow", "hdr": "1", "threshold": "0.9", "intensity": "1.0", "strength": "1.0", "bloom": "0.1", "blend": "additive", "levels": "3,5", "boost": "2.5"},
    "shaft_soft": {"mode": "shaft", "hdr": "0", "threshold": "0.45", "intensity": "0.8", "strength": "1.0", "bloom": "0.1", "blend": "additive", "levels": "3,5,7",
                   "shaft_alpha": "0.22", "shaft_lean": "240", "shaft_spread": "120"},
    "shaft_soft_faint": {"mode": "shaft", "hdr": "0", "threshold": "0.45", "intensity": "0.8", "strength": "1.0", "bloom": "0.1", "blend": "additive", "levels": "3,5,7",
                         "shaft_alpha": "0.14", "shaft_lean": "240", "shaft_spread": "120"},
}


GODOT = next((shutil.which(n) for n in ("godot.exe", "godot.cmd", "godot") if shutil.which(n)), "godot")


def shoot(name, params):
    png = os.path.join(OUT, f"shot_{name}.png")
    cmd = [GODOT, "--path", GAME, "--windowed", "--resolution", "1920x1080", "-s", os.path.join(HERE, "light_shot.gd"), "--",
           f"out={png}", f"player={PLAYER}"] + [f"{k}={v}" for k, v in params.items()]
    p = subprocess.run(cmd, capture_output=True, text=True, timeout=120, encoding="utf-8", errors="replace")
    log = (p.stdout or "") + (p.stderr or "")
    open(os.path.join(OUT, f"run_{name}.log"), "w", encoding="utf-8").write(log)
    err = [l for l in log.splitlines() if "SCRIPT ERROR" in l]
    if err:
        print(name, err[0])
    return png if os.path.exists(png) else None


def halo(png, edge_x, y0, y1, direction, threshold=110):
    """How many screen px past a bright surface's edge the luma stays above
    `threshold`, averaged over rows y0..y1: the bloom's reach."""
    arr = np.array(Image.open(png).convert("RGB")).astype(np.float32)
    luma = arr @ np.array([0.2126, 0.7152, 0.0722], dtype=np.float32)
    widths = []
    for y in range(y0, y1):
        w = 0
        x = edge_x
        while 0 <= x < luma.shape[1] and luma[y, x] >= threshold and w < 200:
            w += 1
            x += direction
        widths.append(w)
    return float(np.mean(widths))


def band_luma(png, box):
    arr = np.array(Image.open(png).convert("RGB").crop(box)).astype(np.float32)
    return float((arr @ np.array([0.2126, 0.7152, 0.0722], dtype=np.float32)).mean())


def compare(names, box, zoom=1, out="compare.png"):
    tiles = []
    for name in names:
        png = os.path.join(OUT, f"shot_{name}.png")
        if not os.path.exists(png):
            continue
        im = Image.open(png).convert("RGB").crop(box)
        im = im.resize((im.width * zoom, im.height * zoom), Image.NEAREST)
        ImageDraw.Draw(im).text((6, 6), name, fill=(255, 220, 80))
        tiles.append(im)
    if not tiles:
        return
    w, h = tiles[0].size
    cols = 2
    rows = (len(tiles) + cols - 1) // cols
    board = Image.new("RGB", (cols * (w + 6), rows * (h + 6)), (30, 32, 40))
    for i, t in enumerate(tiles):
        board.paste(t, ((i % cols) * (w + 6), (i // cols) * (h + 6)))
    path = os.path.join(OUT, out)
    board.save(path)
    print("wrote", path, board.size)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", default=None)
    ap.add_argument("--no-shoot", action="store_true")
    args = ap.parse_args()
    os.makedirs(OUT, exist_ok=True)
    names = args.only.split(",") if args.only else list(VARIANTS)
    rows = []
    for name in names:
        png = os.path.join(OUT, f"shot_{name}.png")
        if not args.no_shoot:
            png = shoot(name, VARIANTS[name])
        if not png or not os.path.exists(png):
            print(name, "no shot")
            continue
        s = ref_stats.stats(png)
        # The glass is room px 846..1074 x 606..954; the camera sits at (640, 720) at 1.5x,
        # so on screen it is x 1269..1611, y 369..891. A band just outside its left edge is
        # where a halo shows; a band on the wall far from any source is the control.
        s["halo"] = band_luma(png, (1225, 380, 1265, 880))
        s["wall"] = band_luma(png, (900, 380, 1000, 600))
        rows.append((name, s))
        print(ref_stats.line(png, s), f" halo band {s['halo']:.1f}  wall {s['wall']:.1f}")
    print("\n| shot | dark | mid | bright | cold | luma outside the glass | luma on the far wall |")
    for name, s in rows:
        print(f"| {name} | {s['dark']:.0%} | {s['mid']:.0%} | {s['bright']:.0%} | {s['cold']:.0%} | {s['halo']:.1f} | {s['wall']:.1f} |")
    compare(names, (700, 320, 1900, 1040))
    edge = [n for n in ("today", "glow_add_ldr", "glow_low_ldr", "glow_hot_hdr", "shaft_soft", "shaft_soft_faint") if n in names]
    compare(edge, (1000, 340, 1700, 940), out="edge.png")


if __name__ == "__main__":
    main()
