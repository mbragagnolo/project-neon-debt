"""Projectiles, light and particle textures.

The interface's frames used to live here too; they moved to ui/sprites.py in
M8 and are written by the ui-artist's sprites.py, which draws them from the
same palette and proves the move byte for byte.
"""
import os
import math
from PIL import Image
from pixel import draw, save, upscale, ASSETS, PALETTE, preview

HERE = os.path.dirname(os.path.abspath(__file__))
L = {"o": "outline", "a": "amber", "A": "amber_d", "w": "white", "y": "grey", "Y": "grey_d",
     "n": "sodium", "r": "red", "R": "red_d", "c": "cyan", "C": "cyan_d", "m": "magenta",
     "s": "steel2", "S": "steel3", "t": "steel1", "b": "bg0", "B": "bg1", "d": "bg2", "v": "violet"}

PLAY = 2   # texture px per art px on the play plane (bible/art.json)

# Art pixels at PLAY, so a projectile's pixel is the pixel of the character
# that fired it. These were drawn at 3 until the art-director's first review
# (art/reviews/2026-09-16/). An effect may keep its outline -- it fires over
# an actor's frame and has to read against whatever is behind it -- which is
# why `o` survives here and not in make_props.py.
PROJECTILES = {
    "bolt": [
        "oaaaaaaaw",
        "oAaaaaaaw",
        "oAAaaaaaw",
    ],
    "nail": [
        "yyyyyw",
        "YYyyyw",
        "YYYyyw",
    ],
    "rivet": [   # 12x4: 24x8 texture, one px off the old 9 because 3 is odd
        "..onnnnnww..",
        ".onnnnnnnnw.",
        ".onnnnnnnnw.",
        "..oAAnnnnw..",
    ],
    "drone_shot": [
        "..ooooo..",
        ".ooRRRoo.",
        "orRRRRRro",
        "oRRrrrRRo",
        "oRrrwrrRo",
        "oRRrrrRRo",
        "orRRRRRro",
        ".ooRRRoo.",
        "..ooooo..",
    ],
    "beam": [   # 18x4: 36x8 texture, one px off the old 9 for the same reason
        "cccccccccccccccccc",
        "cwwwwwwwwwwwwwwwwc",
        "cwwwwwwwwwwwwwwwwc",
        "cccccccccccccccccc",
    ],
    "wave": [
        "......ooooooooo......",
        "....oonnnnnnnnnoo....",
        "..oonnnnnnnnnnnnnoo..",
        ".onnnAAAAAAAAAAAnnno.",
        ".onnAAAAaaaaaAAAAnno.",
        "onnAAAaaaaaaaaaAAAnno",
        "onnAAaaaaaaaaaaaAAAno",
        "onAAAaaaaaaaaaaaAAAno",
        "onAAaaaaaaaaaaaaAAAno",
        "oAAAaaaaaaaaaaaAAAAno",
        "oAAAAaaaaaaaaaAAAAAno",
        "oAAAAAAAAAAAAAAAAAAno",
        "oAAAAAAAAAAAAAAAAAAno",
        ".ooooooooooooooooooo.",
        ".....................",
    ],
}

# HUD nine-patches at 1x (8x8): a thin steel frame on a dark ground.


def radial(size, power=1.6):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    c = (size - 1) / 2.0
    for y in range(size):
        for x in range(size):
            d = math.hypot(x - c, y - c) / c
            a = max(0.0, 1.0 - d) ** power
            img.putpixel((x, y), (255, 255, 255, int(255 * a)))
    return img


def raw_save(img, rel):
    path = os.path.join(ASSETS, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path)
    return path


if __name__ == "__main__":
    for name, rows in PROJECTILES.items():
        w = max(len(r) for r in rows)
        save(draw([r.ljust(w, ".")[:w] for r in rows], L), "fx/%s.png" % name, scale=PLAY)
    raw_save(radial(128), "fx/light_soft.png")
    raw_save(radial(64, 1.0), "fx/light_hard.png")
    # particle textures: tiny, soft
    raw_save(radial(8, 1.2), "fx/dot.png")
    drop = Image.new("RGBA", (2, 10), (0, 0, 0, 0))
    for y in range(10):
        drop.putpixel((0, y), PALETTE["steel4"] + (int(255 * y / 9),))
        drop.putpixel((1, y), PALETTE["steel3"] + (int(180 * y / 9),))
    raw_save(drop, "fx/drop.png")
    spark = Image.new("RGBA", (6, 2), (0, 0, 0, 0))
    for x in range(6):
        spark.putpixel((x, 0), PALETTE["amber"] + (255,))
        spark.putpixel((x, 1), PALETTE["warm"] + (255,))
    raw_save(upscale(spark, 2), "fx/spark.png")
    puff = radial(16, 0.8)
    raw_save(puff, "fx/puff.png")
    print("fx written")
