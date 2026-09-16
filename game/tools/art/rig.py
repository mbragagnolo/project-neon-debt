"""Cutout rig: cut a character's still into parts, pose them, bake sheets.

    python tools/art/rig.py dani joints   # draw the joints over the still, to check them
    python tools/art/rig.py dani cut      # still -> source/<name>/parts/*.png (+ a debug overlay)
    python tools/art/rig.py dani bake     # parts + poses -> assets/sprites/<sheet>.png

A/B of bake settings, without touching the game asset or the json:

    python tools/art/rig.py dani bake --tag base --work-only
    python tools/art/rig.py dani bake --tag lines --work-only --set target.lines={"coverage":0.3}
    python tools/art/rig.py dani ab base lines           # -> work/dani/ab.png + ab_run.gif

`--tag` keeps the 1x sheet in work/<name>/bakes/<tag>.png with its clip table
and the settings that made it; `--set a.b=<json>` overrides one key of the
spec for this run only. What wins goes into cast/<name>.json: a character's
look is data, the command line is for sweeps.

The rig is a tree of parts. Each part owns one pivot joint and is a child
of the part that carries that joint; a pose is a rotation per part (degrees,
clockwise on screen) plus an optional root offset. Forward kinematics runs
at the still's resolution, so limbs rotate smoothly, and every frame is then
downscaled once to art pixels and snapped to the palette. Frames are
consistent by construction: they are all the same parts (docs/art/cast.md,
"rig once, bake to sheets").

Cutting assigns every foreground pixel of the still to the nearest bone,
then pads each part a little and rounds its joints with discs so rotated
limbs show no gap. Occluded pixels under a joint are not inpainted; at the
target sizes the discs cover it.

`cast/<name>.json` holds the geometry (`rig` block); `cast/<name>_poses.py`
holds the clips. Poses are Python because cycles are arithmetic.

A part can come from its own still (`"still": "wrench"`, joints under
`rig.prop_joints.wrench`, image at `source/<name>/wrench.png`) and hang from
one of the character's joints (`"attach": "hand_near"`): that is how a weapon
enters the rig without being drawn in the character's hand. `"rest"` is a
per-part angle added to every pose, so a limb the still drew extended can be
posed as if it hung (the poses are written against a hanging arm).

A pose can also carry `tint` ({part: factor or [r, g, b]}) and `hide`
([parts]): a lens that brightens on aim, a lamp that lights in the windup, a
coat that comes off in phase two, without a second still.

    python tools/art/rig.py dani grid     # 50 px grid over the stills, to read joints off

A part can be an `overlay`: it is cut by its bone like any other but its
pixels are also left to the part beneath, so a folded forearm can swing out
to point without opening a hole in the cardigan (Marisol).

A part can be `cut_as` another part: it takes that part's pixels and carries
its own recolour, which is how a limb exists twice on one rig (the Landlord's
sleeved and chrome arms) for a pose to swap with `hide`.

A part (or the whole rig, `rig.recolor`) can carry `recolor` rules applied at
cut time, so a still can be re-dressed without a re-roll: each rule selects
pixels by hue range (degrees, wrapping) and optional saturation / value
floors, then sets or shifts the hue and scales or sets saturation and value.
The Elite Scav is the Scav's still with the olive sent to black and the amber
eye to magenta; the Scav's own pale face is sent into the hood's shadow.
"""
import argparse
import importlib
import json
import math
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pixel import PALETTE, sheet, save, preview  # noqa: E402

CAST = os.path.join(HERE, "cast")
SOURCE = os.path.join(HERE, "source")
WORK = os.path.join(HERE, "work")


# --- Geometry ---------------------------------------------------------------------

def load_spec(name):
    return json.load(open(os.path.join(CAST, f"{name}.json"), encoding="utf-8"))


def still_path(name):
    return os.path.join(SOURCE, name, "still.png")


def load_still(name, prop=None, cfg=None):
    """The chosen still (or a prop's) as RGBA with the flat background keyed
    out. `cfg` is the json's `still` (or `props.<prop>`) block: `key_seeds`
    ([[x, y], ...]) start extra flood fills in background pockets the border
    cannot reach (between a wide stance's legs, closed off by a floor shadow),
    `clear_boxes` ([[x0, y0, x1, y1], ...]) are wiped outright (the shadow)."""
    path = still_path(name) if prop is None else os.path.join(SOURCE, name, f"{prop}.png")
    img = Image.open(path).convert("RGBA")
    cfg = cfg or {}
    out = key_background(img, seeds=[tuple(s) for s in cfg.get("key_seeds", [])])
    if cfg.get("clear_boxes"):
        alpha = out.split()[3]
        d = ImageDraw.Draw(alpha)
        for x0, y0, x1, y1 in cfg["clear_boxes"]:
            d.rectangle([x0, y0, x1, y1], fill=0)
        out.putalpha(alpha)
    return out


def part_joints(rig, part):
    """The joint table a part's pivot/tip are read from: the character's, or
    its prop still's."""
    if "still" in part:
        return rig["prop_joints"][part["still"]]
    return rig["joints"]


def key_background(img, tolerance=30, seeds=()):
    """Make the flat background transparent. Background colour is read off the
    corners; only pixels *connected to the border* (or to a seed) are keyed,
    so background-coloured pixels inside the figure survive (fakemon-forge's
    lesson)."""
    rgb = img.convert("RGB")
    w, h = rgb.size
    px = rgb.load()
    corners = [px[0, 0], px[w - 1, 0], px[0, h - 1], px[w - 1, h - 1]]
    bg = tuple(sum(c[i] for c in corners) // 4 for i in range(3))

    def is_bg(p):
        return abs(p[0] - bg[0]) + abs(p[1] - bg[1]) + abs(p[2] - bg[2]) <= tolerance * 3

    keyed = bytearray(w * h)
    stack = [(x, 0) for x in range(w)] + [(x, h - 1) for x in range(w)] + [(0, y) for y in range(h)] + [(w - 1, y) for y in range(h)]
    stack += [(int(x), int(y)) for x, y in seeds]
    while stack:
        x, y = stack.pop()
        i = y * w + x
        if keyed[i] or not is_bg(px[x, y]):
            continue
        keyed[i] = 1
        if x > 0: stack.append((x - 1, y))
        if x < w - 1: stack.append((x + 1, y))
        if y > 0: stack.append((x, y - 1))
        if y < h - 1: stack.append((x, y + 1))
    out = img.copy()
    alpha = Image.frombytes("L", (w, h), bytes(0 if k else 255 for k in keyed))
    out.putalpha(alpha)
    return out


def content_bbox(img):
    return img.split()[3].getbbox()


def seg_dist2(p, a, b):
    """Squared distance from point p to segment ab."""
    ax, ay = a; bx, by = b; px, py = p
    dx, dy = bx - ax, by - ay
    l2 = dx * dx + dy * dy
    if l2 == 0:
        return (px - ax) ** 2 + (py - ay) ** 2
    t = max(0.0, min(1.0, ((px - ax) * dx + (py - ay) * dy) / l2))
    cx, cy = ax + t * dx, ay + t * dy
    return (px - cx) ** 2 + (py - cy) ** 2


# --- Commands ---------------------------------------------------------------------

def _draw_grid(img, step=50):
    d = ImageDraw.Draw(img)
    w, h = img.size
    for x in range(0, w, step):
        major = x % (step * 2) == 0
        d.line([(x, 0), (x, h)], fill=(255, 255, 0, 160) if major else (255, 255, 0, 70), width=1)
        if major:
            d.text((x + 2, 2), str(x), fill=(255, 255, 0, 255))
    for y in range(0, h, step):
        major = y % (step * 2) == 0
        d.line([(0, y), (w, y)], fill=(0, 255, 255, 160) if major else (0, 255, 255, 70), width=1)
        if major:
            d.text((2, y + 2), str(y), fill=(0, 255, 255, 255))
    return img


def cmd_grid(name, spec):
    """A labelled 50 px grid over the still and every prop still, to read
    joint coordinates off (work/<name>/grid.png, grid_<prop>.png)."""
    os.makedirs(os.path.join(WORK, name), exist_ok=True)
    stills = [("grid.png", still_path(name))]
    for prop in spec.get("props", {}):
        path = os.path.join(SOURCE, name, f"{prop}.png")
        if os.path.exists(path):
            stills.append((f"grid_{prop}.png", path))
    for out_name, path in stills:
        img = _draw_grid(Image.open(path).convert("RGBA"))
        out = os.path.join(WORK, name, out_name)
        img.save(out)
        print("wrote", out)


def cmd_joints(name, spec):
    """Draw joints and bones over the still (and prop stills) so the
    coordinates can be checked by eye."""
    rig = spec["rig"]
    canvases = {None: Image.open(still_path(name)).convert("RGBA")}
    for prop in rig.get("prop_joints", {}):
        path = os.path.join(SOURCE, name, f"{prop}.png")
        if not os.path.exists(path):
            print("prop still missing, skipped:", path)
            continue
        canvases[prop] = Image.open(path).convert("RGBA")
    for part in rig["parts"]:
        if "copy_of" in part or part.get("still") not in canvases:
            continue
        joints = part_joints(rig, part)
        d = ImageDraw.Draw(canvases[part.get("still")])
        a = joints[part["pivot"]]
        b = joints[part["tip"]]
        colour = (255, 80, 80, 255) if part.get("discard") else (0, 255, 120, 255)
        d.line([tuple(a), tuple(b)], fill=colour, width=5)
    for prop, img in canvases.items():
        d = ImageDraw.Draw(img)
        joints = rig["joints"] if prop is None else rig["prop_joints"][prop]
        for jname, (x, y) in joints.items():
            d.ellipse([x - 7, y - 7, x + 7, y + 7], outline=(255, 60, 200, 255), width=3)
            d.text((x + 9, y - 6), jname, fill=(255, 255, 0, 255))
        out = os.path.join(WORK, name, "joints_debug.png" if prop is None else f"joints_{prop}.png")
        os.makedirs(os.path.dirname(out), exist_ok=True)
        img.save(out)
        print("wrote", out)


def cmd_cut(name, spec):
    """Assign foreground pixels to the nearest bone; save each part with its
    pivot. The character's still first, then each prop still with the parts
    that come from it."""
    rig = spec["rig"]
    out_dir = os.path.join(SOURCE, name, "parts")
    os.makedirs(out_dir, exist_ok=True)
    # Parts are inputs to the bake, not game assets: keep Godot's importer out.
    open(os.path.join(SOURCE, ".gdignore"), "a").close()
    open(os.path.join(WORK, ".gdignore"), "a").close()
    meta = {}
    stills = [None] + sorted({p["still"] for p in rig["parts"] if "still" in p})
    for prop in stills:
        if prop is not None and not os.path.exists(os.path.join(SOURCE, name, f"{prop}.png")):
            print("prop still missing, its parts skipped:", prop)
            continue
        parts = [p for p in rig["parts"] if "copy_of" not in p and p.get("still") == prop]
        still_cfg = spec.get("still", {}) if prop is None else spec.get("props", {}).get(prop, {})
        meta.update(_cut_still(name, rig, prop, parts, out_dir, still_cfg))
    json.dump(meta, open(os.path.join(out_dir, "parts.json"), "w"), indent=2)
    print("wrote", len(meta), "parts to", out_dir)


def _cut_still(name, rig, prop, parts, out_dir, still_cfg=None):
    joints = rig["joints"] if prop is None else rig["prop_joints"][prop]
    still = load_still(name, prop, still_cfg)
    w, h = still.size
    alpha = still.split()[3].load()
    bones = []
    index = {part["name"]: i for i, part in enumerate(parts)}
    for i, part in enumerate(parts):
        if "cut_as" in part:
            # Takes another part's pixels (with its own recolour): the second
            # dress of a limb for a part swap. Not a bone of its own.
            continue
        a, b = joints[part["pivot"]], joints[part["tip"]]
        bones.append((i, tuple(a), tuple(b), float(part.get("weight", 1.0))))
    # An `overlay` part (a folded forearm that will swing out) keeps its pixels
    # for itself AND leaves them to the part beneath, so no hole opens when it
    # moves: the owner map is built without overlays, then overlays are
    # assigned on top in `owner2`.
    overlays = {i for i, part in enumerate(parts) if part.get("overlay")}
    base_bones = [b for b in bones if b[0] not in overlays]

    owner = [-1] * (w * h)
    owner2 = [-1] * (w * h)
    for y in range(h):
        for x in range(w):
            if alpha[x, y] < 8:
                continue
            best, best_d = -1, 1e18
            for i, a, b, wgt in base_bones:
                dd = seg_dist2((x, y), a, b) / (wgt * wgt)
                if dd < best_d:
                    best, best_d = i, dd
            owner[y * w + x] = best
            if overlays:
                best2, best_d2 = -1, 1e18
                for i, a, b, wgt in bones:
                    dd = seg_dist2((x, y), a, b) / (wgt * wgt)
                    if dd < best_d2:
                        best2, best_d2 = i, dd
                owner2[y * w + x] = best2 if best2 in overlays else -1

    pad = int(rig.get("pad", 6))
    debug = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    tints = [(255, 90, 90), (90, 255, 120), (90, 150, 255), (255, 220, 80), (255, 120, 255), (80, 240, 240), (255, 160, 60), (160, 160, 255), (200, 255, 120), (255, 100, 160), (120, 220, 200), (220, 180, 120)]
    meta = {}
    for i, part in enumerate(parts):
        src = index[part["cut_as"]] if "cut_as" in part else i
        table = owner2 if src in overlays else owner
        mask = Image.new("L", (w, h), 0)
        mp = mask.load()
        for y in range(h):
            for x in range(w):
                if table[y * w + x] == src:
                    mp[x, y] = 255
        # Pad so neighbours overlap, then round the joints.
        from PIL import ImageFilter
        mask = mask.filter(ImageFilter.MaxFilter(pad * 2 + 1))
        d = ImageDraw.Draw(mask)
        r = float(part.get("joint_radius", rig.get("joint_radius", 18)))
        for jn in (part["pivot"], part["tip"]):
            x, y = joints[jn]
            d.ellipse([x - r, y - r, x + r, y + r], fill=255)
        # Only keep figure pixels.
        fig = still.split()[3]
        mask = Image.fromarray(__import__("numpy").minimum(__import__("numpy").array(mask), __import__("numpy").array(fig)))
        bbox = mask.getbbox()
        if bbox is None:
            print(f"part {part['name']}: empty, skipped")
            continue
        if part.get("discard"):
            # Cut so its pixels are claimed, but never saved or rendered.
            layer = Image.new("RGBA", (w, h), (255, 255, 255, 0))
            layer.putalpha(mask.point(lambda v: v * 90 // 255))
            debug.alpha_composite(layer)
            continue
        piece = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        piece.paste(still, (0, 0), mask)
        piece = piece.crop(bbox)
        rules = part.get("recolor", rig.get("recolor"))
        if rules:
            piece = recolor(piece, rules, origin=(bbox[0], bbox[1]))
        if part.get("thicken"):
            piece = thicken(piece, int(part["thicken"]))
        piece.save(os.path.join(out_dir, f"{part['name']}.png"))
        px, py = joints[part["pivot"]]
        meta[part["name"]] = {"pivot": [px - bbox[0], py - bbox[1]], "origin": [bbox[0], bbox[1]], "still": prop}
        tint = tints[i % len(tints)]
        layer = Image.new("RGBA", (w, h), tint + (0,))
        layer.putalpha(mask.point(lambda v: v * 150 // 255))
        debug.alpha_composite(layer)
    dbg = still.copy()
    dbg.alpha_composite(debug)
    dbg_path = os.path.join(WORK, name, "parts_debug.png" if prop is None else f"parts_{prop}.png")
    os.makedirs(os.path.dirname(dbg_path), exist_ok=True)
    dbg.save(dbg_path)
    print("wrote", dbg_path)
    return meta


def thicken(img, radius):
    """Dilate a part by `radius` still px, new pixels in the part's mean
    colour: for a shape drawn thinner than an art pixel (rotor blades, a
    cable) that the k-centroid vote would otherwise drop."""
    import numpy as np
    from PIL import ImageFilter
    arr = np.array(img.convert("RGBA"))
    opaque = arr[..., 3] > 0
    if not opaque.any():
        return img
    mean = arr[opaque][:, :3].mean(0)
    grown = np.array(img.split()[3].filter(ImageFilter.MaxFilter(radius * 2 + 1)))
    new = (grown > 0) & ~opaque
    arr[new, :3] = mean.astype(np.uint8)
    arr[new, 3] = grown[new]
    return Image.fromarray(arr, "RGBA")


def recolor(img, rules, origin=(0, 0)):
    """Re-dress a part: for each rule, the pixels whose hue lies in `hue`
    ([lo, hi] degrees, wrapping past 360), whose saturation and value are
    at least `min_sat` / `min_val` (0..1; `max_sat` / `max_val` cap them)
    and, with `box` ([x0, y0, x1, y1] in still pixels), that lie inside it,
    get `hue_to` or `hue_shift` (degrees), `sat_to` or `sat_mul`, `val_to`
    or `val_mul`. Shading survives because only the selected channel moves.
    `origin` is where the part's image sits in the still, for `box`."""
    import numpy as np
    rgba = np.array(img.convert("RGBA"))
    hsv = np.array(img.convert("RGB").convert("HSV")).astype(np.float32)
    h, sv, v = hsv[..., 0] * 360.0 / 255.0, hsv[..., 1] / 255.0, hsv[..., 2] / 255.0
    alpha = rgba[..., 3] > 0
    H, W = alpha.shape
    yy, xx = np.mgrid[0:H, 0:W]
    xx, yy = xx + origin[0], yy + origin[1]
    for rule in rules:
        lo, hi = rule.get("hue", (0, 360))
        sel = ((h >= lo) & (h <= hi)) if lo <= hi else ((h >= lo) | (h <= hi))
        sel &= alpha & (sv >= float(rule.get("min_sat", 0.0))) & (sv <= float(rule.get("max_sat", 1.0)))
        sel &= (v >= float(rule.get("min_val", 0.0))) & (v <= float(rule.get("max_val", 1.0)))
        if "box" in rule:
            x0, y0, x1, y1 = rule["box"]
            sel &= (xx >= x0) & (xx <= x1) & (yy >= y0) & (yy <= y1)
        if not sel.any():
            continue
        if "hue_to" in rule:
            h[sel] = float(rule["hue_to"])
        if "hue_shift" in rule:
            h[sel] = (h[sel] + float(rule["hue_shift"])) % 360.0
        if "sat_to" in rule:
            sv[sel] = float(rule["sat_to"])
        if "sat_mul" in rule:
            sv[sel] = np.clip(sv[sel] * float(rule["sat_mul"]), 0.0, 1.0)
        if "val_to" in rule:
            v[sel] = float(rule["val_to"])
        if "val_mul" in rule:
            v[sel] = np.clip(v[sel] * float(rule["val_mul"]), 0.0, 1.0)
        if "val_add" in rule:
            v[sel] = np.clip(v[sel] + float(rule["val_add"]), 0.0, 1.0)
        if "sat_add" in rule:
            sv[sel] = np.clip(sv[sel] + float(rule["sat_add"]), 0.0, 1.0)
    out = np.stack([h * 255.0 / 360.0, sv * 255.0, v * 255.0], axis=-1)
    rgb = Image.fromarray(np.clip(out, 0, 255).astype(np.uint8), "HSV").convert("RGB")
    rgba[..., :3] = np.array(rgb)
    return Image.fromarray(rgba, "RGBA")


class Rig:
    """Forward kinematics over the cut parts, rendering at still resolution."""

    def __init__(self, name, spec):
        self.spec = spec
        rig = spec["rig"]
        self.joints = {k: tuple(v) for k, v in rig["joints"].items()}
        self.parts = {p["name"]: p for p in rig["parts"] if not p.get("discard")}
        self.order = [p["name"] for p in rig["parts"] if not p.get("discard")]
        meta = json.load(open(os.path.join(SOURCE, name, "parts", "parts.json")))
        self.images = {}
        self.meta = dict(meta)
        self.pivot_pos = {}
        for pname in self.order:
            part = self.parts[pname]
            if "copy_of" in part:
                continue
            path = os.path.join(SOURCE, name, "parts", f"{pname}.png")
            if os.path.exists(path):
                self.images[pname] = Image.open(path).convert("RGBA")
            # A prop part hangs from a character joint (`attach`); its own
            # pivot only says where in its image the hinge is.
            self.pivot_pos[pname] = self.joints[part["attach"] if "still" in part else part.get("attach", part["pivot"])]
        # Copies: the near limb's image, darkened, hung from a shifted pivot.
        for pname in self.order:
            part = self.parts[pname]
            if "copy_of" not in part:
                continue
            src = part["copy_of"]
            if src not in self.images:
                continue
            img = self.images[src].copy()
            t = float(part.get("tint", 1.0))
            if t != 1.0:
                r, g, b, a = img.split()
                img = Image.merge("RGBA", (r.point(lambda v: int(v * t)), g.point(lambda v: int(v * t)), b.point(lambda v: int(v * t)), a))
            self.images[pname] = img
            self.meta[pname] = self.meta[src]
            dx, dy = part.get("offset", (0, 0))
            sx, sy = self.pivot_pos[src]
            self.pivot_pos[pname] = (sx + dx, sy + dy)
        still = load_still(name, cfg=spec.get("still"))
        bbox = content_bbox(still)
        self.figure_height = bbox[3] - bbox[1]
        self.floor_y = bbox[3]
        # Ground reference: the lowest joint (a sole) or the content bottom.
        self.root = rig["root"]

    def parent_of(self, pname):
        return self.parts[pname].get("parent")

    def world(self, pose):
        """Return {part: (angle_deg, pivot_world_xy)} for a pose."""
        angles = pose.get("rot", {})
        out = {}

        def solve(pname):
            if pname in out:
                return out[pname]
            part = self.parts[pname]
            local = float(angles.get(pname, 0.0)) + float(part.get("rest", 0.0))
            parent = part.get("parent")
            pivot_rest = self.pivot_pos[pname]
            if parent is None:
                ang = local
                dx, dy = pose.get("offset", (0, 0))
                pos = (pivot_rest[0] + dx, pivot_rest[1] + dy)
            else:
                pang, ppos = solve(parent)
                ppivot_rest = self.pivot_pos[parent]
                # The child's pivot, expressed relative to the parent's pivot, rotated by the parent's angle.
                rx, ry = pivot_rest[0] - ppivot_rest[0], pivot_rest[1] - ppivot_rest[1]
                th = math.radians(pang)
                pos = (ppos[0] + rx * math.cos(th) - ry * math.sin(th), ppos[1] + rx * math.sin(th) + ry * math.cos(th))
                ang = pang + local
            out[pname] = (ang, pos)
            return out[pname]

        for pname in self.order:
            solve(pname)
        return out

    def render(self, pose, canvas_size, floor, z=None, grounded=True):
        """Composite the pose on a canvas at still resolution.

        The figure is anchored by its root joint so that, at rest, the still's
        floor line lands on `floor`. When `grounded`, the whole figure is then
        shifted so the lowest point of any `ground` part (the feet) sits exactly
        on the floor line: a swung leg rises off the ground, so without this
        every walking frame floats. The shift is the natural walk bob."""
        canvas = Image.new("RGBA", canvas_size, (0, 0, 0, 0))
        world = self.world(pose)
        root_rest = self.pivot_pos[self.root]
        ax = floor[0] - root_rest[0]
        ay = floor[1] - self.floor_y
        order = z or self.order
        placements = []
        lowest = None
        hidden = set(pose.get("hide", ()))
        tints = pose.get("tint", {})
        for pname in order:
            if pname not in self.images or pname in hidden:
                continue
            img = self.images[pname]
            if pname in tints:
                img = self._tint(img, tints[pname])
            pivot = self.meta[pname]["pivot"]
            ang, pos = world[pname]
            scale = self.parts[pname].get("scale", 1.0)
            placed, ppivot = self._transform(img, pivot, ang, scale if isinstance(scale, (list, tuple)) else float(scale))
            tx = int(round(pos[0] + ax - ppivot[0]))
            ty = int(round(pos[1] + ay - ppivot[1]))
            placements.append((placed, tx, ty))
            if self.parts[pname].get("ground"):
                bottom = ty + (placed.split()[3].getbbox() or (0, 0, 0, placed.height))[3] - 1
                lowest = bottom if lowest is None else max(lowest, bottom)
        dy = 0
        if grounded and lowest is not None:
            dy = int(round(floor[1] - lowest))
        for placed, tx, ty in placements:
            canvas.alpha_composite(placed, (tx, ty + dy))
        return canvas

    @staticmethod
    def _tint(img, factor):
        """A pose's per-part brightness: a scalar or an [r, g, b] multiplier.
        This is how a lens brightens on aim, a lamp lights in the windup, a
        readout goes hot: the part's pixels scaled, the palette snap lands
        them on the ramp's next step."""
        f = factor if isinstance(factor, (list, tuple)) else (factor, factor, factor)
        r, g, b, a = img.split()
        chans = [c.point(lambda v, k=k: max(0, min(255, int(v * k)))) for c, k in zip((r, g, b), f)]
        return Image.merge("RGBA", (*chans, a))

    @staticmethod
    def _transform(img, pivot, angle_deg, scale=1.0):
        """Rotate `img` by `angle_deg` and scale it by `scale`, both about
        `pivot` (image coords). Returns (image, pivot in new image)."""
        if not isinstance(scale, (list, tuple)) and abs(angle_deg) < 1e-6 and abs(scale - 1.0) < 1e-6:
            return img, (pivot[0], pivot[1])
        if isinstance(scale, (list, tuple)):
            # Non-uniform: squash the image about the pivot first (a frontal
            # shield still seen edge-on), then rotate uniformly.
            sx, sy = float(scale[0]), float(scale[1])
            w, h = img.size
            nw, nh = max(1, int(round(w * sx))), max(1, int(round(h * sy)))
            img = img.resize((nw, nh), Image.BICUBIC)
            pivot = (pivot[0] * sx, pivot[1] * sy)
            scale = 1.0
            if abs(angle_deg) < 1e-6:
                return img, (pivot[0], pivot[1])
        th = math.radians(angle_deg)
        c, s = math.cos(th), math.sin(th)
        k = float(scale)
        w, h = img.size
        corners = [(0, 0), (w, 0), (0, h), (w, h)]
        pts = [(k * ((x - pivot[0]) * c - (y - pivot[1]) * s), k * ((x - pivot[0]) * s + (y - pivot[1]) * c)) for x, y in corners]
        minx = math.floor(min(p[0] for p in pts)); maxx = math.ceil(max(p[0] for p in pts))
        miny = math.floor(min(p[1] for p in pts)); maxy = math.ceil(max(p[1] for p in pts))
        nw, nh = maxx - minx, maxy - miny
        # Inverse map: output (X, Y) -> input (x, y). Output origin is at (minx, miny) relative to the pivot.
        # x_in = pivot + R(-th) * (out + (minx, miny)) / k
        a, b = c / k, s / k
        d, e = -s / k, c / k
        cx = pivot[0] + (minx * c + miny * s) / k
        fy = pivot[1] + (-minx * s + miny * c) / k
        out = img.transform((nw, nh), Image.AFFINE, (a, b, cx, d, e, fy), resample=Image.BICUBIC)
        return out, (-minx, -miny)


def snap_to_palette(img, palette_keys=None):
    """Nearest palette colour per opaque pixel, binary alpha. Hi-bit pixel art
    has no soft edges and no colours off the sheet."""
    import numpy as np
    keys = palette_keys or list(PALETTE.keys())
    pal = np.array([PALETTE[k] for k in keys], dtype=np.int32)
    arr = np.array(img.convert("RGBA"), dtype=np.int32)
    rgb = arr[..., :3]
    a = arr[..., 3]
    flat = rgb.reshape(-1, 3)
    d = ((flat[:, None, :] - pal[None, :, :]) ** 2).sum(-1)
    idx = d.argmin(1)
    snapped = pal[idx].reshape(rgb.shape)
    out = np.zeros_like(arr)
    out[..., :3] = snapped
    out[..., 3] = np.where(a >= 128, 255, 0)
    out[..., :3] = np.where(out[..., 3:4] == 255, out[..., :3], 0)
    return Image.fromarray(out.astype(np.uint8), "RGBA")


LUMA = (0.299, 0.587, 0.114)


def _is_accent(rgb, accent):
    """An accent is saturated (cyan, magenta, amber) or bright (white, chrome
    highlights): the small marks the look sheet wants to survive the vote."""
    import numpy as np
    chroma = float(rgb.max() - rgb.min())
    luma = float(rgb @ np.array(LUMA, dtype=np.float32))
    return chroma >= float(accent.get("chroma", 120)) or luma >= float(accent.get("luma", 200))


def k_centroid(canvas, art_size, k=2, iters=6, accent=None):
    """Pixelate by dominant colour, not by average (Astropulse's k-centroid,
    the method fakemon-forge validated over NEAREST). Each art pixel covers a
    block of still pixels; the block's opaque pixels are clustered into `k`
    colours and the biggest cluster's mean wins. Averaging would blend the
    still's dark lineart into every fill and read as blur; this keeps fills
    flat and edges hard. A pixel is opaque when at least half its block is.

    `accent` ({share, chroma, luma}) lets a losing cluster win when it is an
    accent colour covering at least `share` of the block, so a one-pixel
    piping line or a visor highlight is not voted away by the fill around it.
    Seeds are the darkest and brightest pixels, then the pixel farthest from
    the seeds so far (k > 2)."""
    import numpy as np
    arr = np.array(canvas, dtype=np.float32)
    H, W = arr.shape[:2]
    aw, ah = art_size
    out = np.zeros((ah, aw, 4), dtype=np.uint8)
    ys = [int(round(j * H / ah)) for j in range(ah + 1)]
    xs = [int(round(i * W / aw)) for i in range(aw + 1)]
    lumav = np.array(LUMA, dtype=np.float32)
    for j in range(ah):
        for i in range(aw):
            block = arr[ys[j]:max(ys[j] + 1, ys[j + 1]), xs[i]:max(xs[i] + 1, xs[i + 1])].reshape(-1, 4)
            if block[:, 3].mean() < 128:
                continue
            px = block[block[:, 3] > 127][:, :3]
            if len(px) == 0:
                continue
            luma = px @ lumav
            seeds = [px[luma.argmin()], px[luma.argmax()]]
            while len(seeds) < min(k, len(px)):
                d = np.min([((px - c) ** 2).sum(-1) for c in seeds], axis=0)
                seeds.append(px[d.argmax()])
            cents = np.stack(seeds)
            labels = np.zeros(len(px), dtype=np.int64)
            for _ in range(iters):
                d = ((px[:, None, :] - cents[None, :, :]) ** 2).sum(-1)
                labels = d.argmin(1)
                for c in range(len(cents)):
                    m = labels == c
                    if m.any():
                        cents[c] = px[m].mean(0)
            counts = np.bincount(labels, minlength=len(cents))
            win = int(counts.argmax())
            if accent and not _is_accent(cents[win], accent):
                share = counts / counts.sum()
                cands = [c for c in range(len(cents))
                         if c != win and share[c] >= float(accent.get("share", 0.25)) and _is_accent(cents[c], accent)]
                if cands:
                    win = max(cands, key=lambda c: share[c])
            out[j, i, :3] = np.clip(cents[win], 0, 255)
            out[j, i, 3] = 255
    return Image.fromarray(out, "RGBA")


def _box_mean(values, weights, radius):
    """Weighted mean over a (2*radius+1)^2 window, by integral images."""
    import numpy as np

    def boxsum(a):
        r = radius
        p = np.pad(a, r)
        s = np.pad(p, ((1, 0), (1, 0))).cumsum(0).cumsum(1)
        n = 2 * r + 1
        return s[n:, n:] - s[:-n, n:] - s[n:, :-n] + s[:-n, :-n]

    return boxsum(values * weights) / np.maximum(boxsum(weights), 1e-6)


def line_mask(canvas, radius=7, delta=22):
    """The still's dark lineart: opaque pixels darker than the mean of their
    neighbourhood by more than `delta` luma. A local test, so it finds a thin
    line on navy as well as on grey and leaves flat dark fills (hair) alone."""
    import numpy as np
    arr = np.array(canvas, dtype=np.float32)
    a = arr[..., 3] / 255.0
    luma = arr[..., :3] @ np.array(LUMA, dtype=np.float32)
    mean = _box_mean(luma, a, int(radius))
    return (a > 0.5) & (luma < mean - float(delta))


def block_coverage(mask, opaque, art_size):
    """Per art pixel: the share of its block's opaque still pixels that are in
    `mask`. Same block edges as `k_centroid`."""
    import numpy as np
    H, W = mask.shape
    aw, ah = art_size
    ys = [int(round(j * H / ah)) for j in range(ah)]
    xs = [int(round(i * W / aw)) for i in range(aw)]
    m = np.add.reduceat(np.add.reduceat((mask & opaque).astype(np.float32), ys, axis=0), xs, axis=1)
    o = np.add.reduceat(np.add.reduceat(opaque.astype(np.float32), ys, axis=0), xs, axis=1)
    return m / np.maximum(o, 1.0)


def interior_mask(a):
    """Opaque pixels whose four neighbours are all opaque."""
    import numpy as np
    pad = np.pad(a, 1, constant_values=False)
    return a & pad[:-2, 1:-1] & pad[2:, 1:-1] & pad[1:-1, :-2] & pad[1:-1, 2:]


def apply_lines(art, canvas, art_size, cfg):
    """Line layer: where the still's lineart covers at least `coverage` of an
    art pixel's block but lost the k-centroid vote, darken that art pixel by
    `factor`, so the seams between materials come back as one-pixel steps.
    Silhouette pixels are left to the edge shade."""
    import numpy as np
    mask = line_mask(canvas, cfg.get("radius", 7), cfg.get("delta", 22))
    opaque = np.array(canvas)[..., 3] > 127
    cov = block_coverage(mask, opaque, art_size)
    arr = np.array(art).astype(np.float32)
    a = arr[..., 3] > 127
    hit = interior_mask(a) & (cov >= float(cfg.get("coverage", 0.3)))
    arr[hit, :3] *= float(cfg.get("factor", 0.7))
    return Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGBA")


def shade_edges(img, shade, lit=None, light=(-1, -1)):
    """Silhouette edge pixels one shade darker: the hi-bit outline rule
    (docs/art/cast.md: no black lines, a darker step of the local colour).
    With `lit`, the edge is directional: pixels whose outward normal faces the
    light (upper left by the look sheet's rule) are multiplied by `lit`
    instead (1.0 = the edge step is simply absent where the light hits; above
    1.0 = a lighter step), the rest by `shade`."""
    import numpy as np
    arr = np.array(img).astype(np.float32)
    a = arr[..., 3] > 127
    edge = a & ~interior_mask(a)
    if lit is None:
        arr[edge, :3] *= shade
        return Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGBA")
    H, W = a.shape
    pad = np.pad(a, 1, constant_values=False)
    nx = np.zeros((H, W), dtype=np.float32)
    ny = np.zeros((H, W), dtype=np.float32)
    for dy in (-1, 0, 1):
        for dx in (-1, 0, 1):
            if dx == 0 and dy == 0:
                continue
            outside = a & ~pad[1 + dy:1 + dy + H, 1 + dx:1 + dx + W]
            nx += dx * outside
            ny += dy * outside
    dot = nx * light[0] + ny * light[1]
    arr[edge & (dot > 0), :3] *= float(lit)
    arr[edge & (dot <= 0), :3] *= float(shade)
    return Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGBA")


def downscale(canvas, art_size, target):
    """Still-resolution frame -> art pixels, then the line layer, then the edge
    shade, then the palette snap. Every knob is a `target` key:

      downscale  "kcentroid" (default) | "box"
      k          clusters per block (2)
      accent     null | {share, chroma, luma}: an accent minority wins its block
      lines      null | {radius, delta, coverage, factor}: the line layer
      edge       0.62 | {shade, lit, light}: uniform or directional edge shade
      palette    the character's subset of pixel.PALETTE names
    """
    method = target.get("downscale", "kcentroid")
    if method == "box":
        import numpy as np
        arr = np.array(canvas, dtype=np.float32) / 255.0
        arr[..., :3] *= arr[..., 3:4]
        pm = Image.fromarray((arr * 255).astype(np.uint8), "RGBA").resize(art_size, Image.BOX)
        arr = np.array(pm, dtype=np.float32) / 255.0
        a = np.clip(arr[..., 3:4], 1e-4, 1.0)
        arr[..., :3] = np.clip(arr[..., :3] / a, 0, 1)
        img = Image.fromarray((arr * 255).astype(np.uint8), "RGBA")
    else:
        img = k_centroid(canvas, art_size, k=int(target.get("k", 2)), accent=target.get("accent"))
    lines = target.get("lines")
    if lines:
        img = apply_lines(img, canvas, art_size, lines)
    edge = target.get("edge", 0.62)
    if isinstance(edge, dict):
        img = shade_edges(img, float(edge.get("shade", 0.62)), float(edge.get("lit", 1.0)), tuple(edge.get("light", (-1, -1))))
    elif edge and edge < 1.0:
        img = shade_edges(img, float(edge))
    return snap_to_palette(img, target.get("palette"))


def colour_count(img):
    """Distinct opaque colours on a sheet or frame."""
    import numpy as np
    arr = np.array(img.convert("RGBA"))
    px = arr[arr[..., 3] > 127][:, :3]
    return 0 if len(px) == 0 else len(np.unique(px, axis=0))


def cmd_bake(name, spec, tag=None, work_only=False):
    rig = Rig(name, spec)
    target = spec["target"]
    frame_w, frame_h = target["frame"]           # art px
    scale = target["scale"]
    height_art = target["height_art_px"]
    poses_mod = importlib.import_module(f"cast.{name}_poses")
    clips = poses_mod.clips(rig)

    # Still px per art px: the figure's rest height maps to `height_art`.
    k = rig.figure_height / height_art
    canvas_size = (int(round(frame_w * k)), int(round(frame_h * k)))
    floor = (canvas_size[0] / 2 + target.get("foot_shift_art_px", 0) * k, canvas_size[1] - 1)

    all_frames = []
    table = {}
    for clip_name, clip in clips.items():
        first = len(all_frames)
        for pose in clip["frames"]:
            if "offset_art" in pose:
                ox, oy = pose["offset_art"]
                pose = dict(pose, offset=(ox * k, oy * k))
            big = rig.render(pose, canvas_size, floor, z=clip.get("z"), grounded=clip.get("grounded", True))
            all_frames.append(downscale(big, (frame_w, frame_h), target))
        table[clip_name] = [first, len(clip["frames"]), clip.get("fps", 0.0), clip.get("loop", False)]
    img = sheet(all_frames)
    os.makedirs(os.path.join(WORK, name), exist_ok=True)
    idle0 = all_frames[table["idle"][0]] if "idle" in table else all_frames[0]
    meta = {"frame": [frame_w, frame_h], "scale": scale, "clips": table, "target": target,
            "chosen_seed": spec.get("still", {}).get("chosen_seed"),
            "colours_sheet": colour_count(img), "colours_idle0": colour_count(idle0)}
    if tag:
        bakes = os.path.join(WORK, name, "bakes")
        os.makedirs(bakes, exist_ok=True)
        img.save(os.path.join(bakes, f"{tag}.png"))
        json.dump(meta, open(os.path.join(bakes, f"{tag}.json"), "w"), indent=2)
        print(f"tag {tag}: {meta['colours_sheet']} colours on the sheet, {meta['colours_idle0']} in idle[0] -> {bakes}/{tag}.png")
    if work_only:
        return
    out_rel = spec["sheet"]
    path = save(img, out_rel, scale=scale)
    preview(img, os.path.join(HERE, f"preview_{name}.png"), 4)
    json.dump({"frame_width": frame_w * scale, "frame_height": frame_h * scale, "clips": table},
              open(os.path.join(WORK, name, "clips.json"), "w"), indent=2)
    print("wrote", path, f"({meta['colours_sheet']} colours)")
    print(f"frame_width = {frame_w * scale}\nframe_height = {frame_h * scale}\nclips = {{")
    for cname, row in table.items():
        print(f'"{cname}": [{row[0]}, {row[1]}, {float(row[2])}, {"true" if row[3] else "false"}],')
    print("}")


# --- A/B ----------------------------------------------------------------------------

# The four cells of a strip: the first clip of each group the sheet has, so
# Dani shows idle / run / run / attack and an enemy idle / run / windup /
# lunge (the drone: hover / aim). `ab --picks idle:0,run:1,...` overrides.
AB_PICK_GROUPS = [
    [("idle", 0)],
    [("run", 1), ("hover", 0)],
    [("run", 3), ("windup", 0), ("hover", 1)],
    [("attack", 1), ("lunge", 0), ("aim", 0), ("talk", 0)],
]
AB_GROUND = (96, 100, 108, 255)


def ab_picks(meta, override=None):
    if override:
        out = []
        for item in override.split(","):
            clip, _, idx = item.partition(":")
            out.append((clip, int(idx or 0)))
        return out
    picks = []
    for group in AB_PICK_GROUPS:
        for clip, idx in group:
            if clip in meta["clips"]:
                picks.append((clip, idx))
                break
    return picks


def ab_cycle(meta):
    """The clip the GIF loops: the run, or the drone's hover, or whatever loops."""
    for clip in ("run", "hover"):
        if clip in meta["clips"]:
            return clip
    for clip, row in meta["clips"].items():
        if row[3]:
            return clip
    return next(iter(meta["clips"]))


def _load_bake(name, tag):
    bakes = os.path.join(WORK, name, "bakes")
    img = Image.open(os.path.join(bakes, f"{tag}.png")).convert("RGBA")
    meta = json.load(open(os.path.join(bakes, f"{tag}.json")))
    return img, meta


def _frame(img, meta, clip, idx):
    fw, fh = meta["frame"]
    first, count = meta["clips"][clip][:2]
    i = first + (idx % count)
    return img.crop((i * fw, 0, (i + 1) * fw, fh))


def _cell(frame, zoom):
    big = frame.resize((frame.width * zoom, frame.height * zoom), Image.NEAREST)
    cell = Image.new("RGBA", big.size, AB_GROUND)
    cell.alpha_composite(big)
    return cell


def _font(size):
    from PIL import ImageFont
    try:
        return ImageFont.load_default(size=size)
    except TypeError:
        return ImageFont.load_default()


def cmd_strip(name, bakes, clip, out, zoom):
    """Every frame of `clip`, one row per tag: a cycle judged as stills."""
    fw, fh = bakes[0][2]["frame"]
    cw, ch = fw * zoom, fh * zoom
    gap, label_w, header = 8, 150, 22
    font, small = _font(15), _font(12)
    n = max(m["clips"][clip][1] for _, _, m in bakes)
    W = label_w + n * (cw + gap) + gap
    H = header + len(bakes) * (ch + gap) + gap
    strip = Image.new("RGBA", (W, H), (30, 32, 40, 255))
    d = ImageDraw.Draw(strip)
    for c in range(n):
        d.text((label_w + c * (cw + gap) + 4, 5), f"{clip}[{c}]", fill=(220, 220, 230, 255), font=small)
    for r, (tag, img, meta) in enumerate(bakes):
        y = header + r * (ch + gap)
        d.text((8, y + 6), tag, fill=(255, 220, 80, 255), font=font)
        count = meta["clips"][clip][1]
        for c in range(count):
            strip.alpha_composite(_cell(_frame(img, meta, clip, c), zoom), (label_w + c * (cw + gap), y))
    out_png = os.path.join(WORK, name, f"{out}_{clip}.png")
    strip.save(out_png)
    print("wrote", out_png)


def cmd_ab(name, spec, tags, out="ab", zoom=4, strip_clip=None, picks=None):
    """Rows of tagged bakes, the same four frames each, at `zoom` on a grey
    ground, judged at target size; plus the run cycles side by side as a GIF.
    `strip_clip` adds a filmstrip of every frame of that clip."""
    if not tags:
        raise SystemExit("ab: give at least one bake tag (see bake --tag)")
    bakes = [(t, *_load_bake(name, t)) for t in tags]
    if strip_clip:
        cmd_strip(name, bakes, strip_clip, out, zoom)
    AB_PICKS = ab_picks(bakes[0][2], picks)
    cycle = ab_cycle(bakes[0][2])
    fw, fh = bakes[0][2]["frame"]
    cw, ch = fw * zoom, fh * zoom
    gap, label_w, header = 8, 150, 22
    font, small = _font(15), _font(12)
    W = label_w + len(AB_PICKS) * (cw + gap) + gap
    H = header + len(bakes) * (ch + gap) + gap
    strip = Image.new("RGBA", (W, H), (30, 32, 40, 255))
    d = ImageDraw.Draw(strip)
    for c, (clip, idx) in enumerate(AB_PICKS):
        d.text((label_w + c * (cw + gap) + 4, 5), f"{clip}[{idx}]", fill=(220, 220, 230, 255), font=small)
    for r, (tag, img, meta) in enumerate(bakes):
        y = header + r * (ch + gap)
        d.text((8, y + 6), tag, fill=(255, 220, 80, 255), font=font)
        d.text((8, y + 28), f"{meta['colours_sheet']} colours / sheet", fill=(200, 200, 210, 255), font=small)
        d.text((8, y + 44), f"{meta['colours_idle0']} in idle[0]", fill=(200, 200, 210, 255), font=small)
        if meta.get("chosen_seed") is not None:
            d.text((8, y + 60), f"still seed {meta['chosen_seed']}", fill=(160, 160, 170, 255), font=small)
        for c, (clip, idx) in enumerate(AB_PICKS):
            strip.alpha_composite(_cell(_frame(img, meta, clip, idx), zoom), (label_w + c * (cw + gap), y))
    out_png = os.path.join(WORK, name, f"{out}.png")
    strip.save(out_png)

    # Run cycles side by side, one column per tag, looping at the clip's fps.
    n = max(m["clips"][cycle][1] for _, _, m in bakes)
    fps = bakes[0][2]["clips"][cycle][2] or 12.0
    gw = gap + len(bakes) * (cw + gap)
    gh = header + ch + gap
    gif_frames = []
    for t in range(n):
        f = Image.new("RGBA", (gw, gh), (30, 32, 40, 255))
        dd = ImageDraw.Draw(f)
        for c, (tag, img, meta) in enumerate(bakes):
            x = gap + c * (cw + gap)
            dd.text((x + 2, 4), tag, fill=(255, 220, 80, 255), font=small)
            f.alpha_composite(_cell(_frame(img, meta, cycle, t), zoom), (x, header))
        gif_frames.append(f.convert("RGB").quantize(colors=256, method=Image.Quantize.MEDIANCUT))
    out_gif = os.path.join(WORK, name, f"{out}_{cycle}.gif")
    gif_frames[0].save(out_gif, save_all=True, append_images=gif_frames[1:], duration=int(round(1000 / fps)), loop=0)
    print("wrote", out_png, "and", out_gif)
    for tag, _, meta in bakes:
        print(f"  {tag:>14}: {meta['colours_sheet']:3d} colours on the sheet, {meta['colours_idle0']:3d} in idle[0]")


def apply_overrides(spec, sets):
    """`--set target.edge=0.5` / `--set target.lines={"coverage":0.3}`: one
    dotted key of the spec, value parsed as JSON (a bare word stays a string)."""
    for item in sets or []:
        path, _, raw = item.partition("=")
        try:
            value = json.loads(raw)
        except json.JSONDecodeError:
            value = raw
        node = spec
        keys = path.split(".")
        for key in keys[:-1]:
            node = node.setdefault(key, {})
        node[keys[-1]] = value
    return spec


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("name")
    ap.add_argument("command", choices=["grid", "joints", "cut", "bake", "ab"])
    ap.add_argument("tags", nargs="*", help="ab: bake tags to compare, in row order")
    ap.add_argument("--tag", help="bake: also keep the 1x sheet as work/<name>/bakes/<tag>.png")
    ap.add_argument("--work-only", action="store_true", help="bake: do not write the game asset or the preview")
    ap.add_argument("--set", action="append", metavar="KEY=JSON", help="override one spec key for this run")
    ap.add_argument("--out", default="ab", help="ab: basename for the strip and the gif under work/<name>/")
    ap.add_argument("--zoom", type=int, default=4, help="ab: magnification of the strip")
    ap.add_argument("--strip", metavar="CLIP", help="ab: also write every frame of CLIP per tag, as work/<name>/<out>_<CLIP>.png")
    ap.add_argument("--picks", metavar="CLIP:IDX,...", help="ab: the four cells (default: idle, run|hover, run|windup, attack|lunge|aim)")
    args = ap.parse_args()
    spec = apply_overrides(load_spec(args.name), args.set)
    if args.command == "bake":
        cmd_bake(args.name, spec, tag=args.tag, work_only=args.work_only)
    elif args.command == "ab":
        cmd_ab(args.name, spec, args.tags, out=args.out, zoom=args.zoom, strip_clip=args.strip, picks=args.picks)
    else:
        {"grid": cmd_grid, "joints": cmd_joints, "cut": cmd_cut}[args.command](args.name, spec)


if __name__ == "__main__":
    main()
