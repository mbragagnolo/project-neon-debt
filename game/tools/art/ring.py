"""Wall ring: the textured band a solid wears around air, authored as pixel
art at 2x (docs/art/environment.md, "Direction change"). Past the ring a
wall is void.

    python tools/art/ring.py residential                 # the set's method -> assets/tiles/wall_<style>.png
    python tools/art/ring.py residential --method proc   # one method, to work/rings/ only
    python tools/art/ring.py residential --all           # every method, work/rings/compare_<name>.png
    python tools/art/ring.py residential --set ring.face=16 --set ring.tiles=2

Reads the `ring` block of `tools/art/sets/<name>.json`. Three methods:
`proc` draws the whole ring from rules (one ramp, noise inside it, seams,
streaks, a lit lip, a dithered fade to void); `hand` reads typed ASCII
pieces from `sets/<name>_ring.py`; `mix` is the procedural surface with the
hand-drawn stamps from the same module placed on it by data.

The nine-patch is (C + L + C) square: corners C = tiles x 30 art px, edge
strips L long, the centre void. The preview draws Unit 14-C's corner the way
the room generator does (greedy rectangles, one NinePatchRect each, tile
mode) with the per-side margins and region_rect that `make_stacks._solid`
is to take from the spec's air-neighbour checks, and Dani's idle frame for
scale. Judge the preview at 1:1.
"""
import argparse
import importlib
import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pixel import PALETTE, save as save_scaled  # noqa: E402

SETS = os.path.join(HERE, "sets")
WORK = os.path.join(HERE, "work", "rings")
ASSETS = os.path.join(os.path.dirname(os.path.dirname(HERE)), "assets")
STACKS = os.path.join(os.path.dirname(HERE), "stacks")
TILE = 30  # art px per 60 px engine tile at 2x
SCALE = 2
INF = 10 ** 6


def load_set(name):
    return json.load(open(os.path.join(SETS, f"{name}.json"), encoding="utf-8"))


def rgb(key):
    return np.array(PALETTE[key], dtype=np.uint8)


# --- Noise ---------------------------------------------------------------------------

def value_noise(size, cell, rng):
    """Tileable value noise on a size x size field: a lattice every `cell`
    px (cell divides size), bilinear with a smoothstep, wrapping both ways."""
    n = size // cell
    assert n * cell == size, f"cell {cell} does not divide {size}"
    lat = rng.random((n, n))
    t = np.arange(size) / cell
    i0 = np.floor(t).astype(int) % n
    i1 = (i0 + 1) % n
    f = t - np.floor(t)
    f = f * f * (3 - 2 * f)
    a = lat[i0[:, None], i0[None, :]]
    b = lat[i0[:, None], i1[None, :]]
    c = lat[i1[:, None], i0[None, :]]
    d = lat[i1[:, None], i1[None, :]]
    fx, fy = f[None, :], f[:, None]
    return (a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + d * fx) * fy


def mottle(size, cfg, rng):
    """Octaves summed, plus one-pixel grain, stretched to 0..1 by percentile
    so the step thresholds mean the same whatever the octaves."""
    out = np.zeros((size, size))
    for cell, w in zip(cfg["cells"], cfg["weights"]):
        out += w * value_noise(size, cell, rng)
    out += cfg.get("grain", 0.08) * rng.random((size, size))
    lo, hi = np.percentile(out, [1, 99])
    return np.clip((out - lo) / max(hi - lo, 1e-6), 0, 1)


# --- The procedural ring ---------------------------------------------------------------

def geometry(ring):
    C = int(ring.get("tiles", 1)) * TILE
    L = int(ring.get("strip", 6)) * TILE
    return C, L, C + L + C


def sides(W, C, L):
    """Which texture sides each pixel's region touches air on, and the
    depth: the distance to the nearest of them (INF in the centre)."""
    xs = np.arange(W)[None, :].repeat(W, 0)
    ys = np.arange(W)[:, None].repeat(W, 1)
    top, bottom = ys < C, ys >= C + L
    left, right = xs < C, xs >= C + L
    d = np.full((W, W), INF)
    d = np.where(top, np.minimum(d, ys), d)
    d = np.where(bottom, np.minimum(d, W - 1 - ys), d)
    d = np.where(left, np.minimum(d, xs), d)
    d = np.where(right, np.minimum(d, W - 1 - xs), d)
    return d, top, bottom, left, right, xs, ys


def proc_steps(ring, rng, W, C, L):
    """The ring as ramp step indices (0 = void ... len(ramp) - 1), before
    the stamps and the colour lookup."""
    ramp = ring["ramp"]
    base = ramp.index(ring.get("base", "concrete1"))
    n_face = ring.get("face", 20)
    n_fade = ring.get("fade", 8)
    d, top, bottom, left, right, xs, ys = sides(W, C, L)
    # the surface: noise sampled with the strip's period so corners continue the strips
    field = mottle(L, ring["noise"], rng)
    u, v = (xs - C) % L, (ys - C) % L
    m = field[v, u]
    jit = mottle(L, ring.get("dither", {"cells": [6], "weights": [0.5], "grain": 0.5}), rng)[v, u]
    th = ring["steps"]
    step = np.full((W, W), base)
    step[m < th["dark"]] = base - 1
    step[m > th["light"]] = base + 1
    # the ceiling underside sits one step lower on average: more shadow, no lit fleck
    under = bottom & ~(left | right)
    u_dark, u_light = th.get("under_dark", 0.5), th.get("under_light", 0.95)
    step[under] = base
    step[under & (m < u_dark)] = base - 1
    step[under & (m > u_light)] = base + 1
    # the lit floor lip, the dark underside edge, the lit and the shaded side
    lip = ring["lip"]
    chip = m < lip.get("chip", 0.1)
    step[top & (ys == 0)] = ramp.index(lip["top"][0])
    step[top & (ys == 0) & chip] = ramp.index(lip["top"][1])
    step[top & (ys == 1)] = ramp.index(lip["top"][1])
    step[top & (ys == 1) & chip] = base
    if lip.get("crease"):
        crease_row = lip.get("crease_row", 3)
        step[top & (ys == crease_row) & (m < lip.get("crease_cover", 0.6))] = ramp.index(lip["crease"])
    edge = ring["edge"]
    under_i = ramp.index(edge["under"])
    step[bottom & (ys == W - 1)] = under_i
    step[bottom & (ys == W - 1) & (m < 0.2)] = max(under_i - 1, 0)
    step[bottom & (ys == W - 2) & (m < 0.45)] = under_i
    step[left & (xs == 0)] = ramp.index(edge["lit_side"])
    step[left & (xs == 0) & chip] = base
    step[right & (xs == W - 1)] = ramp.index(edge["shade_side"])
    # seams across the strips, from the air edge into the face
    seams = ring.get("seams")
    if seams:
        every, jitter = seams["every"], seams.get("jitter", 0)
        inside = (d >= 2) & (d < n_face + 2)
        for strip_axis in ("h", "v"):
            pos = 0
            while pos < L:
                p = C + int(pos + rng.integers(-jitter, jitter + 1)) % L
                if strip_axis == "h":
                    col = (xs == p) & (top | bottom) & ~(left | right)
                    lit = (xs == p + 1) & (top | bottom) & ~(left | right)
                else:
                    col = (ys == p) & (left | right) & ~(top | bottom)
                    lit = (ys == p + 1) & (left | right) & ~(top | bottom)
                step[col & inside] = base - 1
                step[lit & inside & (m > seams.get("lit_cover", 0.55))] = base + 1
                pos += every
    # streaks: stains running down the wall faces and off the ceiling edge
    streaks = ring.get("streaks")
    if streaks:
        lo, hi = streaks["length"]
        count = int(streaks["per_tile"] * L / TILE)
        for _ in range(count):
            p = C + int(rng.integers(0, L))
            length = int(rng.integers(lo, hi + 1))
            y0 = W - 2 - int(rng.integers(0, 3))
            for y in range(max(y0 - length, W - C + 2), y0 + 1):
                step[y, p] = base - 1
            x_in = 2 + int(rng.integers(0, max(1, n_face - 6)))
            for y in range(p, min(p + length, C + L)):
                step[y, x_in] = base - 1
                step[y, W - 1 - x_in] = base - 1
    # scuffs on the floor lip's face
    scuffs = ring.get("scuffs")
    if scuffs:
        for _ in range(int(scuffs["per_tile"] * L / TILE)):
            p = C + int(rng.integers(0, L))
            y = 4 + int(rng.integers(0, scuffs.get("depth", 6)))
            for x in range(p, min(p + int(rng.integers(2, 5)), C + L)):
                step[y, x] = base + 1
    # the fade: past the face the steps fall to void, dithered by the noise
    k = np.clip((d - n_face) / max(n_fade, 1), 0.0, 1.0)
    shift = np.floor(k * (base + 0.001) + jit * 0.999).astype(int)
    shift[d < n_face] = 0
    step = np.maximum(step - shift, 0)
    step[d >= n_face + n_fade] = 0
    return step, m, d


def specks(colours, ring, rng, d, W):
    """Rust pits in the face: single pixels, sometimes a pair."""
    cfg = ring.get("specks")
    if not cfg:
        return colours
    face = (d >= 3) & (d < ring.get("face", 20) - 2)
    pick = (rng.random((W, W)) < cfg["rate"]) & face
    ys, xs = np.nonzero(pick)
    for y, x in zip(ys, xs):
        colours[y, x] = rgb(cfg["colour"])
        if rng.random() < 0.4 and x + 1 < W and face[y, x + 1]:
            colours[y, x + 1] = rgb(cfg.get("colour2", cfg["colour"]))
    return colours


def colourise(step, ramp):
    lut = np.array([PALETTE[k] for k in ramp], dtype=np.uint8)
    return lut[np.clip(step, 0, len(ramp) - 1)]


def hand_module(name, ring):
    return importlib.import_module(f"sets.{ring.get('hand', name + '_ring')}")


def ascii_image(rows, legend):
    """Typed rows -> RGBA array. '.' is transparent (stamps); the ring pieces
    use no transparency."""
    h, w = len(rows), max(len(r) for r in rows)
    out = np.zeros((h, w, 4), dtype=np.uint8)
    for y, row in enumerate(rows):
        assert len(row) == w, f"row {y} is {len(row)} wide, expected {w}"
        for x, c in enumerate(row):
            if c == ".":
                continue
            out[y, x, :3] = PALETTE[legend[c]]
            out[y, x, 3] = 255
    return out


def place_stamps(colours, ring, mod, rng, C, L, W):
    """Hand-drawn motifs on the procedural surface. Each entry: which strip
    (`t`, `b`, `l`, `r`), the depth from the air edge, and either fixed
    positions along the strip or an `every` spacing with jitter. Stamps are
    typed in their own side's orientation; `turn: true` takes one typed for
    a floor and turns it for another side."""
    for entry in ring.get("stamps", []):
        art = ascii_image(mod.STAMPS[entry["name"]], mod.LEGEND)
        side = entry["side"]
        if entry.get("turn", False):
            if side == "b":
                art = art[::-1]
            elif side == "l":
                art = np.rot90(art, 1)
            elif side == "r":
                art = np.rot90(art, -1)
        h, w = art.shape[:2]
        if "at" in entry:
            positions = list(entry["at"])
        else:
            every, jitter = entry["every"], entry.get("jitter", 0)
            positions = [int(p + rng.integers(-jitter, jitter + 1)) % L for p in range(entry.get("offset", 0), L, every)]
        for p in positions:
            depth = entry.get("depth", 0)
            if side == "t":
                x0, y0 = C + p, depth
            elif side == "b":
                x0, y0 = C + p, W - depth - h
            elif side == "l":
                x0, y0 = depth, C + p
            else:
                x0, y0 = W - depth - w, C + p
            for yy in range(h):
                for xx in range(w):
                    if art[yy, xx, 3] == 0:
                        continue
                    x, y = x0 + xx, y0 + yy
                    if side in ("t", "b"):
                        x = C + (x - C) % L
                    else:
                        y = C + (y - C) % L
                    if 0 <= x < W and 0 <= y < W:
                        colours[y, x] = art[yy, xx, :3]
    return colours


def boards(colours, cfg, rng, top, xs, ys, C, L, W):
    """Floorboards along the top strip: a band `depth` deep with a lit edge,
    grain runs, staggered board ends and a shadow line under it."""
    b = cfg.get("boards")
    if not b:
        return colours
    depth = int(b["depth"])
    base, grain, lit, gap, shadow = (rgb(b[k]) for k in ("base", "grain", "lit", "gap", "shadow"))
    band = top & (ys < depth)
    colours[band] = base
    colours[top & (ys == 0)] = lit
    colours[top & (ys == depth - 1)] = shadow
    chip = rng.random(W) < b.get("chip", 0.08)
    colours[(ys == 0) & top & chip[None, :].repeat(W, 0)] = base
    lo, hi = b["length"]
    # board ends: 1 px gaps at staggered positions, periodic along the strip
    x = int(rng.integers(0, hi))
    while x < L:
        for y in range(1, depth - 1):
            colours[y, C + x] = gap
        x += int(rng.integers(lo, hi + 1))
    for _ in range(int(b.get("grain_per_tile", 3) * L / TILE)):
        y = 2 + int(rng.integers(0, max(1, depth - 3)))
        x0 = int(rng.integers(0, L))
        for x in range(x0, x0 + int(rng.integers(3, 10))):
            xx = C + x % L
            if tuple(colours[y, xx]) == tuple(base):
                colours[y, xx] = grain
    # the corners carry the band too, continued from the strip's ends
    for y in range(depth):
        colours[y, :C] = colours[y, L:L + C]
        colours[y, C + L:] = colours[y, C:2 * C]
    return colours


def slats(colours, cfg, rng, m, bottom, xs, ys, C, L, W):
    """Under the ceiling: a beam line at the edge and slat lines above it,
    broken by the noise so they read as rafters, not rules."""
    sl = cfg.get("slats")
    if not sl:
        return colours
    beam, line = rgb(sl["beam"]), rgb(sl["line"])
    for i in range(int(sl.get("beam_depth", 2))):
        colours[bottom & (ys == W - 1 - i)] = beam
    for i in range(int(sl.get("count", 3))):
        y = W - 1 - int(sl.get("beam_depth", 2)) - 1 - i * int(sl.get("every", 2))
        colours[bottom & (ys == y) & (m > sl.get("cover", 0.35))] = line
    return colours


def material_cfg(ring, side):
    """The ring block with one side's overrides on top: a floor can be
    boards while the walls are plaster."""
    cfg = dict(ring)
    cfg.update(ring.get("materials", {}).get(side, {}))
    return cfg


def build_proc(name, ring, with_stamps):
    C, L, W = geometry(ring)
    d, top, bottom, left, right, xs, ys = sides(W, C, L)
    # which side's material a pixel wears: a horizontal side owns its band
    # outright (the boards reach the corner), the rest goes to the nearest side
    dists = [ys, W - 1 - ys, xs, W - 1 - xs]
    masks = [top, bottom, left, right]
    owner = np.full((W, W), -1)
    best = np.full((W, W), INF)
    for i, (mask, dd) in enumerate(zip(masks, dists)):
        better = mask & (dd < best)
        owner[better] = i
        best[better] = dd[better]
    for i, side in ((0, "t"), (1, "b")):
        band = material_cfg(ring, side).get("band", 0)
        if band:
            forced = masks[i] & (dists[i] < band)
            owner[forced] = i
    seed = int(ring.get("seed", 1))
    colours = np.zeros((W, W, 3), dtype=np.uint8)
    for i, side in enumerate("tblr"):
        mine = owner == i
        if not mine.any():
            continue
        cfg = material_cfg(ring, side)
        rng = np.random.default_rng(seed)
        step, m, dd = proc_steps(cfg, rng, W, C, L)
        col = colourise(step, cfg["ramp"])
        col = specks(col, cfg, rng, dd, W)
        if side == "t":
            col = boards(col, cfg, rng, top, xs, ys, C, L, W)
        if side == "b":
            col = slats(col, cfg, rng, m, bottom, xs, ys, C, L, W)
        colours[mine] = col[mine]
    if with_stamps:
        rng = np.random.default_rng(seed + 1)
        colours = place_stamps(colours, ring, hand_module(name, ring), rng, C, L, W)
    return Image.fromarray(colours, "RGB").convert("RGBA"), C


def build_hand(name, ring):
    """Typed pieces: T, B, L (R mirrored), TL, BL (TR, BR mirrored). The
    centre is void. Strip length is whatever was typed."""
    mod = hand_module(name, ring)
    P = {k: ascii_image(v, mod.LEGEND) for k, v in mod.PIECES.items()}
    if "R" not in P:
        P["R"] = P["L"][:, ::-1]
    if "TR" not in P:
        P["TR"] = P["TL"][:, ::-1]
    if "BR" not in P:
        P["BR"] = P["BL"][:, ::-1]
    C = P["TL"].shape[0]
    L = P["T"].shape[1]
    assert P["L"].shape[0] == L, "the side strip must be as long as the top strip"
    W = C + L + C
    out = np.zeros((W, W, 4), dtype=np.uint8)
    out[..., :3] = PALETTE["void"]
    out[..., 3] = 255
    at = {"TL": (0, 0), "T": (0, C), "TR": (0, C + L), "L": (C, 0), "R": (C, W - C),
          "BL": (W - C, 0), "B": (W - C, C), "BR": (W - C, W - C)}
    for k, (y, x) in at.items():
        h, w = P[k].shape[:2]
        out[y:y + h, x:x + w] = P[k]
    return Image.fromarray(out, "RGBA"), C


def build(name, spec, method):
    ring = spec["ring"]
    if method == "hand":
        return build_hand(name, ring)
    return build_proc(name, ring, with_stamps=(method == "mix"))


# --- The engine, emulated ------------------------------------------------------------

def load_room(room_id):
    grid, in_grid = [], False
    for raw in open(os.path.join(STACKS, f"{room_id}.room"), encoding="utf-8"):
        line = raw.rstrip("\r\n")
        if in_grid:
            if line.strip():
                grid.append(line)
        elif line.strip() == "grid":
            in_grid = True
    return grid


def tile_at(grid, x, y):
    if y < 0 or y >= len(grid) or x < 0 or x >= len(grid[y]):
        return "#"
    return grid[y][x]


def is_air(grid, x, y):
    return tile_at(grid, x, y) not in "#=v~"


def rects_of(grid, c):
    """`RoomSpec.rects_of`, ported: horizontal runs merged downward."""
    taken, out = set(), []
    for y in range(len(grid)):
        x = 0
        while x < len(grid[y]):
            if grid[y][x] != c or (x, y) in taken:
                x += 1
                continue
            run = 0
            while x + run < len(grid[y]) and grid[y][x + run] == c and (x + run, y) not in taken:
                run += 1
            rows = 1
            while y + rows < len(grid):
                if any(tile_at(grid, x + dx, y + rows) != c or (x + dx, y + rows) in taken for dx in range(run)):
                    break
                rows += 1
            for dy in range(rows):
                for dx in range(run):
                    taken.add((x + dx, y + dy))
            out.append((x, y, run, rows))
            x += run
    return out


def air_sides(grid, rect):
    """Which sides of a solid rectangle touch air: the check _solid is to make."""
    x, y, w, h = rect
    return {
        "l": any(is_air(grid, x - 1, yy) for yy in range(y, y + h)),
        "r": any(is_air(grid, x + w, yy) for yy in range(y, y + h)),
        "t": any(is_air(grid, xx, y - 1) for xx in range(x, x + w)),
        "b": any(is_air(grid, xx, y + h) for xx in range(x, x + w)),
    }


def map_axis(px, draw, tex, m0, m1):
    """Godot's map_ninepatch_axis, tile mode: the first margin wins, then the
    last, the middle repeats the centre."""
    if px < m0:
        return px
    if px >= draw - m1:
        return tex - (draw - px)
    mid = tex - m0 - m1
    if mid <= 0:
        return min(tex - 1, px)
    return m0 + (px - m0) % mid


def draw_solid(canvas, tex, rect_px, margins, region):
    """One NinePatchRect, at art px: `margins` (l, t, r, b), `region` the
    texture sub-rect (x0, y0, x1, y1) it reads."""
    x, y, w, h = rect_px
    ml, mt, mr, mb = margins
    sub = tex[region[1]:region[3], region[0]:region[2]]
    th, tw = sub.shape[:2]
    us = np.clip(np.array([map_axis(i, w, tw, ml, mr) for i in range(w)]), 0, tw - 1)
    vs = np.clip(np.array([map_axis(j, h, th, mt, mb) for j in range(h)]), 0, th - 1)
    canvas[y:y + h, x:x + w] = sub[vs[:, None], us[None, :]]


def render_room(tex_img, C, room_id, crop_tiles, fixed=True):
    """The room's solids as the generator draws them, at art px, air left
    transparent. `fixed` applies the per-side margin + region rule; without
    it every side gets the ring, as _solid does today."""
    grid = load_room(room_id)
    tex = np.array(tex_img.convert("RGBA"))
    W = tex.shape[0]
    cx, cy, cw, ch = crop_tiles
    full = np.zeros((len(grid) * TILE, len(grid[0]) * TILE, 4), dtype=np.uint8)
    for rect in rects_of(grid, "#"):
        x, y, w, h = rect
        air = air_sides(grid, rect) if fixed else {"l": True, "r": True, "t": True, "b": True}
        ml, mr = (C if air["l"] else 0), (C if air["r"] else 0)
        mt, mb = (C if air["t"] else 0), (C if air["b"] else 0)
        wp, hp = w * TILE, h * TILE
        if ml and mr and ml + mr > wp:
            ml, mr = wp // 2, wp - wp // 2
        if mt and mb and mt + mb > hp:
            mt, mb = hp // 2, hp - hp // 2
        region = (0 if air["l"] else C, 0 if air["t"] else C, W if air["r"] else W - C, W if air["b"] else W - C)
        draw_solid(full, tex, (x * TILE, y * TILE, wp, hp), (ml, mt, mr, mb), region)
    canvas = full[cy * TILE:(cy + ch) * TILE, cx * TILE:(cx + cw) * TILE]
    return Image.fromarray(np.ascontiguousarray(canvas), "RGBA")


def preview(tex_img, C, label, room_id="unit_14c", crop=(0, 4, 16, 14), player=(3, 15), fixed=True):
    """The 14-C corner at screen pixels: the backdrop the room has today,
    the solids, Dani on the P tile."""
    cx, cy, cw, ch = crop
    art = render_room(tex_img, C, room_id, crop, fixed)
    screen = art.resize((art.width * SCALE, art.height * SCALE), Image.NEAREST)
    page = Image.new("RGBA", screen.size, PALETTE["bg1"] + (255,))
    back_path = os.path.join(ASSETS, "tiles", "back_residential.png")
    if os.path.exists(back_path):
        back = Image.open(back_path).convert("RGBA")
        ox, oy = (cx * TILE * SCALE) % back.width, (cy * TILE * SCALE) % back.height
        for y in range(-oy, page.height, back.height):
            for x in range(-ox, page.width, back.width):
                page.paste(back, (x, y))
    page.alpha_composite(screen)
    sheet_path = os.path.join(ASSETS, "sprites", "player.png")
    if os.path.exists(sheet_path):
        frame = Image.open(sheet_path).convert("RGBA").crop((0, 0, 96, 128))
        fx = int((player[0] + 0.5 - cx) * TILE * SCALE) - frame.width // 2
        fy = int((player[1] - cy) * TILE * SCALE) - frame.height
        page.alpha_composite(frame, (fx, fy))
    ImageDraw.Draw(page).text((8, 6), label, fill=(255, 220, 80))
    return page


def strip_view(tex_img, C, label):
    """The nine-patch at 1:1 screen pixels."""
    big = tex_img.resize((tex_img.width * SCALE, tex_img.height * SCALE), Image.NEAREST)
    page = Image.new("RGBA", (big.width, big.height + 18), (10, 12, 18, 255))
    page.paste(big, (0, 18))
    ImageDraw.Draw(page).text((4, 3), label, fill=(255, 220, 80))
    return page


def colour_count(img):
    arr = np.array(img.convert("RGB")).reshape(-1, 3)
    return len(np.unique(arr, axis=0))


# --- Commands ---------------------------------------------------------------------------

def run(name, spec, method, work_only, tag="", fixed=True):
    os.makedirs(WORK, exist_ok=True)
    open(os.path.join(HERE, "work", ".gdignore"), "a").close()
    tex, C = build(name, spec, method)
    suffix = f"_{tag}" if tag else ""
    tex.save(os.path.join(WORK, f"{name}_{method}{suffix}.png"))
    strip_tiles = (tex.width - 2 * C) // TILE
    label = f"{name} / {method}{suffix}   ring {C // TILE} tile, strip {strip_tiles} tiles, {colour_count(tex)} colours"
    if not fixed:
        label += "   -- drawn by today's _solid: every side gets the ring"
    page = preview(tex, C, label, fixed=fixed)
    page_path = os.path.join(WORK, f"preview_{name}_{method}{suffix}.png")
    page.save(page_path)
    strip_view(tex, C, f"{name} / {method}: the nine-patch at 1:1").save(os.path.join(WORK, f"patch_{name}_{method}{suffix}.png"))
    print(f"{method}: {tex.width}x{tex.height} art px, ring {C} px, {colour_count(tex)} colours -> {page_path}")
    if not work_only:
        path = save_scaled(tex, spec["sheet"], scale=SCALE)
        json.dump({"margin": C * SCALE}, open(os.path.splitext(path)[0] + ".json", "w"), indent=2)
        print("sheet:", path, f"{tex.width * SCALE}x{tex.height * SCALE}, margin {C * SCALE}")
    return page


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("name")
    ap.add_argument("--method", choices=["proc", "hand", "mix"], default=None)
    ap.add_argument("--all", action="store_true", help="every method, previews stacked in work/rings/compare_<name>.png")
    ap.add_argument("--tag", default="")
    ap.add_argument("--set", action="append", help="override a ring key for this run, e.g. --set ring.face=16")
    ap.add_argument("--work-only", action="store_true")
    args = ap.parse_args()
    spec = load_set(args.name)
    for kv in args.set or []:
        k, v = kv.split("=", 1)
        cur = spec
        keys = k.split(".")
        for kk in keys[:-1]:
            cur = cur.setdefault(kk, {})
        cur[keys[-1]] = json.loads(v)
    if args.all:
        pages = [run(args.name, spec, m, True, args.tag) for m in ("proc", "hand", "mix")]
        # two more rows: the set's method through today's _solid, and a two-tile ring
        chosen = spec["ring"].get("method", "mix")
        pages.append(run(args.name, spec, chosen, True, (args.tag + "_" if args.tag else "") + "nofix", fixed=False))
        deep = json.loads(json.dumps(spec))
        deep["ring"].update({"tiles": 2, "face": deep["ring"].get("face", 20) + TILE, "fade": deep["ring"].get("fade", 8) + 4})
        pages.append(run(args.name, deep, chosen, True, (args.tag + "_" if args.tag else "") + "ring2"))
        w, h = pages[0].width, sum(p.height for p in pages) + 8 * (len(pages) - 1)
        page = Image.new("RGBA", (w, h), (10, 12, 18, 255))
        y = 0
        for p in pages:
            page.paste(p, (0, y))
            y += p.height + 8
        path = os.path.join(WORK, f"compare_{args.name}{'_' + args.tag if args.tag else ''}.png")
        page.save(path)
        print("compare:", path)
        return
    method = args.method or spec["ring"].get("method", "mix")
    run(args.name, spec, method, args.work_only or args.method is not None, args.tag)


if __name__ == "__main__":
    main()
