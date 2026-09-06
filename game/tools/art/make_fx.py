"""Projectiles, light and particle textures, and the HUD's pixel frames."""
import os
import math
from PIL import Image
from pixel import draw, save, upscale, ASSETS, PALETTE, preview

HERE = os.path.dirname(os.path.abspath(__file__))
L = {"o": "outline", "a": "amber", "A": "amber_d", "w": "white", "y": "grey", "Y": "grey_d",
     "n": "sodium", "r": "red", "R": "red_d", "c": "cyan", "C": "cyan_d", "m": "magenta",
     "s": "steel2", "S": "steel3", "t": "steel1", "b": "bg0", "B": "bg1", "d": "bg2", "v": "violet"}

PROJECTILES = {
    "bolt": ["oaaaaw", "oAaaaw"],
    "nail": ["yyyw", "YYyw"],
    "rivet": [".onnnw..", "onnnnnnw", ".oAnnnw."],
    "drone_shot": [".oooo.", "orRRro", "oRrwro", "oRwwro", "orRRro", ".oooo."],
    "beam": ["cccccccccccc", "cwwwwwwwwwwc", "cccccccccccc"],
    "wave": [
        ".....oooo.....",
        "...oonnnnoo...",
        "..onnnnnnnno..",
        ".onnAAAAAAnno.",
        ".onAAaaaaAAno.",
        "onAaaaaaaaAno.",
        "onAaaaaaaaAAno",
        "oAAaaaaaaAAAno",
        "oAAAAAAAAAAAno",
        ".oooooooooooo.",
    ],
}

# HUD nine-patches at 1x (8x8): a thin steel frame on a dark ground.
HUD_FRAME = [
    "oSSSSSSo",
    "SBBBBBBS",
    "SBBBBBBS",
    "SBBBBBBS",
    "SBBBBBBS",
    "SBBBBBBS",
    "SBBBBBBS",
    "oSSSSSSo",
]
PANEL_FRAME = [
    "ooSSSSoo",
    "oSbbbbSo",
    "SbbbbbbS",
    "SbbbbbbS",
    "SbbbbbbS",
    "SbbbbbbS",
    "oSbbbbSo",
    "ooSSSSoo",
]
PIP_ON = ["oooooo", "oaaaao", "oawwao", "oaaaao", "oaaaao", "oooooo"]
PIP_OFF = ["oooooo", "oBBBBo", "oBBBBo", "oBBBBo", "oBBBBo", "oooooo"]
SLOT = [
    "oSSSSSSSSSSSSSSSSSSSSSSo",
    "SbbbbbbbbbbbbbbbbbbbbbbS",
    "SbbbbbbbbbbbbbbbbbbbbbbS",
    "SbbbbbbbbbbbbbbbbbbbbbbS",
    "SbbbbbbbbbbbbbbbbbbbbbbS",
    "SbbbbbbbbbbbbbbbbbbbbbbS",
    "SbbbbbbbbbbbbbbbbbbbbbbS",
    "SbbbbbbbbbbbbbbbbbbbbbbS",
    "SbbbbbbbbbbbbbbbbbbbbbbS",
    "SbbbbbbbbbbbbbbbbbbbbbbS",
    "SbbbbbbbbbbbbbbbbbbbbbbS",
    "SbbbbbbbbbbbbbbbbbbbbbbS",
    "SbbbbbbbbbbbbbbbbbbbbbbS",
    "SbbbbbbbbbbbbbbbbbbbbbbS",
    "SbbbbbbbbbbbbbbbbbbbbbbS",
    "SbbbbbbbbbbbbbbbbbbbbbbS",
    "SbbbbbbbbbbbbbbbbbbbbbbS",
    "SbbbbbbbbbbbbbbbbbbbbbbS",
    "SbbbbbbbbbbbbbbbbbbbbbbS",
    "SbbbbbbbbbbbbbbbbbbbbbbS",
    "SbbbbbbbbbbbbbbbbbbbbbbS",
    "SbbbbbbbbbbbbbbbbbbbbbbS",
    "SbbbbbbbbbbbbbbbbbbbbbbS",
    "oSSSSSSSSSSSSSSSSSSSSSSo",
]
CURSOR = ["o.......", "oo......", "owo.....", "owwo....", "owwwo...", "owwo....", "owo.....", "oo......"]
LOCK = ["..oooo..", ".oaaaao.", ".oa..ao.", "oaaaaaao", "oaaooaao", "oaaooaao", "oaaaaaao", ".oooooo."]


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
        save(draw([r.ljust(w, ".")[:w] for r in rows], L), "fx/%s.png" % name)
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
    for name, rows in {"hud_frame": HUD_FRAME, "panel_frame": PANEL_FRAME, "pip_on": PIP_ON,
                       "pip_off": PIP_OFF, "slot": SLOT, "cursor": CURSOR, "lock": LOCK}.items():
        save(draw(rows, L), "ui/%s.png" % name)
    print("fx written")
