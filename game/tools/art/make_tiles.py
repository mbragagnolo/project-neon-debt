"""Walls, ledges, hazards, backdrops and the skyline (docs/art/direction.md).

Solids are merged rectangles in multiples of the 60px tile, so a wall is a
NinePatchRect over a 3x3-tile texture: corners, edges, fill. One texture per
zone style. Backdrops are tileable squares; the skyline is two parallax
strips for the rooms that open onto the night.
"""
import os
import random
from PIL import Image
from pixel import PALETTE, save, upscale, ASSETS

T = 20  # art pixels per tile


def solid(w, h, color):
    return Image.new("RGBA", (w, h), PALETTE[color] + (255,))


def px(img, x, y, color):
    if 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((x, y), PALETTE[color] + (255,))


def hline(img, x0, x1, y, color):
    for x in range(x0, x1 + 1):
        px(img, x, y, color)


def vline(img, x, y0, y1, color):
    for y in range(y0, y1 + 1):
        px(img, x, y, color)


def rect(img, x0, y0, x1, y1, color):
    for y in range(y0, y1 + 1):
        hline(img, x0, x1, y, color)


# --- Wall styles ---------------------------------------------------------------------
# Each returns a 60x60 (3x3 tile) image: the centre tile is the fill, the
# outer ring the edges. The engine tiles the edges and fill (NinePatch, tile mode).

def wall_residential():
    img = solid(60, 60, "concrete1")
    rng = random.Random(1)
    # panel seams every 10px, faint
    for x in range(0, 60, 10):
        vline(img, x, 0, 59, "concrete0")
    for y in range(0, 60, 20):
        hline(img, 0, 59, y, "concrete0")
    # a few lighter flecks
    for _ in range(40):
        px(img, rng.randrange(60), rng.randrange(60), "concrete2")
    # edges: top lip lighter, sides darker, bottom dark
    rect(img, 0, 0, 59, 1, "concrete3")
    hline(img, 0, 59, 2, "concrete2")
    rect(img, 0, 0, 1, 59, "concrete0")
    rect(img, 58, 0, 59, 59, "concrete0")
    rect(img, 0, 57, 59, 59, "concrete0")
    hline(img, 0, 59, 56, "concrete0")
    return img


def wall_roof():
    img = solid(60, 60, "concrete0")
    rng = random.Random(2)
    for x in range(0, 60, 15):
        vline(img, x, 0, 59, "bg1")
    for _ in range(60):
        px(img, rng.randrange(60), rng.randrange(60), "concrete1")
    for _ in range(12):
        x = rng.randrange(60)
        y = rng.randrange(4, 60)
        vline(img, x, y, min(59, y + rng.randrange(3, 9)), "rust0")
    rect(img, 0, 0, 59, 1, "concrete2")
    hline(img, 0, 59, 2, "concrete1")
    # a hazard stripe along the very top of exterior walls
    for x in range(0, 60, 4):
        hline(img, x, x + 1, 0, "amber_d")
    rect(img, 0, 0, 1, 59, "bg1")
    rect(img, 58, 0, 59, 59, "bg1")
    rect(img, 0, 57, 59, 59, "bg1")
    return img


def wall_mezz():
    img = solid(60, 60, "steel1")
    for x in range(0, 60, 10):
        vline(img, x, 0, 59, "steel0")
    for y in range(0, 60, 10):
        hline(img, 0, 59, y, "steel0")
    for y in range(1, 60, 10):
        for x in range(1, 60, 10):
            px(img, x, y, "steel2")
    rect(img, 0, 0, 59, 1, "steel3")
    hline(img, 0, 59, 2, "steel2")
    rect(img, 0, 0, 1, 59, "steel0")
    rect(img, 58, 0, 59, 59, "steel0")
    rect(img, 0, 57, 59, 59, "steel0")
    return img


def wall_gut():
    img = solid(60, 60, "rust0")
    rng = random.Random(3)
    for _ in range(90):
        px(img, rng.randrange(60), rng.randrange(60), "rust1")
    for _ in range(30):
        px(img, rng.randrange(60), rng.randrange(60), "bg0")
    # plates with rivets
    for y in range(0, 60, 20):
        hline(img, 0, 59, y, "bg0")
        for x in range(3, 60, 10):
            px(img, x, y + 2, "rust2")
    for x in range(0, 60, 30):
        vline(img, x, 0, 59, "bg0")
    rect(img, 0, 0, 59, 1, "rust2")
    hline(img, 0, 59, 2, "rust1")
    rect(img, 0, 0, 1, 59, "bg0")
    rect(img, 58, 0, 59, 59, "bg0")
    rect(img, 0, 57, 59, 59, "bg0")
    return img


def wall_collections():
    img = solid(60, 60, "bg2")
    for x in range(0, 60, 20):
        vline(img, x, 0, 59, "bg1")
    for y in range(0, 60, 20):
        hline(img, 0, 59, y, "bg1")
    rect(img, 0, 0, 59, 0, "amber_d")
    hline(img, 0, 59, 1, "steel3")
    hline(img, 0, 59, 2, "bg3")
    rect(img, 0, 0, 1, 59, "bg1")
    rect(img, 58, 0, 59, 59, "bg1")
    rect(img, 0, 57, 59, 59, "bg1")
    return img


def wall_shaft():
    img = solid(60, 60, "steel0")
    for x in range(0, 60, 12):
        vline(img, x, 0, 59, "bg1")
    for y in range(6, 60, 12):
        for x in range(6, 60, 12):
            px(img, x, y, "steel1")
    rect(img, 0, 0, 59, 1, "steel2")
    rect(img, 0, 0, 1, 59, "bg1")
    rect(img, 58, 0, 59, 59, "bg1")
    rect(img, 0, 57, 59, 59, "bg1")
    return img


WALLS = {
    "residential": wall_residential,
    "roof": wall_roof,
    "mezz": wall_mezz,
    "gut": wall_gut,
    "collections": wall_collections,
    "shaft": wall_shaft,
}


# --- Backdrops ---------------------------------------------------------------------------
# 40x40 tileable interiors, dark: they sit behind everything under the lights.

def back_residential():
    img = solid(40, 40, "bg1")
    for y in range(0, 40, 20):
        hline(img, 0, 39, y, "bg0")
    for x in range(0, 40, 40):
        vline(img, x, 0, 39, "bg0")
    # wainscot line
    hline(img, 0, 39, 30, "bg2")
    return img


def back_roof():
    img = Image.new("RGBA", (40, 40), PALETTE["void"] + (255,))
    rng = random.Random(4)
    for _ in range(3):
        px(img, rng.randrange(40), rng.randrange(40), "steel1")
    return img


def back_mezz():
    img = solid(40, 40, "bg1")
    for x in range(0, 40, 8):
        vline(img, x, 0, 39, "bg0")
    vline(img, 20, 0, 39, "bg2")
    return img


def back_gut():
    img = solid(40, 40, "bg0")
    rng = random.Random(5)
    for _ in range(30):
        px(img, rng.randrange(40), rng.randrange(40), "rust0")
    hline(img, 0, 39, 12, "bg1")
    hline(img, 0, 39, 13, "rust0")
    return img


def back_collections():
    img = solid(40, 40, "bg0")
    for x in range(0, 40, 20):
        vline(img, x, 0, 39, "bg1")
    hline(img, 0, 39, 8, "bg1")
    px(img, 20, 8, "amber_d")
    return img


BACKS = {
    "residential": back_residential,
    "roof": back_roof,
    "mezz": back_mezz,
    "gut": back_gut,
    "collections": back_collections,
    "shaft": back_mezz,
}


# --- Ledges, hazards, void --------------------------------------------------------------

def platform_strip():
    img = solid(20, 5, "steel2")
    for x in range(1, 20, 3):
        vline(img, x, 2, 4, "steel0")
    hline(img, 0, 19, 1, "steel3")
    hline(img, 0, 19, 0, "steel4")
    return img


def hazard_frames():
    frames = []
    for f in range(3):
        img = solid(20, 20, "cyan_d")
        rect(img, 0, 0, 19, 19, "cyan_d")
        # darker body, bright crests moving right
        for y in range(4, 20):
            hline(img, 0, 19, y, "bg2" if y % 3 else "cyan_d")
        for x in range(0, 20, 5):
            xx = (x + f * 2) % 20
            px(img, xx, 1, "cyan")
            px(img, (xx + 1) % 20, 1, "cyan")
            px(img, (xx + 3) % 20, 2, "white")
        hline(img, 0, 19, 0, "cyan")
        frames.append(img)
    return frames


# --- The skyline -----------------------------------------------------------------------------

def skyline(seed, base, window, min_h, max_h, density):
    """A 320x180 strip of tower silhouettes with lit windows, tileable."""
    img = Image.new("RGBA", (320, 180), (0, 0, 0, 0))
    rng = random.Random(seed)
    x = 0
    while x < 320:
        w = rng.randrange(14, 40)
        h = rng.randrange(min_h, max_h)
        for yy in range(180 - h, 180):
            for xx in range(x, min(320, x + w)):
                img.putpixel((xx, yy), PALETTE[base] + (255,))
        # antenna
        if rng.random() < 0.3:
            for yy in range(180 - h - rng.randrange(4, 12), 180 - h):
                img.putpixel((x + w // 2, yy), PALETTE[base] + (255,))
            img.putpixel((x + w // 2, 180 - h - 1), PALETTE["red"] + (255,))
        # windows
        for yy in range(180 - h + 3, 178, 4):
            for xx in range(x + 2, min(320, x + w) - 1, 4):
                if rng.random() < density:
                    img.putpixel((xx, yy), PALETTE[window] + (255,))
        x += w + rng.randrange(0, 6)
    return img


if __name__ == "__main__":
    for name, fn in WALLS.items():
        # A style with a set json is made by swatch.py from a diffused
        # material (docs/art/environment.md); the ASCII wall is superseded.
        if os.path.exists(os.path.join(os.path.dirname(os.path.abspath(__file__)), "sets", "%s.json" % name)):
            print("wall_%s: made by swatch.py, skipped" % name)
            continue
        save(fn(), "tiles/wall_%s.png" % name)
    for name, fn in BACKS.items():
        save(fn(), "tiles/back_%s.png" % name)
    save(platform_strip(), "tiles/platform.png")
    for i, f in enumerate(hazard_frames()):
        save(f, "tiles/hazard_%d.png" % i)
    save(skyline(11, "bg1", "amber_d", 40, 120, 0.22), "tiles/skyline_far.png")
    save(skyline(12, "bg2", "warm", 60, 160, 0.3), "tiles/skyline_near.png")
    # a soft vertical gradient for the night, 1x wide
    grad = Image.new("RGBA", (1, 180), (0, 0, 0, 0))
    for y in range(180):
        t = y / 179.0
        c0 = PALETTE["void"]
        c1 = PALETTE["bg2"]
        grad.putpixel((0, y), tuple(int(c0[i] + (c1[i] - c0[i]) * t) for i in range(3)) + (255,))
    save(grad, "tiles/sky_gradient.png")
    print("tiles written")
