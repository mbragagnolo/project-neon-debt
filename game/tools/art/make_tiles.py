"""Walls, ledges, hazards, backdrops and the skyline (docs/art/direction.md).

Solids are merged rectangles in multiples of the 60px tile, so a wall is a
NinePatchRect over a 3x3-tile texture: corners, edges, fill. One texture per
zone style. Backdrops are tileable squares; the skyline is two parallax
strips for the rooms that open onto the night.

Re-authored 2026-09-16 at the play plane's density (art-director's first
review, art/reviews/2026-09-16/). Everything here used to be drawn at 20 art
px per tile and saved at 3, which is 3 texture px per art pixel where the
play plane is 2 and the characters are: a hazard stripe's pixel was half
again the size of the pixel of the woman standing on it. `T` was declared as
"art pixels per tile" and then never used, and 60 was typed forty times
instead -- which is how the drift got in and stayed invisible. Now every
structural size derives from T, so the density is one number.

Every texture keeps the size it had (a wall is still 180x180, a back still
120x120), so nothing downstream -- the dress files, make_stacks.gd, the
colliders -- can tell the difference. Detail spacings are the old ones at
1.5x, because what was authored was the apparent size, not the pixel count.
"""
import os
import random
from PIL import Image
from pixel import PALETTE, save

T = 30              # art pixels per 60 px tile, at PLAY
PLAY = 2            # texture px per art px on the play plane (bible/art.json)
OUTSIDE = 4         # ... and on the outside plane, which is far and parallaxes

WALL = 3 * T        # a wall texture is 3x3 tiles: corners, edges, fill
BACK = 2 * T        # a backdrop is a tileable 2x2
HAZ = T             # one tile
LEDGE_H = 6         # 12 texture px, which is make_stacks.gd's ledge thickness
SKY_W, SKY_H = 240, 135   # x OUTSIDE = the 960x540 strip the parallax expects


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
# Each returns a WALL x WALL (3x3 tile) image: the centre tile is the fill, the
# outer ring the edges. The engine tiles the edges and fill (NinePatch, tile mode).
# E is the ring's thickness in art px; at PLAY it is 6 texture px, the same lip
# the walls have always had.

E = 3
LAST = WALL - 1


def wall_residential():
    img = solid(WALL, WALL, "concrete1")
    rng = random.Random(1)
    # panel seams every half tile, faint
    for x in range(0, WALL, T // 2):
        vline(img, x, 0, LAST, "concrete0")
    for y in range(0, WALL, T):
        hline(img, 0, LAST, y, "concrete0")
    # a few lighter flecks
    for _ in range(90):
        px(img, rng.randrange(WALL), rng.randrange(WALL), "concrete2")
    # edges: top lip lighter, sides darker, bottom dark
    rect(img, 0, 0, LAST, E - 1, "concrete3")
    rect(img, 0, E, LAST, E + 1, "concrete2")
    rect(img, 0, 0, E - 1, LAST, "concrete0")
    rect(img, WALL - E, 0, LAST, LAST, "concrete0")
    rect(img, 0, WALL - E - 1, LAST, LAST, "concrete0")
    hline(img, 0, LAST, WALL - E - 6, "concrete0")
    return img


def wall_roof():
    img = solid(WALL, WALL, "concrete0")
    rng = random.Random(2)
    for x in range(0, WALL, 22):
        vline(img, x, 0, LAST, "bg1")
    for _ in range(135):
        px(img, rng.randrange(WALL), rng.randrange(WALL), "concrete1")
    for _ in range(18):
        x = rng.randrange(WALL)
        y = rng.randrange(6, WALL)
        vline(img, x, y, min(LAST, y + rng.randrange(4, 13)), "rust0")
    rect(img, 0, 0, LAST, E - 1, "concrete2")
    rect(img, 0, E, LAST, E + 1, "concrete1")
    # a hazard stripe along the very top of exterior walls
    for x in range(0, WALL, 6):
        rect(img, x, 0, x + 2, E - 2, "amber_d")
    rect(img, 0, 0, E - 1, LAST, "bg1")
    rect(img, WALL - E, 0, LAST, LAST, "bg1")
    rect(img, 0, WALL - E - 1, LAST, LAST, "bg1")
    return img


def wall_mezz():
    img = solid(WALL, WALL, "steel1")
    for x in range(0, WALL, T // 2):
        vline(img, x, 0, LAST, "steel0")
    for y in range(0, WALL, T // 2):
        hline(img, 0, LAST, y, "steel0")
    for y in range(2, WALL, T // 2):
        for x in range(2, WALL, T // 2):
            px(img, x, y, "steel2")
    rect(img, 0, 0, LAST, E - 1, "steel3")
    rect(img, 0, E, LAST, E + 1, "steel2")
    rect(img, 0, 0, E - 1, LAST, "steel0")
    rect(img, WALL - E, 0, LAST, LAST, "steel0")
    rect(img, 0, WALL - E - 1, LAST, LAST, "steel0")
    return img


def wall_gut():
    img = solid(WALL, WALL, "rust0")
    rng = random.Random(3)
    for _ in range(200):
        px(img, rng.randrange(WALL), rng.randrange(WALL), "rust1")
    for _ in range(68):
        px(img, rng.randrange(WALL), rng.randrange(WALL), "bg0")
    # plates with rivets
    for y in range(0, WALL, T):
        hline(img, 0, LAST, y, "bg0")
        for x in range(5, WALL, T // 2):
            px(img, x, y + 3, "rust2")
    for x in range(0, WALL, T + T // 2):
        vline(img, x, 0, LAST, "bg0")
    rect(img, 0, 0, LAST, E - 1, "rust2")
    rect(img, 0, E, LAST, E + 1, "rust1")
    rect(img, 0, 0, E - 1, LAST, "bg0")
    rect(img, WALL - E, 0, LAST, LAST, "bg0")
    rect(img, 0, WALL - E - 1, LAST, LAST, "bg0")
    return img


def wall_collections():
    img = solid(WALL, WALL, "bg2")
    for x in range(0, WALL, T):
        vline(img, x, 0, LAST, "bg1")
    for y in range(0, WALL, T):
        hline(img, 0, LAST, y, "bg1")
    rect(img, 0, 0, LAST, 1, "amber_d")
    rect(img, 0, 2, LAST, 3, "steel3")
    rect(img, 0, 4, LAST, 5, "bg3")
    rect(img, 0, 0, E - 1, LAST, "bg1")
    rect(img, WALL - E, 0, LAST, LAST, "bg1")
    rect(img, 0, WALL - E - 1, LAST, LAST, "bg1")
    return img


def wall_shaft():
    img = solid(WALL, WALL, "steel0")
    for x in range(0, WALL, 18):
        vline(img, x, 0, LAST, "bg1")
    for y in range(9, WALL, 18):
        for x in range(9, WALL, 18):
            px(img, x, y, "steel1")
    rect(img, 0, 0, LAST, E - 1, "steel2")
    rect(img, 0, 0, E - 1, LAST, "bg1")
    rect(img, WALL - E, 0, LAST, LAST, "bg1")
    rect(img, 0, WALL - E - 1, LAST, LAST, "bg1")
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
# BACK x BACK tileable interiors, dark: they sit behind everything under the lights.

BLAST = BACK - 1


def back_residential():
    img = solid(BACK, BACK, "bg1")
    for y in range(0, BACK, T):
        hline(img, 0, BLAST, y, "bg0")
    vline(img, 0, 0, BLAST, "bg0")
    # wainscot line
    hline(img, 0, BLAST, 45, "bg2")
    return img


def back_roof():
    img = Image.new("RGBA", (BACK, BACK), PALETTE["void"] + (255,))
    rng = random.Random(4)
    for _ in range(7):
        px(img, rng.randrange(BACK), rng.randrange(BACK), "steel1")
    return img


def back_mezz():
    img = solid(BACK, BACK, "bg1")
    for x in range(0, BACK, 12):
        vline(img, x, 0, BLAST, "bg0")
    vline(img, BACK // 2, 0, BLAST, "bg2")
    return img


def back_gut():
    img = solid(BACK, BACK, "bg0")
    rng = random.Random(5)
    for _ in range(68):
        px(img, rng.randrange(BACK), rng.randrange(BACK), "rust0")
    hline(img, 0, BLAST, 18, "bg1")
    hline(img, 0, BLAST, 19, "rust0")
    return img


def back_collections():
    img = solid(BACK, BACK, "bg0")
    for x in range(0, BACK, T):
        vline(img, x, 0, BLAST, "bg1")
    hline(img, 0, BLAST, 12, "bg1")
    px(img, BACK // 2, 12, "amber_d")
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
    """T x LEDGE_H: one tile wide, and exactly the 12 texture px make_stacks.gd
    draws a ledge at. The old strip was 15 texture px tall and its bottom three
    rows were never on screen."""
    img = solid(T, LEDGE_H, "steel2")
    # rivets every 5 art px, which divides T: the old spacing did not divide the
    # strip's width, so the pattern broke at every horizontal tile seam.
    for x in range(1, T, 5):
        vline(img, x, 3, LEDGE_H - 1, "steel0")
    rect(img, 0, 2, T - 1, 2, "steel3")
    rect(img, 0, 0, T - 1, 1, "steel4")
    return img


def hazard_frames():
    frames = []
    for f in range(3):
        img = solid(HAZ, HAZ, "cyan_d")
        # The body goes down the bg ramp as it deepens, with a cyan_d crest
        # every fourth row. It used to be one flat bg2, which the art-director
        # read as one step of a ramp over 540 art px: a hazard the player has
        # to judge the depth of, drawn with no depth in it.
        # The ramp is centred on bg2, which is what the flat body used to be:
        # adding depth should not quietly darken the room the hazard is in.
        for y in range(6, HAZ):
            depth = "bg3" if y < 13 else ("bg2" if y < 22 else "bg1")
            hline(img, 0, HAZ - 1, y, depth if y % 4 else "cyan_d")
        for x in range(0, HAZ, 7):
            xx = (x + f * 3) % HAZ
            for i in range(3):
                px(img, (xx + i) % HAZ, 2, "cyan")
            px(img, (xx + 5) % HAZ, 4, "white")
        rect(img, 0, 0, HAZ - 1, 1, "cyan")
        frames.append(img)
    return frames


# --- The skyline -----------------------------------------------------------------------------

def skyline(seed, base, window, min_h, max_h, density):
    """A SKY_W x SKY_H strip of tower silhouettes with lit windows, tileable.

    Authored at OUTSIDE, not PLAY: it is the far plane, it parallaxes, and the
    shading bar says a far plane drops pixels rather than detail."""
    img = Image.new("RGBA", (SKY_W, SKY_H), (0, 0, 0, 0))
    rng = random.Random(seed)
    x = 0
    while x < SKY_W:
        w = rng.randrange(11, 30)
        h = rng.randrange(min_h, max_h)
        for yy in range(SKY_H - h, SKY_H):
            for xx in range(x, min(SKY_W, x + w)):
                img.putpixel((xx, yy), PALETTE[base] + (255,))
        # antenna. `px` guards the edge: a tower starting near the right of the
        # strip can put its mast past it, which the 320 px strip never happened
        # to hit and the 240 px one does.
        if rng.random() < 0.3:
            ax = x + w // 2
            for yy in range(SKY_H - h - rng.randrange(3, 9), SKY_H - h):
                px(img, ax, yy, base)
            px(img, ax, SKY_H - h - 1, "red")
        # windows
        for yy in range(SKY_H - h + 2, SKY_H - 2, 3):
            for xx in range(x + 2, min(SKY_W, x + w) - 1, 3):
                if rng.random() < density:
                    img.putpixel((xx, yy), PALETTE[window] + (255,))
        x += w + rng.randrange(0, 5)
    return img


if __name__ == "__main__":
    for name, fn in WALLS.items():
        # A style with a set json is made by swatch.py from a diffused
        # material (docs/art/environment.md); the ASCII wall is superseded.
        if os.path.exists(os.path.join(os.path.dirname(os.path.abspath(__file__)), "sets", "%s.json" % name)):
            print("wall_%s: made by swatch.py, skipped" % name)
            continue
        save(fn(), "tiles/wall_%s.png" % name, scale=PLAY)
    for name, fn in BACKS.items():
        save(fn(), "tiles/back_%s.png" % name, scale=PLAY)
    save(platform_strip(), "tiles/platform.png", scale=PLAY)
    for i, f in enumerate(hazard_frames()):
        save(f, "tiles/hazard_%d.png" % i, scale=PLAY)
    save(skyline(11, "bg1", "amber_d", 30, 90, 0.22), "tiles/skyline_far.png", scale=OUTSIDE)
    save(skyline(12, "bg2", "warm", 45, 120, 0.3), "tiles/skyline_near.png", scale=OUTSIDE)
    # a soft vertical gradient for the night, 1x wide. No density: a gradient is
    # the one thing the palette cannot hold, and it is stretched across the sky.
    grad = Image.new("RGBA", (1, 180), (0, 0, 0, 0))
    for y in range(180):
        t = y / 179.0
        c0 = PALETTE["void"]
        c1 = PALETTE["bg2"]
        grad.putpixel((0, y), tuple(int(c0[i] + (c1[i] - c0[i]) * t) for i in range(3)) + (255,))
    save(grad, "tiles/sky_gradient.png")
    print("tiles written")
