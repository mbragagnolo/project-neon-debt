"""The A/B strips: every frame of every path, over the character frame that
is on screen at that moment, timed against the engine.

    python strip.py            # out/strip_<effect>.png, out/lineup.png, out/measure.json

A strip row is one authoring path (direct / bake / hot); a column is one
frame of the effect at its time t = k / fps, with the actor's own clip
advanced to t as PixelAnim would (hitstop holds both, so relative time is
preserved). Cells are 4x on the roster's grey, the size the roster was
judged at. The lineup shows the impact frame beside Dani and the Scav on
the game's dark ground at 1x and at 3x (the game's scale).
"""
import json
import os
import sys

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
GAME = os.path.normpath(os.path.join(HERE, "..", "..", "game"))
sys.path.insert(0, os.path.join(GAME, "tools", "art"))
from pixel import PALETTE  # noqa: E402

TAGS = ("direct", "bake", "hot")
AB_GROUND = (96, 100, 108, 255)
AB_FLOOR = (78, 82, 90, 255)
DARK = PALETTE["bg1"] + (255,)
DARK_FLOOR = PALETTE["bg2"] + (255,)

# The sheets as the engine has them (2x), reduced to art px; feet at the
# bottom centre of the frame, as rig.py places them.
SHEETS = {
    "dani": ("assets/sprites/player.png", (96, 128), {"idle": [0, 4, 4.0], "fall": [11, 1, 0], "attack": [14, 3, 18.0]}),
    "scav": ("assets/sprites/scav.png", (120, 112), {"idle": [0, 4, 4.0], "dead": [15, 1, 0]}),
}


def _font(size):
    try:
        return ImageFont.load_default(size=size)
    except TypeError:
        return ImageFont.load_default()


class Sheet:
    def __init__(self, rel, frame, clips):
        img = Image.open(os.path.join(GAME, rel)).convert("RGBA")
        self.img = img.resize((img.width // 2, img.height // 2), Image.NEAREST)
        self.fw, self.fh = frame[0] // 2, frame[1] // 2
        self.clips = clips

    def frame(self, clip, t_ms):
        first, count, fps = self.clips[clip]
        idx = 0 if fps <= 0 or count <= 1 else min(count - 1, int(t_ms / (1000.0 / fps)))
        if clip == "idle":
            idx = int(t_ms / 250.0) % count
        i = first + idx
        return self.img.crop((i * self.fw, 0, (i + 1) * self.fw, self.fh)), idx


SH = {k: Sheet(*v) for k, v in SHEETS.items()}


def actor(canvas, who, clip, t_ms, feet, flip=False, modulate=None):
    """Paste an actor's frame at t with its feet at `feet` (art px)."""
    frame, idx = SH[who].frame(clip, t_ms)
    if flip:
        frame = frame.transpose(Image.FLIP_LEFT_RIGHT)
    if modulate:
        r, g, b, a = modulate
        px = frame.load()
        for y in range(frame.height):
            for x in range(frame.width):
                pr, pg, pb, pa = px[x, y]
                px[x, y] = (int(pr * r), int(pg * g), int(pb * b), int(pa * a))
    canvas.alpha_composite(frame, (feet[0] - SH[who].fw // 2, feet[1] - SH[who].fh))
    return f"{clip}[{idx}]"


# What is on screen when each effect fires, in art px; feet on the floor line.
def scene_spark(canvas, t_ms, feet_x, floor_y, effect_frame=None, anchor=None):
    a = actor(canvas, "dani", "attack", t_ms, (feet_x, floor_y))
    b = actor(canvas, "scav", "idle", t_ms, (feet_x + 30, floor_y), flip=True)
    if effect_frame is not None:
        canvas.alpha_composite(effect_frame, (feet_x + 30 - anchor[0], floor_y - 20 - anchor[1]))
    return f"dani {a}, scav {b}"


def scene_dust(canvas, t_ms, feet_x, floor_y, effect_frame=None, anchor=None):
    a = actor(canvas, "dani", "idle", t_ms, (feet_x, floor_y))
    if effect_frame is not None:
        canvas.alpha_composite(effect_frame, (feet_x - anchor[0], floor_y - anchor[1]))
    return f"dani {a} (was fall)"


def scene_burst(canvas, t_ms, feet_x, floor_y, effect_frame=None, anchor=None):
    a = actor(canvas, "dani", "attack", t_ms, (feet_x - 32, floor_y))
    b = actor(canvas, "scav", "dead", t_ms, (feet_x, floor_y), flip=True, modulate=(0.6, 0.6, 0.6, 0.55))
    if effect_frame is not None:
        canvas.alpha_composite(effect_frame, (feet_x - anchor[0], floor_y - 20 - anchor[1]))
    return f"scav {b} greyed, dani {a}"


SCENES = {"spark.hit": scene_spark, "dust.land": scene_dust, "burst.die": scene_burst}


def load_bake(tag, name):
    img = Image.open(os.path.join(HERE, "out", tag, name + ".png")).convert("RGBA")
    meta = json.load(open(os.path.join(HERE, "out", tag, name + ".json")))
    return img, meta


def effect_frame(img, meta, k):
    fw, fh = meta["frame"]
    return img.crop((k * fw, 0, (k + 1) * fw, fh))


CELL = {"spark.hit": (80, 72, 32), "dust.land": (80, 72, 40), "burst.die": (104, 76, 60)}  # w, h, feet x


def cell(draw_scene, t_ms, frame, anchor, zoom, ground, floor_col, size=(80, 72), floor_y=60, feet_x=40):
    canvas = Image.new("RGBA", size, ground)
    d = ImageDraw.Draw(canvas)
    d.rectangle((0, floor_y, size[0], size[1]), fill=floor_col)
    label = draw_scene(canvas, t_ms, feet_x, floor_y, frame, anchor)
    return canvas.resize((size[0] * zoom, size[1] * zoom), Image.NEAREST), label


def strip(name, zoom=4):
    bakes = [(tag, *load_bake(tag, name)) for tag in TAGS]
    meta = bakes[0][2]
    n = len(meta["frames"])
    fps = meta["fps"]
    cw_art, ch_art, feet_x = CELL[name]
    cw, ch = cw_art * zoom, ch_art * zoom
    gap, label_w, header = 8, 170, 56
    W = label_w + (n + 1) * (cw + gap) + gap
    H = header + len(bakes) * (ch + gap) + gap
    out = Image.new("RGBA", (W, H), (30, 32, 40, 255))
    d = ImageDraw.Draw(out)
    font, small = _font(15), _font(12)
    d.text((8, 6), f"{name}  {n} frames at {fps} fps ({1000 * n / fps:.0f} ms); f0 held +33 ms by hitstop", fill=(220, 220, 230, 255), font=font)
    for c in range(n + 1):
        x = label_w + c * (cw + gap)
        t = 0 if c == 0 else (c - 1) * 1000.0 / fps
        d.text((x + 4, 26), "trigger frame, no effect" if c == 0 else f"f{c - 1}  t={t:.0f} ms", fill=(220, 220, 230, 255), font=small)
    for r, (tag, img, m) in enumerate(bakes):
        y = header + r * (ch + gap)
        d.text((8, y + 6), tag, fill=(255, 220, 80, 255), font=font)
        d.text((8, y + 28), f"{m['colours_sheet']} colours / sheet", fill=(200, 200, 210, 255), font=small)
        fr = m["frames"]
        d.text((8, y + 44), f"f0: {fr[0]['colours']} colours, {fr[0]['opaque']} px", fill=(200, 200, 210, 255), font=small)
        d.text((8, y + 60), f"rim dark {fr[0]['rim_dark']:.2f} light {fr[0]['rim_light']:.2f}", fill=(200, 200, 210, 255), font=small)
        d.text((8, y + 76), f"px/frame {[s['opaque'] for s in fr]}", fill=(160, 160, 170, 255), font=_font(10))
        for c in range(n + 1):
            x = label_w + c * (cw + gap)
            t = 0 if c == 0 else (c - 1) * 1000.0 / fps
            frame = None if c == 0 else effect_frame(img, m, c - 1)
            im, label = cell(SCENES[name], t, frame, m["anchor"], zoom, AB_GROUND, AB_FLOOR, (cw_art, ch_art), ch_art - 12, feet_x)
            out.alpha_composite(im, (x, y))
            if r == 0:
                d.text((x + 4, 40), label, fill=(160, 160, 170, 255), font=_font(10))
    path = os.path.join(HERE, "out", f"strip_{name}.png")
    out.save(path)
    print("wrote", path)


def lineup():
    """Impact frames beside the figures on the game's dark ground, 1x and 3x."""
    picks = [("spark.hit", 0), ("dust.land", 0), ("burst.die", 1)]
    size = (232, 72)
    rows = []
    for tag in TAGS:
        canvas = Image.new("RGBA", size, DARK)
        d = ImageDraw.Draw(canvas)
        d.rectangle((0, 60, size[0], size[1]), fill=DARK_FLOOR)
        x = 40
        for name, k in picks:
            img, m = load_bake(tag, name)
            fr = effect_frame(img, m, k)
            t = k * 1000.0 / m["fps"]
            SCENES[name](canvas, t, x, 60, fr, m["anchor"])
            x += 80 if name != "burst.die" else 60
        rows.append((tag, canvas))
    font = _font(14)
    for zoom, suffix in ((1, "1x"), (3, "3x")):
        gap, label_w = 6, 60
        W = label_w + size[0] * zoom + gap
        H = gap + len(rows) * (size[1] * zoom + gap)
        out = Image.new("RGBA", (W, H), (30, 32, 40, 255))
        d = ImageDraw.Draw(out)
        for r, (tag, canvas) in enumerate(rows):
            y = gap + r * (size[1] * zoom + gap)
            d.text((6, y + 4), tag, fill=(255, 220, 80, 255), font=font)
            out.alpha_composite(canvas.resize((size[0] * zoom, size[1] * zoom), Image.NEAREST), (label_w, y))
        path = os.path.join(HERE, "out", f"lineup_{suffix}.png")
        out.save(path)
        print("wrote", path)


def measure():
    table = {}
    for name in SCENES:
        for tag in TAGS:
            _, m = load_bake(tag, name)
            table.setdefault(name, {})[tag] = {"colours_sheet": m["colours_sheet"], "frames": m["frames"]}
    json.dump(table, open(os.path.join(HERE, "out", "measure.json"), "w"), indent=1)


if __name__ == "__main__":
    for name in SCENES:
        strip(name)
    lineup()
    measure()
