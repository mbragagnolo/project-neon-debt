"""Stitch's clips (tools/art/rig.py bakes them): seated, four parts.

Degrees clockwise on screen relative to the still; he faces right, so a
positive torso angle is a lean toward the player. `idle` breathes; `talk`
leans in with the flesh arm coming up off the counter to make a point,
which is all the look sheet asks of him (docs/art/cast.md). Nothing is
grounded: he sits, and the still's floor line is the bake's floor.
Part names match cast/stitch.json `rig.parts`.
"""
import math


def pose(rot=None, offset_art=(0, 0)):
    return {"rot": dict(rot or {}), "offset_art": tuple(offset_art)}


def idle():
    frames = []
    for i in range(4):
        t = math.sin(2 * math.pi * i / 4)
        r = {"torso": 1.2 * t, "head": -1.0 * t, "arm_near": -0.6 * t, "arm_far": -0.8 * t}
        frames.append(pose(r, offset_art=(0, round(0.6 * t))))
    return {"frames": frames, "fps": 2.0, "loop": True, "grounded": False}


def talk():
    a = {"torso": 5, "head": -4, "arm_near": -2, "arm_far": -14}
    b = {"torso": 3, "head": 2, "arm_near": -1, "arm_far": -26}
    return {"frames": [pose(a, offset_art=(1, 0)), pose(b, offset_art=(1, 0))], "fps": 4.0, "loop": True, "grounded": False}


def clips(rig):
    return {"idle": idle(), "talk": talk()}
