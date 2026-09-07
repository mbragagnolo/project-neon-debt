"""Dani's clips as rig poses (tools/art/rig.py bakes them).

Angles are degrees, clockwise on screen, relative to the part's rest
orientation in the still. She faces right, so for a bone that hangs down
(thighs, arms) a NEGATIVE angle swings it forward and for the torso, which
points up, a POSITIVE angle is a forward lean. `offset_art` moves the whole
figure in art pixels (positive y is down); grounded clips ignore vertical
offsets because the bake plants the lowest foot on the floor line itself.

Feet: a foot's angle is relative to its shin, so `flat(thigh, shin)` is the
foot angle that keeps the sole level with the floor.

Weapon: the wrench is a prop hung from the near hand with rest 90, so at
angle 0 it continues the forearm, head outward (hanging arm: head down,
as the look sheet wants; strike: straight out). A positive angle dips the
head below the forearm line, the loose grip of the run.

Part names match cast/dani.json `rig.parts`.
"""
import math

NEAR = ("leg_near_upper", "leg_near_lower", "foot_near")
FAR = ("leg_far_upper", "leg_far_lower", "foot_far")
ARM = ("arm_near_upper", "arm_near_lower")
FARM = ("arm_far_upper", "arm_far_lower")


def pose(rot=None, offset_art=(0, 0)):
    return {"rot": dict(rot or {}), "offset_art": tuple(offset_art)}


def flat(thigh, shin, torso=0.0):
    """Foot angle that cancels the leg's (and the torso's, which carries the
    legs) rotation so the sole stays level."""
    return -(torso + thigh + shin)


def leg(thigh, shin, foot=None, near=True, torso=0.0):
    u, l, f = NEAR if near else FAR
    return {u: thigh, l: shin, f: flat(thigh, shin, torso) if foot is None else foot}


def arm(upper, lower, near=True):
    u, l = ARM if near else FARM
    return {u: upper, l: lower}


def idle():
    frames = []
    for i in range(4):
        t = math.sin(2 * math.pi * i / 4)
        r = {"torso": 1.5 * t, "head": -1.0 * t}
        r.update(leg(0, 0))
        r.update(leg(0, 0, near=False))
        r.update(arm(2.0 * t, -3.0 * t))
        r.update(arm(1.5 * t, -2.0 * t, near=False))
        frames.append(pose(r))
    return {"frames": frames, "fps": 4.0, "loop": True, "grounded": True}


def run():
    """Six-frame run. Frame 0 is the near foot's contact: that leg is nearly
    straight and reaching forward, the far leg is folded behind. The shin
    folds on the back-to-front swing only, and the foot points down as the
    leg leaves the ground. Ground contact comes from the bake, which plants
    the lowest foot each frame, so the body rises at the passing frames and
    drops on contact by itself."""
    frames = []
    n = 6
    for i in range(n):
        ph = 2 * math.pi * i / n
        # Thigh: -36 (reaching forward) .. +34 (driven back).
        def thigh(p):
            return -36 * math.cos(p) if math.cos(p) > 0 else 34 * -math.cos(p)
        # Shin: near-straight on contact, folded while swinging forward.
        def shin(p):
            return 6 + 58 * max(0.0, math.sin(p))
        # Foot: level on and around contact, toes down on the back swing.
        def foot(p, th, sh):
            return flat(th, sh, 12) + 28 * max(0.0, -math.sin(p))
        tn, sn = thigh(ph), shin(ph)
        tf, sf = thigh(ph + math.pi), shin(ph + math.pi)
        r = {"torso": 12, "head": -7}
        r.update(leg(tn, sn, foot(ph, tn, sn), near=True))
        r.update(leg(tf, sf, foot(ph + math.pi, tf, sf), near=False))
        # Arms pump opposite the legs, elbows at ninety.
        r.update(arm(30 * math.cos(ph + math.pi), -85, near=True))
        r.update(arm(30 * math.cos(ph), -80, near=False))
        r["weapon"] = 55
        frames.append(pose(r))
    return {"frames": frames, "fps": 12.0, "loop": True, "grounded": True}


def jump():
    r = {"torso": 6, "head": -4}
    r.update(leg(-45, 65, 22, near=True))
    r.update(leg(15, 45, 30, near=False))
    r.update(arm(-55, -60, near=True))
    r.update(arm(-35, -40, near=False))
    r["weapon"] = 0
    return {"frames": [pose(r, offset_art=(0, 3))], "fps": 0.0, "loop": False, "grounded": False}


def fall():
    r = {"torso": -6, "head": 4}
    r.update(leg(-22, 20, 10, near=True))
    r.update(leg(24, 12, 25, near=False))
    r.update(arm(-140, -25, near=True))
    r.update(arm(-125, -20, near=False))
    r["weapon"] = 0
    return {"frames": [pose(r, offset_art=(0, 1))], "fps": 0.0, "loop": False, "grounded": False}


def wall():
    r = {"torso": 12, "head": -8}
    r.update(leg(-30, 70, -10, near=True))
    r.update(leg(-18, 60, -5, near=False))
    r.update(arm(-160, -10, near=True))
    r.update(arm(20, -30, near=False))
    r["weapon"] = 0
    return {"frames": [pose(r, offset_art=(0, 2))], "fps": 0.0, "loop": False, "grounded": False}


def dash():
    r = {"torso": 26, "head": -12}
    r.update(leg(22, 10, near=True, torso=26))
    r.update(leg(-52, 22, 20, near=False))
    r.update(arm(58, -25, near=True))
    r.update(arm(44, -20, near=False))
    r["weapon"] = 0
    return {"frames": [pose(r)], "fps": 0.0, "loop": False, "grounded": True}


def attack():
    wind = {"torso": -8, "head": 5}
    wind.update(leg(-10, 12, near=True, torso=-8)); wind.update(leg(12, 10, near=False, torso=-8))
    wind.update(arm(150, -35, near=True)); wind.update(arm(-20, -30, near=False))
    wind["weapon"] = 0
    strike = {"torso": 16, "head": -9}
    strike.update(leg(-22, 16, near=True, torso=16)); strike.update(leg(18, 12, near=False, torso=16))
    strike.update(arm(-95, 5, near=True)); strike.update(arm(25, -35, near=False))
    strike["weapon"] = 0
    follow = {"torso": 20, "head": -11}
    follow.update(leg(-22, 16, near=True, torso=20)); follow.update(leg(18, 12, near=False, torso=20))
    follow.update(arm(-120, 30, near=True)); follow.update(arm(30, -30, near=False))
    follow["weapon"] = 30
    return {"frames": [pose(wind), pose(strike, offset_art=(1, 0)), pose(follow, offset_art=(1, 0))],
            "fps": 18.0, "loop": False, "grounded": True}


def hurt():
    r = {"torso": -22, "head": -14}
    r.update(leg(-18, 25, near=True, torso=-22))
    r.update(leg(14, 15, near=False, torso=-22))
    r.update(arm(-65, -40, near=True))
    r.update(arm(-50, -30, near=False))
    r["weapon"] = 0
    return {"frames": [pose(r)], "fps": 0.0, "loop": False, "grounded": True}


def clips(rig):
    return {
        "idle": idle(),
        "run": run(),
        "jump": jump(),
        "fall": fall(),
        "dash": dash(),
        "wall": wall(),
        "attack": attack(),
        "hurt": hurt(),
    }
