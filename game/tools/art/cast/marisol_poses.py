"""Marisol's clips (tools/art/rig.py bakes them): five parts, standing.

Degrees clockwise on screen relative to the still; she faces right. `idle`
breathes with the arms folded; `talk` unfolds the near forearm from the
elbow to point ahead (a large negative angle swings it up and forward) and
brings it back, as docs/art/cast.md describes the quest hand-off.
Part names match cast/marisol.json `rig.parts`.
"""
import math


def pose(rot=None, offset_art=(0, 0)):
    return {"rot": dict(rot or {}), "offset_art": tuple(offset_art)}


def idle():
    frames = []
    for i in range(4):
        t = math.sin(2 * math.pi * i / 4)
        r = {"torso": 1.0 * t, "head": -0.8 * t, "hand_point": 0, "skirt": -0.6 * t}
        frames.append(pose(r))
    return {"frames": frames, "fps": 2.0, "loop": True, "grounded": True}


def talk():
    a = {"torso": 3, "head": -3, "hand_point": -150, "skirt": -2}
    b = {"torso": 2, "head": -1, "hand_point": -132, "skirt": -1}
    return {"frames": [pose(a, offset_art=(1, 0)), pose(b, offset_art=(1, 0))], "fps": 3.0, "loop": True, "grounded": True}


def clips(rig):
    return {"idle": idle(), "talk": talk()}
