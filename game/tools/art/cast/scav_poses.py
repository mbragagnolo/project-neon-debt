"""The Scav's clips as rig poses (tools/art/rig.py bakes them).

Same conventions as cast/dani_poses.py: degrees clockwise on screen, relative
to the part's rest in the still; he faces right, so a hanging bone (arm,
thigh) swings forward on a NEGATIVE angle and the torso leans forward on a
POSITIVE one. `offset_art` moves the whole figure in art pixels; grounded
clips ignore the vertical part because the bake plants the lowest foot.

The Scav is hunched (docs/art/cast.md): every grounded pose carries a
forward lean on the torso and the head tips back up to look ahead. The pipe
is a prop on the near hand with rest 90, so at angle 0 it continues the
forearm, business end outward; both arms hang forward-and-down so the pipe
is held low, in front, angled at the floor. The far hand is posed onto the
pipe rather than attached to it.

The clips are the ones `enemy_base.gd`'s states play: idle run windup
lunge recover stagger dead (stunned falls back to idle; a Scav is not
mechanical). The lunge is the full-body reach with the feet off the ground.

Part names match cast/scav.json `rig.parts`.
"""
import math

NEAR = ("leg_near_upper", "leg_near_lower", "foot_near")
FAR = ("leg_far_upper", "leg_far_lower", "foot_far")
ARM = ("arm_near_upper", "arm_near_lower", "hand_near")
FARM = ("arm_far_upper", "arm_far_lower", "hand_far")

HUNCH = 14  # torso lean of the resting Scav


def pose(rot=None, offset_art=(0, 0)):
    return {"rot": dict(rot or {}), "offset_art": tuple(offset_art)}


def flat(thigh, shin, torso=0.0):
    return -(torso + thigh + shin)


def leg(thigh, shin, foot=None, near=True, torso=0.0):
    u, l, f = NEAR if near else FAR
    return {u: thigh, l: shin, f: flat(thigh, shin, torso) if foot is None else foot}


def arm(upper, lower, hand=0.0, near=True):
    u, l, h = ARM if near else FARM
    return {u: upper, l: lower, h: hand}


def body(lean, head=None):
    return {"torso": lean, "head": -lean * 0.7 if head is None else head}


def idle():
    """Four frames of breathing under the hunch: the pipe rises and falls
    with the shoulders."""
    frames = []
    for i in range(4):
        t = math.sin(2 * math.pi * i / 4)
        r = body(HUNCH + 1.5 * t)
        r.update(leg(-4, 8, torso=HUNCH))
        r.update(leg(6, 6, near=False, torso=HUNCH))
        r.update(arm(-38 + 2 * t, -14 - 3 * t, 0, near=True))
        r.update(arm(-30 + 1.5 * t, -18 - 2 * t, 0, near=False))
        r["pipe"] = 8
        frames.append(pose(r))
    return {"frames": frames, "fps": 4.0, "loop": True, "grounded": True}


def run():
    """Six frames, Dani's cycle with a deeper lean and the arms kept on the
    pipe instead of pumping: a rusher, low and committed."""
    frames = []
    n = 6
    lean = 24
    for i in range(n):
        ph = 2 * math.pi * i / n

        def thigh(p):
            return -40 * math.cos(p) if math.cos(p) > 0 else 36 * -math.cos(p)

        def shin(p):
            return 8 + 62 * max(0.0, math.sin(p))

        def foot(p, th, sh):
            return flat(th, sh, lean) + 28 * max(0.0, -math.sin(p))

        tn, sn = thigh(ph), shin(ph)
        tf, sf = thigh(ph + math.pi), shin(ph + math.pi)
        r = body(lean, head=-16)
        r.update(leg(tn, sn, foot(ph, tn, sn), near=True))
        r.update(leg(tf, sf, foot(ph + math.pi, tf, sf), near=False))
        bob = 4 * math.cos(2 * ph)
        r.update(arm(-50 + bob, -30, 0, near=True))
        r.update(arm(-42 + bob, -34, 0, near=False))
        r["pipe"] = 20
        frames.append(pose(r))
    return {"frames": frames, "fps": 12.0, "loop": True, "grounded": True}


def windup():
    """The tell: he sinks, the pipe goes back over the far shoulder, the
    near foot stays planted to push off from. Two frames so the state tint
    has a pose to agree with as the crouch deepens."""
    a = body(-4, head=6)
    a.update(leg(-14, 26, torso=-4))
    a.update(leg(18, 22, near=False, torso=-4))
    a.update(arm(130, -50, 0, near=True))
    a.update(arm(120, -60, 0, near=False))
    a["pipe"] = -20
    b = body(-8, head=10)
    b.update(leg(-18, 34, torso=-8))
    b.update(leg(22, 30, near=False, torso=-8))
    b.update(arm(150, -45, 0, near=True))
    b.update(arm(140, -55, 0, near=False))
    b["pipe"] = -30
    return {"frames": [pose(a, offset_art=(4, 0)), pose(b, offset_art=(5, 0))], "fps": 8.0, "loop": False, "grounded": True}


def lunge():
    """The overcommit: the whole body reaching with the pipe, feet off the
    ground (grounded: false), the trailing leg kicked back."""
    r = body(38, head=-22)
    r.update(leg(-46, 30, 30, near=True))
    r.update(leg(40, 40, 40, near=False))
    r.update(arm(-130, -10, 0, near=True))
    r.update(arm(-120, -20, 0, near=False))
    r["pipe"] = -8
    return {"frames": [pose(r, offset_art=(3, -4))], "fps": 0.0, "loop": False, "grounded": False}


def recover():
    """Folded over the swing, the pipe dragging on the floor, the near leg
    braced forward: the punish window."""
    r = body(48, head=-26)
    r.update(leg(-30, 40, torso=48))
    r.update(leg(24, 14, near=False, torso=48))
    r.update(arm(-70, 20, 0, near=True))
    r.update(arm(-60, 10, 0, near=False))
    r["pipe"] = 40
    return {"frames": [pose(r, offset_art=(2, 0))], "fps": 0.0, "loop": False, "grounded": True}


def stagger():
    r = body(-24, head=-12)
    r.update(leg(-16, 24, torso=-24))
    r.update(leg(16, 14, near=False, torso=-24))
    r.update(arm(-60, -50, 0, near=True))
    r.update(arm(-45, -40, 0, near=False))
    r["pipe"] = 10
    return {"frames": [pose(r)], "fps": 0.0, "loop": False, "grounded": True}


def dead():
    """Face down, head forward, the pipe dropped alongside. The torso turns
    ninety degrees so the legs trail behind; the bake still plants the
    lowest foot, which is now a heel, so the body lies on the floor line."""
    r = body(88, head=-30)
    r.update(leg(4, 6, 20, near=True))
    r.update(leg(-10, 14, 24, near=False))
    r.update(arm(-150, 30, 0, near=True))
    r.update(arm(-40, -20, 0, near=False))
    r["pipe"] = 60
    return {"frames": [pose(r, offset_art=(0, 0))], "fps": 0.0, "loop": False, "grounded": True}


def clips(rig):
    return {
        "idle": idle(),
        "run": run(),
        "windup": windup(),
        "lunge": lunge(),
        "recover": recover(),
        "stagger": stagger(),
        "dead": dead(),
    }
