"""Bake the effects in effects/*.json through three authoring paths.

    python bake.py            # all three paths, out/<tag>/<name>.png + .json
    python bake.py --emit hot # also out/sheets/<name>.png at 2x with clips

Paths (tags):
  direct   drawn at 1x, tones rounded to ramp steps, no edge rule: what an
           ASCII grid or a pixel brush gives (make_fx.py's kind of authoring)
  bake     drawn at 8x with continuous tones, then the character bake as is:
           k-centroid (k 2, accent vote), edge shade 0.62 with the lit rim
           1.3 from the upper left, palette snap to the effect's ramps
  hot      the same, but the edge rule is per family: the hot family (an
           emitter) gets no edge step; dust (a lit solid) gets the character
           rule. Families are baked as layers and composited, dust under hot.

The bake functions are rig.py's own, imported from the kiln skill.
"""
import argparse
import glob
import json
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
GAME_ART = os.path.normpath(os.path.join(HERE, "..", "..", "game", "tools", "art"))
KILN_CD = r"F:\Projects\Coding Projects\kiln\skills\character-designer\scripts"
sys.path.insert(0, HERE)
sys.path.insert(0, GAME_ART)
sys.path.insert(0, KILN_CD)
import shapes  # noqa: E402
from pixel import PALETTE  # noqa: E402
import rig  # noqa: E402
from pixelkit import upscale  # noqa: E402

BAKE_SCALE = 8
ACCENT = {"share": 0.25, "chroma": 120, "luma": 200}
EDGE = {"shade": 0.62, "lit": 1.3, "light": (-1, -1)}
TAGS = ("direct", "bake", "hot")


def _composite(layers):
    out = layers[0].copy()
    for layer in layers[1:]:
        out.alpha_composite(layer)
    return out


def bake_frame(effect, i, tag):
    fw, fh = effect["frame"]
    pal = shapes.palette_of(effect, PALETTE)
    if tag == "direct":
        return rig.snap_to_palette(shapes.render(effect, i, PALETTE, scale=1), pal)
    if tag == "bake":
        canvas = shapes.render(effect, i, PALETTE, scale=BAKE_SCALE)
        art = rig.k_centroid(canvas, (fw, fh), k=2, accent=ACCENT)
        art = rig.shade_edges(art, EDGE["shade"], EDGE["lit"], EDGE["light"])
        return rig.snap_to_palette(art, pal)
    if tag == "hot":
        layers = []
        for ramp_name in sorted(effect["ramps"], key=lambda r: 0 if r == "dust" else 1):
            canvas = shapes.render(effect, i, PALETTE, scale=BAKE_SCALE, only_ramp=ramp_name)
            art = rig.k_centroid(canvas, (fw, fh), k=2, accent=ACCENT)
            if ramp_name == "dust":
                art = rig.shade_edges(art, EDGE["shade"], EDGE["lit"], EDGE["light"])
            layers.append(rig.snap_to_palette(art, {n: PALETTE[n] for n in effect["ramps"][ramp_name]}))
        return _composite(layers)
    raise ValueError(tag)


LUMA = np.array([0.299, 0.587, 0.114], dtype=np.float32)


def measure(frame, allowed):
    """Colours, opaque pixels, off-palette pixels, and the edge rule: the share
    of silhouette pixels darker / lighter than their brightest / darkest
    opaque neighbour by a step (8 luma)."""
    arr = np.array(frame.convert("RGBA")).astype(np.float32)
    a = arr[..., 3] > 127
    n = int(a.sum())
    if n == 0:
        return {"colours": 0, "opaque": 0, "off_palette": 0, "rim_dark": 0.0, "rim_light": 0.0}
    rgb = arr[..., :3]
    cols = np.unique(rgb[a].astype(np.uint8), axis=0)
    allowed_set = {tuple(int(c) for c in v) for v in allowed.values()}
    off = sum(1 for c in cols if tuple(int(x) for x in c) not in allowed_set)
    luma = rgb @ LUMA
    pad_a = np.pad(a, 1)
    pad_l = np.pad(luma, 1)
    interior = a & pad_a[:-2, 1:-1] & pad_a[2:, 1:-1] & pad_a[1:-1, :-2] & pad_a[1:-1, 2:]
    edge = a & ~interior
    hi = np.full(luma.shape, -1.0, dtype=np.float32)
    lo = np.full(luma.shape, 1e9, dtype=np.float32)
    H, W = a.shape
    for dy in (-1, 0, 1):
        for dx in (-1, 0, 1):
            if dx == 0 and dy == 0:
                continue
            na = pad_a[1 + dy:1 + dy + H, 1 + dx:1 + dx + W]
            nl = pad_l[1 + dy:1 + dy + H, 1 + dx:1 + dx + W]
            hi = np.where(na, np.maximum(hi, nl), hi)
            lo = np.where(na, np.minimum(lo, nl), lo)
    has = edge & (hi >= 0)
    e = int(has.sum())
    rim_dark = float(((luma < hi - 8) & has).sum() / e) if e else 0.0
    rim_light = float(((luma > lo + 8) & has).sum() / e) if e else 0.0
    return {"colours": int(len(cols)), "opaque": n, "off_palette": int(off),
            "rim_dark": round(rim_dark, 2), "rim_light": round(rim_light, 2)}


def bake_effect(effect, tag):
    frames = [bake_frame(effect, i, tag) for i in range(len(effect["frames"]))]
    img = rig.sheet(frames)
    pal = shapes.palette_of(effect, PALETTE)
    stats = [measure(f, pal) for f in frames]
    meta = {"name": effect["name"], "tag": tag, "frame": effect["frame"], "anchor": effect["anchor"],
            "fps": effect["fps"], "clips": {"play": [0, len(frames), effect["fps"], False]},
            "colours_sheet": rig.colour_count(img), "frames": stats}
    out_dir = os.path.join(HERE, "out", tag)
    os.makedirs(out_dir, exist_ok=True)
    img.save(os.path.join(out_dir, effect["name"] + ".png"))
    json.dump(meta, open(os.path.join(out_dir, effect["name"] + ".json"), "w"), indent=1)
    return img, meta


def emit(effect, tag, scale=2):
    """The engine-facing sheet: 2x nearest, one row, with a clip table the
    same shape as rig.py's plus the anchor in art px."""
    img = Image.open(os.path.join(HERE, "out", tag, effect["name"] + ".png")).convert("RGBA")
    out_dir = os.path.join(HERE, "out", "sheets")
    os.makedirs(out_dir, exist_ok=True)
    path = os.path.join(out_dir, effect["name"] + ".png")
    upscale(img, scale).save(path)
    fw, fh = effect["frame"]
    clips = {"sheet": path, "frame_width": fw * scale, "frame_height": fh * scale, "scale": scale,
             "frames": len(effect["frames"]), "row_layout": "one row, left to right",
             "anchor": [effect["anchor"][0] * scale, effect["anchor"][1] * scale],
             "anchor_art_px": effect["anchor"], "fps": effect["fps"], "tag": tag,
             "clips": {"play": {"first": 0, "count": len(effect["frames"]), "fps": effect["fps"], "loop": False}}}
    json.dump(clips, open(os.path.join(out_dir, effect["name"] + ".clips.json"), "w"), indent=1)
    return path


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--tags", default=",".join(TAGS))
    ap.add_argument("--emit", default=None, help="write out/sheets/ at 2x from this tag")
    args = ap.parse_args()
    effects = [json.load(open(p)) for p in sorted(glob.glob(os.path.join(HERE, "effects", "*.json")))]
    for tag in args.tags.split(","):
        for effect in effects:
            img, meta = bake_effect(effect, tag)
            per = meta["frames"]
            print(f"{tag:>7} {effect['name']:>10}: {meta['colours_sheet']:2d} colours on the sheet; "
                  f"per frame colours {[s['colours'] for s in per]}, opaque {[s['opaque'] for s in per]}, "
                  f"off-palette {sum(s['off_palette'] for s in per)}, rim dark {per[0]['rim_dark']:.2f} light {per[0]['rim_light']:.2f} on f0")
    if args.emit:
        for effect in effects:
            print("sheet ->", emit(effect, args.emit))


if __name__ == "__main__":
    main()
