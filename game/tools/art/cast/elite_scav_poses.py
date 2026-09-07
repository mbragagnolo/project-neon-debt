"""The Elite Scav's clips: the Scav's poses on the Scav's rig (docs/art/cast.md:
identical silhouette, same moveset). What differs is the idle, where he stands
straighter and hunches only to lunge, and the weapon part's name (`weapon`, a
rebar cutter still, where the Scav's is `pipe`)."""
import math

from cast import scav_poses as S


def idle():
    """Straighter than the Scav: half the hunch, the cutter held lower and
    steadier."""
    frames = []
    for i in range(4):
        t = math.sin(2 * math.pi * i / 4)
        r = S.body(6 + 1.2 * t)
        r.update(S.leg(-2, 4, torso=6))
        r.update(S.leg(4, 4, near=False, torso=6))
        r.update(S.arm(-30 + 1.5 * t, -10 - 2 * t, 0, near=True))
        r.update(S.arm(-24 + 1.0 * t, -14 - 1.5 * t, 0, near=False))
        r["pipe"] = -24
        frames.append(S.pose(r))
    return {"frames": frames, "fps": 4.0, "loop": True, "grounded": True}


def lunge():
    """The Scav's dive with the cutter dipped: it reaches 20 art px past the
    hand where the pipe reaches 13, so held straight out it left the frame."""
    clip = S.lunge()
    for frame in clip["frames"]:
        frame["rot"]["pipe"] = 58
        frame["offset_art"] = (-7, -4)
    return clip


def _rename(clip):
    for frame in clip["frames"]:
        if "pipe" in frame["rot"]:
            frame["rot"]["weapon"] = frame["rot"].pop("pipe")
    return clip


def clips(rig):
    out = S.clips(rig)
    out["idle"] = idle()
    out["lunge"] = lunge()
    for frame in out["run"]["frames"]:
        frame["rot"]["pipe"] = -4  # the longer tool carried level, off the floor
    return {name: _rename(clip) for name, clip in out.items()}
