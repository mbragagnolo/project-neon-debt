"""The shape vocabulary an effect is authored from, rendered as fields.

An effect frame is a list of shapes in art px relative to the effect's
anchor (y down). Every shape names a ramp (a list of palette names, hot or
dust) and a tone: a float position along that ramp, so a disc can run from
white at its centre to rust at its edge and the bake decides where the
steps fall. The same function renders a frame at 1x (tone rounded to the
nearest step, no edge rule: the direct path) or at 8x with continuous
tones for the character bake to reduce (the bake path).

Shapes (all positions in art px from the anchor):
  disc    at, r, tone [centre, edge]
  ring    at, r, w, tone [inner, outer], ry (optional: an ellipse, the shockwave)
  streak  from, angle (deg, 0 = +x, -90 = up), len, w, tone [base, tip]
  chip    at, s, tone                        (a square of debris)
  puff    at, r, lobes [[dx, dy, r], ...], tone [lit, dark]
          a cluster of discs shaded by the upper-left light, the dust family
"""
import math

import numpy as np
from PIL import Image

LIGHT = (-1.0, -1.0)  # the look sheet's light: upper left


def ramp_rgb(names, palette):
    return np.array([palette[n] for n in names], dtype=np.float32)


def tone_rgb(ramp, t, quantize):
    """Tone positions -> RGB. `t` is an array of floats in [0, len-1]."""
    n = len(ramp)
    t = np.clip(t, 0.0, n - 1.0)
    if quantize:
        return ramp[np.rint(t).astype(int)]
    lo = np.floor(t).astype(int)
    hi = np.minimum(lo + 1, n - 1)
    f = (t - lo)[..., None]
    return ramp[lo] * (1 - f) + ramp[hi] * f


def _grid(frame, anchor, scale):
    w, h = frame
    ax, ay = anchor
    xs = (np.arange(w * scale) + 0.5) / scale - ax
    ys = (np.arange(h * scale) + 0.5) / scale - ay
    return np.meshgrid(xs, ys)


def _field(shape, X, Y):
    """Returns (mask, tone) for one shape over the grid."""
    kind = shape["kind"]
    if kind == "disc":
        cx, cy = shape["at"]
        r = float(shape["r"])
        d = np.hypot(X - cx, Y - cy) / max(r, 1e-6)
        t0, t1 = shape["tone"]
        return d < 1.0, t0 + (t1 - t0) * d
    if kind == "ring":
        cx, cy = shape["at"]
        r, w = float(shape["r"]), float(shape["w"])
        ry = float(shape.get("ry", r))  # an ellipse when ry < r: a shockwave seen from the side
        d = np.hypot((X - cx), (Y - cy) * (r / max(ry, 1e-6)))
        inner = r - w / 2
        mask = (d >= inner) & (d < r + w / 2)
        t0, t1 = shape["tone"]
        return mask, t0 + (t1 - t0) * np.clip((d - inner) / max(w, 1e-6), 0, 1)
    if kind == "streak":
        fx, fy = shape["from"]
        a = math.radians(shape["angle"])
        length, w = float(shape["len"]), float(shape["w"])
        dx, dy = math.cos(a), math.sin(a)
        u = (X - fx) * dx + (Y - fy) * dy
        v = -(X - fx) * dy + (Y - fy) * dx
        p = np.clip(u / max(length, 1e-6), 0, 1)
        half = (w / 2) * (1 - p ** float(shape.get("taper", 1.5)))
        mask = (u >= 0) & (u <= length) & (np.abs(v) <= half)
        mask |= np.hypot(X - fx, Y - fy) <= w / 2  # a rounded base
        t0, t1 = shape["tone"]
        return mask, t0 + (t1 - t0) * p
    if kind == "chip":
        cx, cy = shape["at"]
        s = float(shape["s"]) / 2
        mask = (np.abs(X - cx) <= s) & (np.abs(Y - cy) <= s)
        return mask, np.full_like(X, float(shape["tone"]))
    if kind == "puff":
        cx, cy = shape["at"]
        discs = [(cx, cy, float(shape["r"]))] + [(cx + dx, cy + dy, float(r)) for dx, dy, r in shape.get("lobes", [])]
        best = np.full_like(X, np.inf)
        nx = np.zeros_like(X)
        ny = np.zeros_like(Y)
        for dcx, dcy, r in discs:
            d = np.hypot(X - dcx, Y - dcy) / max(r, 1e-6)
            closer = d < best
            best = np.where(closer, d, best)
            nx = np.where(closer, (X - dcx) / max(r, 1e-6), nx)
            ny = np.where(closer, (Y - dcy) / max(r, 1e-6), ny)
        mask = best < 1.0
        lx, ly = LIGHT
        norm = math.hypot(lx, ly)
        lit = np.clip(((nx * lx + ny * ly) / norm + 1.0) / 2.0, 0, 1)  # 1 = faces the light
        t_lit, t_dark = shape["tone"]
        return mask, t_lit + (t_dark - t_lit) * (1.0 - lit)
    raise ValueError(kind)


def render(effect, frame_index, palette, scale=1, quantize=None, only_ramp=None):
    """One frame of an effect as an RGBA image at `scale` still px per art px.
    `quantize` (default: scale == 1) rounds tones to ramp steps. `only_ramp`
    renders just the shapes on that ramp, so a family can be baked as its own
    layer with its own edge rule."""
    if quantize is None:
        quantize = scale == 1
    fw, fh = effect["frame"]
    X, Y = _grid(effect["frame"], effect["anchor"], scale)
    out = np.zeros((fh * scale, fw * scale, 4), dtype=np.float32)
    ramps = {name: ramp_rgb(names, palette) for name, names in effect["ramps"].items()}
    default_ramp = effect.get("default_ramp", next(iter(effect["ramps"])))
    floor = effect.get("floor")
    for shape in effect["frames"][frame_index]["shapes"]:
        ramp_name = shape.get("ramp", default_ramp)
        if only_ramp is not None and ramp_name != only_ramp:
            continue
        mask, tone = _field(shape, X, Y)
        if floor is not None:
            mask &= Y < floor
        rgb = tone_rgb(ramps[ramp_name], tone, quantize)
        out[mask, :3] = rgb[mask]
        out[mask, 3] = 255
    return Image.fromarray(np.clip(out, 0, 255).astype(np.uint8), "RGBA")


def palette_of(effect, palette):
    """{name: rgb} of every colour the effect may use: its ramps."""
    names = []
    for ramp in effect["ramps"].values():
        for n in ramp:
            if n not in names:
                names.append(n)
    return {n: tuple(palette[n]) for n in names}
