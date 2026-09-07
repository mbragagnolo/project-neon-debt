"""Pixel-art toolkit for the Neon Debt art pass (docs/art/direction.md).

Sprites are authored as ASCII grids, one character per pixel, against a
shared palette, at 1x (a 60px greybox tile is 20 art pixels). They are
saved pre-scaled 3x with nearest-neighbour so the engine never resamples
them: at a 1280x720 window every art pixel is exactly 2 screen pixels, at
1080p 3, at 1440p 4, at 4K 6.

Run any `make_*.py` in this folder from the repo's game/ directory.
"""
import os
from PIL import Image

SCALE = 3
ASSETS = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "assets")

# --- The palette -----------------------------------------------------------------
# Dark, cold base; four neons; warm sodium light for the lived-in corners.
PALETTE = {
    # base
    "void":     (7, 8, 15),
    "bg0":      (13, 16, 24),
    "bg1":      (20, 26, 38),
    "bg2":      (28, 36, 54),
    "bg3":      (38, 48, 70),
    # steel and concrete
    "steel0":   (33, 39, 54),
    "steel1":   (48, 56, 76),
    "steel2":   (68, 78, 104),
    "steel3":   (105, 120, 156),
    "steel4":   (150, 166, 200),
    "concrete0": (36, 38, 46),
    "concrete1": (58, 61, 72),
    "concrete2": (92, 96, 110),
    "concrete3": (130, 134, 148),
    # rust and warmth
    "rust0":    (58, 36, 32),
    "rust1":    (110, 62, 48),
    "rust2":    (170, 104, 78),
    "sodium":   (255, 159, 67),
    "warm":     (255, 217, 160),
    # neons
    "cyan":     (34, 230, 255),
    "cyan_d":   (14, 120, 140),
    "magenta":  (255, 46, 148),
    "magenta_d": (140, 22, 80),
    "amber":    (255, 184, 51),
    "amber_d":  (150, 100, 20),
    "green":    (109, 255, 140),
    "green_d":  (40, 140, 70),
    "violet":   (157, 107, 255),
    "violet_d": (80, 50, 150),
    "red":      (255, 80, 80),
    "red_d":    (140, 30, 40),
    # people
    "outline":  (11, 13, 20),
    "skin":     (224, 165, 140),
    "skin_d":   (160, 106, 85),
    "skin2":    (150, 100, 70),
    "skin2_d":  (100, 62, 45),
    "hair":     (26, 20, 24),
    "hair_h":   (60, 44, 52),
    "white":    (236, 240, 248),
    "grey":     (154, 163, 184),
    "grey_d":   (100, 108, 128),
    "navy":     (43, 54, 84),
    "navy_l":   (61, 74, 112),
    "navy_d":   (28, 34, 51),
    "black":    (21, 23, 31),
    "black_l":  (44, 48, 64),
    "chrome":   (200, 208, 224),
    "chrome_d": (120, 130, 150),
    "olive":    (78, 84, 58),
    "olive_l":  (110, 118, 82),
    # hi-bit ramps (docs/art/refs/README.md): a fourth and fifth step per
    # material so a shaded still has somewhere to land after the snap. The
    # neutral ramp is black / concrete0-3 / grey, already six steps.
    "navy_ll":  (86, 102, 150),
    "skin_l":   (240, 200, 178),
    "skin_dd":  (112, 70, 58),
    "hair_l":   (92, 74, 86),
    "cyan_l":   (170, 246, 255),
    "magenta_l": (255, 140, 200),
    # Roster ramps (the enemies' and NPCs' materials had two or three steps):
    # olive and rust get a dark and a light end, amber a highlight for the eye.
    "olive_d":  (50, 55, 36),
    "olive_ll": (146, 156, 112),
    "rust3":    (214, 150, 118),
    "amber_l":  (255, 224, 150),
    "red_l":    (255, 150, 140),
}


def draw(rows, legend, size=None):
    """ASCII rows -> RGBA image. `legend` maps a character to a palette key.
    '.' and ' ' are transparent."""
    h = len(rows)
    w = max(len(r) for r in rows)
    if size:
        w, h = size
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = img.load()
    for y, row in enumerate(rows):
        for x, c in enumerate(row):
            if c in ". ":
                continue
            key = legend[c]
            px[x, y] = PALETTE[key] + (255,)
    return img


def flip(img):
    return img.transpose(Image.FLIP_LEFT_RIGHT)


def upscale(img, scale=SCALE):
    return img.resize((img.width * scale, img.height * scale), Image.NEAREST)


def sheet(frames, columns=None):
    """Frames of identical size -> one horizontal (or wrapped) sheet."""
    if columns is None:
        columns = len(frames)
    w, h = frames[0].size
    rows = (len(frames) + columns - 1) // columns
    out = Image.new("RGBA", (w * columns, h * rows), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        assert f.size == (w, h), (i, f.size, (w, h))
        out.paste(f, ((i % columns) * w, (i // columns) * h))
    return out


def save(img, rel_path, scale=SCALE):
    path = os.path.join(ASSETS, rel_path)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    upscale(img, scale).save(path)
    return path


def preview(img, rel_path, scale=6):
    """A large copy on a dark ground, for eyeballing."""
    big = upscale(img, scale)
    ground = Image.new("RGBA", big.size, (40, 44, 52, 255))
    ground.alpha_composite(big)
    os.makedirs(os.path.dirname(rel_path), exist_ok=True)
    ground.save(rel_path)


def shift(rows, dx=0, dy=0, size=None):
    """Move a grid inside its box (positive dy = down)."""
    h = len(rows)
    w = max(len(r) for r in rows)
    if size:
        w, h = size
    blank = ["." * w for _ in range(h)]
    for y, row in enumerate(rows):
        ty = y + dy
        if 0 <= ty < h:
            line = list(blank[ty])
            for x, c in enumerate(row):
                tx = x + dx
                if 0 <= tx < w and c not in ". ":
                    line[tx] = c
            blank[ty] = "".join(line)
    return blank


def overlay(base, *layers):
    """Later layers paint over earlier ones; '.' is transparent."""
    h = len(base)
    w = max(len(r) for r in base)
    out = [list(r.ljust(w, ".")) for r in base]
    for layer in layers:
        for y, row in enumerate(layer):
            if y >= h:
                break
            for x, c in enumerate(row):
                if x < w and c not in ". ":
                    out[y][x] = c
    return ["".join(r) for r in out]


def blank(w, h):
    return ["." * w for _ in range(h)]
