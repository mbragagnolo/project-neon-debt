"""The Riot unit's clips as rig poses (tools/art/rig.py bakes them).

Conventions as cast/dani_poses.py: degrees clockwise on screen, relative to
the still; it faces right, so a hanging bone swings forward on a negative
angle and the torso leans forward on a positive one.

The shield is not on this rig: it is its own sheet and its own node
(riot.tscn Facing/Shield, cast/riot_shield.json), fixed in front of the
body. So the bash is told by the chassis: the windup rocks the frame back
and pulls the near arm in (the shield drawn back), the lunge drives the
whole frame forward with the near forearm punched out. The near arm is
posed as if holding the shield: forearm forward, level, all the time.

The amber lamp is its own part (`lamp`, on the near shoulder) so a pose can
light it with `tint`: it blinks in idle and stays lit through the windup
(docs/art/cast.md). Stunned sags at the knees with the visor (the head)
darkened.

Clips are the ones enemy_base.gd plays: idle run windup lunge recover
stagger stunned dead. Part names match cast/riot.json `rig.parts`.
"""
import math

NEAR = ("leg_near_upper", "leg_near_lower", "foot_near")
FAR = ("leg_far_upper", "leg_far_lower", "foot_far")
ARM = ("arm_near_upper", "arm_near_lower")
FARM = ("arm_far_upper", "arm_far_lower")

LAMP_ON = 1.6
LAMP_OFF = 0.55


def pose(rot=None, offset_art=(0, 0), tint=None, hide=None):
    out = {"rot": dict(rot or {}), "offset_art": tuple(offset_art)}
    if tint:
        out["tint"] = dict(tint)
    if hide:
        out["hide"] = list(hide)
    return out


def flat(thigh, shin, torso=0.0):
    return -(torso + thigh + shin)


def leg(thigh, shin, foot=None, near=True, torso=0.0):
    u, l, f = NEAR if near else FAR
    return {u: thigh, l: shin, f: flat(thigh, shin, torso) if foot is None else foot}


def arm(upper, lower, near=True):
    u, l = ARM if near else FARM
    return {u: upper, l: lower}


def shield_arm(t=0.0):
    """The near arm holding the shield: forearm forward and level."""
    return arm(-18 + t, -72 - t, near=True)


def idle():
    """Four frames, a slow settle; the lamp blinks on frames 0 and 1."""
    frames = []
    lean = 6
    for i in range(4):
        t = math.sin(2 * math.pi * i / 4)
        r = {"torso": lean + 1.0 * t, "head": -0.5 * t}
        r.update(leg(-4, 8, torso=lean))
        r.update(leg(6, 6, near=False, torso=lean))
        r.update(shield_arm(1.5 * t))
        r.update(arm(4 + 1.5 * t, -6 - 2 * t, near=False))
        frames.append(pose(r, tint={"lamp": LAMP_ON if i < 2 else LAMP_OFF}))
    return {"frames": frames, "fps": 3.0, "loop": True, "grounded": True}


def run():
    """Six frames of a planted walk with a forward lean: short strides, the
    shield arm held steady, the far arm swinging."""
    frames = []
    n = 6
    lean = 14
    for i in range(n):
        ph = 2 * math.pi * i / n

        def thigh(p):
            return -26 * math.cos(p) if math.cos(p) > 0 else 24 * -math.cos(p)

        def shin(p):
            return 6 + 44 * max(0.0, math.sin(p))

        def foot(p, th, sh):
            return flat(th, sh, lean) + 18 * max(0.0, -math.sin(p))

        tn, sn = thigh(ph), shin(ph)
        tf, sf = thigh(ph + math.pi), shin(ph + math.pi)
        r = {"torso": lean, "head": -6}
        r.update(leg(tn, sn, foot(ph, tn, sn), near=True))
        r.update(leg(tf, sf, foot(ph + math.pi, tf, sf), near=False))
        r.update(shield_arm(3 * math.cos(ph)))
        r.update(arm(22 * math.cos(ph), -40, near=False))
        frames.append(pose(r, tint={"lamp": LAMP_ON if i % 3 == 0 else LAMP_OFF}))
    return {"frames": frames, "fps": 8.0, "loop": True, "grounded": True}


def windup():
    """The shield drawn back: the frame rocks onto its heels, the near arm
    pulls in and up, the lamp stays lit."""
    a = {"torso": -8, "head": 4}
    a.update(leg(-10, 16, torso=-8))
    a.update(leg(14, 12, near=False, torso=-8))
    a.update(arm(24, -110, near=True))
    a.update(arm(30, -20, near=False))
    b = {"torso": -14, "head": 8}
    b.update(leg(-14, 24, torso=-14))
    b.update(leg(18, 18, near=False, torso=-14))
    b.update(arm(40, -120, near=True))
    b.update(arm(38, -24, near=False))
    return {"frames": [pose(a, offset_art=(-2, 0), tint={"lamp": LAMP_ON}), pose(b, offset_art=(-3, 0), tint={"lamp": LAMP_ON})],
            "fps": 6.0, "loop": False, "grounded": True}


def lunge():
    """The whole frame behind the shield: a deep forward lean, the near
    forearm punched straight out, the trailing leg driving."""
    r = {"torso": 26, "head": -10}
    r.update(leg(-34, 22, torso=26))
    r.update(leg(30, 8, near=False, torso=26))
    r.update(arm(-70, -30, near=True))
    r.update(arm(50, -40, near=False))
    return {"frames": [pose(r, offset_art=(4, 0), tint={"lamp": LAMP_ON})], "fps": 0.0, "loop": False, "grounded": True}


def recover():
    r = {"torso": 18, "head": -8}
    r.update(leg(-22, 30, torso=18))
    r.update(leg(20, 10, near=False, torso=18))
    r.update(arm(-30, -50, near=True))
    r.update(arm(30, -30, near=False))
    return {"frames": [pose(r, offset_art=(2, 0), tint={"lamp": LAMP_OFF})], "fps": 0.0, "loop": False, "grounded": True}


def stagger():
    r = {"torso": -18, "head": -8}
    r.update(leg(-14, 20, torso=-18))
    r.update(leg(12, 12, near=False, torso=-18))
    r.update(arm(-40, -60, near=True))
    r.update(arm(-30, -30, near=False))
    return {"frames": [pose(r, offset_art=(-2, 0), tint={"lamp": LAMP_OFF})], "fps": 0.0, "loop": False, "grounded": True}


def stunned():
    """Sagging at the knees, the visor dark, the lamp out."""
    r = {"torso": 14, "head": 10}
    r.update(leg(-34, 62, torso=14))
    r.update(leg(-26, 56, near=False, torso=14))
    r.update(arm(-6, -40, near=True))
    r.update(arm(10, -10, near=False))
    return {"frames": [pose(r, tint={"lamp": LAMP_OFF, "head": 0.6})], "fps": 0.0, "loop": False, "grounded": True}


def dead():
    """Down on the knees, folded forward over them, everything dark."""
    r = {"torso": 70, "head": 20}
    r.update(leg(-70, 130, 30, near=True))
    r.update(leg(-64, 124, 30, near=False))
    r.update(arm(-110, 10, near=True))
    r.update(arm(-100, 0, near=False))
    return {"frames": [pose(r, offset_art=(2, 0), tint={"lamp": LAMP_OFF, "head": 0.5})], "fps": 0.0, "loop": False, "grounded": True}


def clips(rig):
    return {
        "idle": idle(),
        "run": run(),
        "windup": windup(),
        "lunge": lunge(),
        "recover": recover(),
        "stagger": stagger(),
        "stunned": stunned(),
        "dead": dead(),
    }
