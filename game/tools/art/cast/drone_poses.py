"""The Watcher drone's clips as rig poses (tools/art/rig.py bakes them).

Not humanoid: four parts, body (root), rotor, lens, mast, all hung from
the body. Degrees clockwise on screen; the drone faces right, so a positive
body angle tips the nose down. Nothing is grounded: every clip has
`grounded: false` and the body's rest height is where the still put it.

The rotor is the one part that animates: it wobbles a few degrees each frame
in the hover so the blur reads as motion at 8 fps. Aim tips the body toward
the target and brightens the lens (a per-pose `tint`); stunned stops the
rotor and drops the drone nose-first; dead is the same, further, lower.
The clips are the ones `enemy_base.gd`'s flier states play: idle hover aim
stagger stunned dead (Track plays hover, Stagger plays stagger).

Part names match cast/drone.json `rig.parts`.
"""
import math


def pose(rot=None, offset_art=(0, 0), tint=None, hide=None):
    out = {"rot": dict(rot or {}), "offset_art": tuple(offset_art)}
    if tint:
        out["tint"] = dict(tint)
    if hide:
        out["hide"] = list(hide)
    return out


def hover():
    """Four frames: the body bobs a pixel, the rotor wobbles, the lens
    flickers a step."""
    frames = []
    for i in range(4):
        t = math.sin(2 * math.pi * i / 4)
        r = {"body": 1.5 * t, "rotor": 6 * math.sin(2 * math.pi * i / 2 + 0.6), "lens": 0, "mast": -1.0 * t}
        frames.append(pose(r, offset_art=(0, round(-1.2 * t)), tint={"lens": 1.0 + 0.25 * max(0.0, t)}))
    return {"frames": frames, "fps": 8.0, "loop": True, "grounded": False}


def aim():
    """Nose toward the target, lens hot, camera mast tipped at the player."""
    r = {"body": 12, "rotor": 0, "lens": 0, "mast": -14}
    return {"frames": [pose(r, offset_art=(1, -1), tint={"lens": [1.8, 1.4, 1.4]})], "fps": 0.0, "loop": False, "grounded": False}


def stagger():
    r = {"body": -10, "rotor": 8, "lens": 0, "mast": 6}
    return {"frames": [pose(r, offset_art=(-2, -1))], "fps": 0.0, "loop": False, "grounded": False}


def stunned():
    """Rotor stopped, dropping nose-first, lens dark."""
    r = {"body": 30, "rotor": 0, "lens": 0, "mast": 0}
    return {"frames": [pose(r, offset_art=(-2, -3), tint={"lens": 0.35, "rotor": 0.8})], "fps": 0.0, "loop": False, "grounded": False}


def dead():
    r = {"body": 46, "rotor": 0, "lens": 0, "mast": 0}
    return {"frames": [pose(r, offset_art=(-3, -2), tint={"lens": 0.25, "rotor": 0.7, "body": 0.85})], "fps": 0.0, "loop": False, "grounded": False}


def clips(rig):
    h = hover()
    return {
        "idle": h,
        "hover": {**h, "frames": [dict(f) for f in h["frames"]]},
        "aim": aim(),
        "stagger": stagger(),
        "stunned": stunned(),
        "dead": dead(),
    }
