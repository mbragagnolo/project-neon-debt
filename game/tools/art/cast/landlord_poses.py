"""The Landlord's clips as rig poses (tools/art/rig.py bakes them).

Conventions as cast/dani_poses.py: degrees clockwise on screen, relative to
the still; he faces right, a hanging bone swings forward on a negative
angle, the torso leans forward on a positive one. Tall, still, expensive
(docs/art/cast.md): the idle barely moves, the run is long-legged and
upright, and every attack starts from stillness.

The rig has two coat tails (`coat_back`, `coat_front`) hung from the torso
so they swing against the legs; a `deck` part on the chest whose readout is
lit with a pose tint in the beam, the phase shift and all of phase two; and
two batons from one prop still: `baton` as drawn and `baton_lit`, the same
part recoloured to a magenta glow, swapped in with `hide` for the windup,
the slam windup and the beam.

Phase two (the coat off the shoulders, the chrome arms at full length) is a
part swap, not a second still: the arm parts exist twice, the `_p2` copies
recoloured from black sleeve to chrome, and every clip is baked twice, the
`p2_` set hiding the sleeved arms and lighting the deck. `landlord.gd`
plays the `p2_` clip when it has one and the phase is two.

Clips are the ones the boss states play: idle run windup lunge recover
stagger slam_windup beam phase dead (+ the p2_ set, minus phase).
Part names match cast/landlord.json `rig.parts`.
"""
import math

NEAR = ("leg_near_upper", "leg_near_lower", "foot_near")
FAR = ("leg_far_upper", "leg_far_lower", "foot_far")
ARM = ("arm_near_upper", "arm_near_lower", "hand_near")
FARM = ("arm_far_upper", "arm_far_lower", "hand_far")
ARMS_P1 = ARM + FARM
ARMS_P2 = tuple(p + "_p2" for p in ARMS_P1)
DECK_HOT = [1.9, 1.3, 1.8]


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


def arm(upper, lower, hand=0.0, near=True):
    u, l, h = ARM if near else FARM
    return {u: upper, l: lower, h: hand}


def coat(back, front):
    return {"coat_back": back, "coat_front": front}


def idle():
    """Four frames, a breath and the baton's tip drifting: he does not fidget."""
    frames = []
    for i in range(4):
        t = math.sin(2 * math.pi * i / 4)
        r = {"torso": 1.0 * t, "head": -0.6 * t}
        r.update(leg(-2, 3))
        r.update(leg(4, 3, near=False))
        r.update(arm(4 + 1.0 * t, -6 - 1.5 * t, 0, near=True))
        r.update(arm(-3 + 0.8 * t, -4 - 1.0 * t, 0, near=False))
        r.update(coat(-2 - 0.5 * t, 3 + 0.5 * t))
        r["baton"] = 0
        frames.append(pose(r))
    return {"frames": frames, "fps": 3.0, "loop": True, "grounded": True}


def run():
    """Six frames, long strides, upright; the coat tails swing against the
    legs, the baton stays down at his side."""
    frames = []
    n = 6
    lean = 8
    for i in range(n):
        ph = 2 * math.pi * i / n

        def thigh(p):
            return -38 * math.cos(p) if math.cos(p) > 0 else 32 * -math.cos(p)

        def shin(p):
            return 6 + 56 * max(0.0, math.sin(p))

        def foot(p, th, sh):
            return flat(th, sh, lean) + 24 * max(0.0, -math.sin(p))

        tn, sn = thigh(ph), shin(ph)
        tf, sf = thigh(ph + math.pi), shin(ph + math.pi)
        r = {"torso": lean, "head": -5}
        r.update(leg(tn, sn, foot(ph, tn, sn), near=True))
        r.update(leg(tf, sf, foot(ph + math.pi, tf, sf), near=False))
        r.update(arm(22 * math.cos(ph + math.pi), -30, 0, near=True))
        r.update(arm(22 * math.cos(ph), -35, 0, near=False))
        swing = 14 * math.cos(ph)
        r.update(coat(-16 - swing * 0.5, -6 + swing))
        r["baton"] = 10
        frames.append(pose(r))
    return {"frames": frames, "fps": 10.0, "loop": True, "grounded": True}


def windup():
    """The baton lights and comes up over the shoulder; two frames."""
    a = {"torso": -4, "head": 3}
    a.update(leg(-8, 12, torso=-4)); a.update(leg(10, 8, near=False, torso=-4))
    a.update(arm(110, -60, 0, near=True)); a.update(arm(-10, -20, 0, near=False))
    a.update(coat(-4, 4)); a["baton"] = -10
    b = {"torso": -8, "head": 6}
    b.update(leg(-12, 20, torso=-8)); b.update(leg(14, 14, near=False, torso=-8))
    b.update(arm(150, -40, 0, near=True)); b.update(arm(-16, -24, 0, near=False))
    b.update(coat(-6, 6)); b["baton"] = -20
    return {"frames": [pose(a, offset_art=(2, 0)), pose(b, offset_art=(3, 0))], "fps": 6.0, "loop": False, "grounded": True, "lit": True}


def lunge():
    """The strike: a long step and the baton straight out."""
    r = {"torso": 22, "head": -12}
    r.update(leg(-40, 24, torso=22)); r.update(leg(34, 10, near=False, torso=22))
    r.update(arm(-100, 4, 0, near=True)); r.update(arm(30, -30, 0, near=False))
    r.update(coat(-30, -20)); r["baton"] = 0
    return {"frames": [pose(r, offset_art=(-5, 0))], "fps": 0.0, "loop": False, "grounded": True, "lit": True}


def recover():
    r = {"torso": 14, "head": -8}
    r.update(leg(-24, 30, torso=14)); r.update(leg(22, 8, near=False, torso=14))
    r.update(arm(-50, 20, 0, near=True)); r.update(arm(20, -20, 0, near=False))
    r.update(coat(-16, -8)); r["baton"] = 30
    return {"frames": [pose(r, offset_art=(2, 0))], "fps": 0.0, "loop": False, "grounded": True}


def stagger():
    r = {"torso": -16, "head": -8}
    r.update(leg(-12, 18, torso=-16)); r.update(leg(12, 10, near=False, torso=-16))
    r.update(arm(-40, -50, 0, near=True)); r.update(arm(-30, -30, 0, near=False))
    r.update(coat(6, 10)); r["baton"] = 20
    return {"frames": [pose(r)], "fps": 0.0, "loop": False, "grounded": True}


def slam_windup():
    """Crouched, the lit baton raised high in both hands for the slam."""
    a = {"torso": 10, "head": -6}
    a.update(leg(-30, 50, torso=10)); a.update(leg(-24, 44, near=False, torso=10))
    a.update(arm(120, -30, 0, near=True)); a.update(arm(110, -30, 0, near=False))
    a.update(coat(-8, 8)); a["baton"] = -40
    b = {"torso": 16, "head": -10}
    b.update(leg(-38, 64, torso=16)); b.update(leg(-30, 56, near=False, torso=16))
    b.update(arm(160, -20, 0, near=True)); b.update(arm(150, -20, 0, near=False))
    b.update(coat(-10, 10)); b["baton"] = -60
    return {"frames": [pose(a), pose(b)], "fps": 5.0, "loop": False, "grounded": True, "lit": True}


def beam():
    """The repo beam: the near arm level, baton forward, deck hot."""
    r = {"torso": 6, "head": -4}
    r.update(leg(-14, 8, torso=6)); r.update(leg(16, 6, near=False, torso=6))
    r.update(arm(-92, 0, 0, near=True)); r.update(arm(12, -14, 0, near=False))
    r.update(coat(-6, 2)); r["baton"] = 0
    return {"frames": [pose(r, offset_art=(-3, 0), tint={"deck": DECK_HOT})], "fps": 0.0, "loop": False, "grounded": True, "lit": True, "hot": True}


def phase():
    """The shift: arms flung wide as the coat comes off the shoulders, the
    deck hot. The sleeved arms and the chrome arms are both in this frame:
    the sleeves hidden, the chrome shown, the tails flaring."""
    r = {"torso": -6, "head": -4}
    r.update(leg(-10, 6, torso=-6)); r.update(leg(12, 6, near=False, torso=-6))
    r.update(arm(-140, -30, 0, near=True)); r.update(arm(120, 30, 0, near=False))
    r.update(coat(24, -24)); r["baton"] = 0
    return {"frames": [pose(r, tint={"deck": DECK_HOT})], "fps": 0.0, "loop": False, "grounded": True, "p2_arms": True, "hot": True}


def dead():
    """On one knee, then down: a single frame, folded forward, the baton
    dropped, the deck dark."""
    r = {"torso": 60, "head": 20}
    r.update(leg(-60, 120, 30, near=True)); r.update(leg(-54, 114, 30, near=False))
    r.update(arm(-120, 10, 0, near=True)); r.update(arm(-110, 0, 0, near=False))
    r.update(coat(-40, -50)); r["baton"] = 70
    return {"frames": [pose(r, offset_art=(2, 0), tint={"deck": 0.5})], "fps": 0.0, "loop": False, "grounded": True}


def _finish(clip, phase2):
    """Fill in what every frame of a clip needs: the p2 arm copies posed like
    the p1 arms, one set hidden; the lit baton swapped in on `lit` clips;
    the deck hot through phase two."""
    lit = clip.pop("lit", False)
    hot = clip.pop("hot", False)
    p2_arms = clip.pop("p2_arms", False) or phase2
    for frame in clip["frames"]:
        rot = frame["rot"]
        for p in ARMS_P1:
            rot[p + "_p2"] = rot.get(p, 0.0)
        rot["baton_lit"] = rot.get("baton", 0.0)
        hide = set(frame.get("hide", ()))
        hide |= set(ARMS_P1) if p2_arms else set(ARMS_P2)
        hide.add("baton" if lit else "baton_lit")
        frame["hide"] = sorted(hide)
        if phase2 or hot:
            tint = dict(frame.get("tint", {}))
            tint.setdefault("deck", DECK_HOT)
            frame["tint"] = tint
    return clip


def clips(rig):
    makers = {
        "idle": idle, "run": run, "windup": windup, "lunge": lunge, "recover": recover,
        "stagger": stagger, "slam_windup": slam_windup, "beam": beam, "phase": phase, "dead": dead,
    }
    out = {name: _finish(make(), False) for name, make in makers.items()}
    for name, make in makers.items():
        if name != "phase":
            out["p2_" + name] = _finish(make(), True)
    return out
