"""The first three effects, authored from arithmetic and written as json:
a hit spark (hot), a landing puff (dust), a death burst (hot + dust).
Copy this into the project's studio (vfx/effects.py), set the sheets,
the actors and the sizes from the project's figures, run it, then bake.

    python vfx/effects.py --studio art        # writes art/vfx/spark_hit.json, dust_land.json, burst_die.json

Sizes come from the figure: on the first project Dani is 56 art px tall,
the wrench's box 36 art px square, the Scav 50 tall; the spark is about
the hitbox, the dust under the feet about 0.8 of the figure's height wide,
the burst's wave about the figure's height. Timing is against the engine:
60 Hz, hitstop holds the first frame two to four frames on top of its own
duration, so the first frame is the impact and the biggest and the decay
is longer than it. Nothing anticipates: the trigger is the impact
(reference/timing.md).

Two families share the shapes (reference/families.md): `hot` (spark,
burst, white to rust) and `dust` (landing, the burst's smoke, steel4 to
steel1). The burst uses both and bakes them as layers.
"""
import argparse
import json
import math
import os
import sys

HOT = ["white", "warm", "amber", "sodium", "rust2", "rust1"]
DUST = ["steel4", "steel3", "steel2", "steel1"]

# The actors the effects fire over, for the strips: the engine's sheets
# (pre-scaled) with the clip on screen at the trigger. Edit per project.
PLAYER = {"sheet": "../../assets/sprites/player.png", "frame": [96, 128], "scale": 2}
TARGET = {"sheet": "../../assets/sprites/scav.png", "frame": [120, 112], "scale": 2}
ATTACK = [14, 3, 18.0, False]
IDLE = [0, 4, 4.0, True]
TARGET_IDLE = [0, 4, 4.0, True]
TARGET_DEAD = [15, 1, 0.0, False]
TARGET_CENTRE_DY = -20   # the target's centre above its feet, art px
SHEETS = "../../assets/fx"


def d(angle):
    a = math.radians(angle)
    return math.cos(a), math.sin(a)


def at(angle, dist, dy=0.0):
    x, y = d(angle)
    return [round(x * dist, 2), round(y * dist + dy, 2)]


def puff(x, y, r, tone, sign=1, ramp="dust"):
    """A dust clump: a main disc with three satellites, wider than tall."""
    return {"kind": "puff", "ramp": ramp, "at": [x, y], "r": r, "tone": tone,
            "lobes": [[round(0.85 * r * sign, 2), round(0.1 * r, 2), round(0.7 * r, 2)],
                      [round(-0.6 * r * sign, 2), round(0.15 * r, 2), round(0.6 * r, 2)],
                      [round(0.3 * r * sign, 2), round(-0.55 * r, 2), round(0.5 * r, 2)]]}


def spark_hit():
    """damage_dealt, at the target's centre. A star: small white core,
    short corona, nine rays of uneven length biased away from the attacker
    (right) and up; the rays detach into chips that fall. 6 at 30 fps."""
    rays = [(-135, 9), (-105, 13), (-80, 10), (-55, 15), (-30, 11), (-5, 16), (20, 12), (45, 9), (165, 6)]
    frames = [
        {"shapes": [
            {"kind": "disc", "at": [0, 0], "r": 5.0, "tone": [0.7, 2.6]},
            *[{"kind": "streak", "from": [0, 0], "angle": a, "len": L, "w": 2.6, "taper": 1.2, "tone": [0.5, 3.2]} for a, L in rays],
            {"kind": "disc", "at": [0, 0], "r": 2.6, "tone": [0.0, 0.5]}]},
        {"shapes": [
            {"kind": "disc", "at": [0, 0], "r": 3.5, "tone": [1.0, 2.8]},
            *[{"kind": "streak", "from": at(a, 4), "angle": a, "len": L * 0.85, "w": 2.0, "taper": 1.2, "tone": [1.4, 3.8]} for a, L in rays],
            {"kind": "disc", "at": [0, 0], "r": 1.6, "tone": [0.0, 1.0]}]},
        {"shapes": [
            {"kind": "disc", "at": [0, 0.3], "r": 1.8, "tone": [1.5, 3.0]},
            *[{"kind": "streak", "from": at(a, L * 0.6, 0.5), "angle": a, "len": L * 0.45, "w": 1.6, "tone": [2.2, 4.4]} for a, L in rays],
            *[{"kind": "chip", "at": at(a, L * 1.1, 0.8), "s": 1.8, "tone": 2.4} for a, L in rays]]},
        {"shapes": [
            *[{"kind": "streak", "from": at(a, L * 0.95, 1.8), "angle": a, "len": L * 0.25, "w": 1.3, "tone": [3.0, 4.6]} for a, L in rays[1::2]],
            *[{"kind": "chip", "at": at(a, L * 1.3, 2.8), "s": 1.8, "tone": 3.2} for a, L in rays]]},
        {"shapes": [{"kind": "chip", "at": at(a, L * 1.45, 5.0), "s": 1.5, "tone": 4.0} for a, L in rays[:6]]},
        {"shapes": [{"kind": "chip", "at": at(a, L * 1.55, 8.0), "s": 1.2, "tone": 4.8} for a, L in rays[1:4]]},
    ]
    return {"name": "spark_hit", "family": "hot", "trigger": "damage_dealt (target not the player), at the target's centre",
            "frame": [32, 32], "anchor": [16, 16], "fps": 30, "scale": 2, "sheet": f"{SHEETS}/spark_hit.png",
            "ramps": {"hot": HOT}, "default_ramp": "hot", "edge": {"hot": "none"},
            "strip": {"cell": [80, 72], "feet": [32, 60], "at": [30, TARGET_CENTRE_DY], "lineup_frame": 0, "ground": "bg1", "floor": "bg2",
                      "actors": [dict(PLAYER, clip=ATTACK, clip_name="attack", at=[0, 0]),
                                 dict(TARGET, clip=TARGET_IDLE, clip_name="idle", at=[30, 0], flip=True)]},
            "frames": frames}


def dust_land():
    """player land, at the feet. Two low clumps kicked out along the floor,
    hugging it, breaking into smaller clumps and specks as they thin.
    Left and right differ a little. 6 at 20 fps."""
    frames = [
        {"shapes": [puff(-5.0, -2.4, 3.6, [0.0, 1.8], -1), puff(5.5, -2.6, 4.0, [0.0, 1.8], 1), puff(0.0, -1.2, 2.4, [0.4, 2.0], 1)]},
        {"shapes": [puff(-9.0, -3.0, 4.2, [0.2, 2.2], -1), puff(10.0, -3.4, 4.6, [0.2, 2.2], 1), puff(0.5, -1.5, 2.6, [0.8, 2.4], 1)]},
        {"shapes": [puff(-13.0, -3.6, 4.0, [0.6, 2.6], -1), puff(14.0, -4.0, 4.4, [0.6, 2.6], 1),
                    puff(-7.0, -1.6, 1.8, [1.5, 2.8], -1), puff(8.0, -1.8, 2.0, [1.5, 2.8], 1)]},
        {"shapes": [puff(-16.5, -4.4, 3.4, [1.0, 2.9], -1), puff(17.5, -5.0, 3.8, [1.0, 2.9], 1),
                    puff(-10.0, -2.0, 1.6, [1.8, 3.0], -1), puff(11.0, -2.2, 1.7, [1.8, 3.0], 1),
                    {"kind": "chip", "at": [-13.0, -8.0], "s": 1.0, "tone": 1.5}, {"kind": "chip", "at": [14.5, -8.5], "s": 1.0, "tone": 1.5}]},
        {"shapes": [puff(-19.0, -5.4, 2.6, [1.6, 3.0], -1), puff(20.0, -6.2, 3.0, [1.6, 3.0], 1),
                    {"kind": "chip", "at": [-15.5, -10.0], "s": 1.0, "tone": 2.0}, {"kind": "chip", "at": [17.0, -10.5], "s": 1.0, "tone": 2.0}]},
        {"shapes": [puff(-20.5, -6.4, 1.8, [2.3, 3.0], -1), puff(21.5, -7.2, 2.1, [2.3, 3.0], 1)]},
    ]
    return {"name": "dust_land", "family": "dust", "trigger": "player_action land, at the feet",
            "frame": [48, 20], "anchor": [24, 20], "fps": 20, "floor": 0, "scale": 2, "sheet": f"{SHEETS}/dust_land.png",
            "ramps": {"dust": DUST}, "default_ramp": "dust", "edge": {"dust": "character"},
            "strip": {"cell": [80, 72], "feet": [40, 60], "at": [0, 0], "lineup_frame": 0, "ground": "bg1", "floor": "bg2",
                      "actors": [dict(PLAYER, clip=IDLE, clip_name="idle", at=[0, 0])]},
            "frames": frames}


def burst_die():
    """enemy_died, at the enemy's centre. A flash star, a flattened
    shockwave along the ground (the hack tell owns the circle), chips out
    and down, smoke up. 8 at 24 fps."""
    rays = [(-100, 14), (-70, 11), (-40, 15), (-15, 12), (15, 9), (165, 12), (-165, 9), (-140, 13), (-115, 10)]
    up = [r for r in rays if -150 <= r[0] <= -30]
    frames = [
        {"shapes": [
            {"kind": "ring", "at": [0, 0], "r": 10.5, "w": 2.5, "tone": [1.0, 2.0]},
            {"kind": "disc", "at": [0, 0], "r": 9.0, "tone": [0.0, 1.3]},
            *[{"kind": "streak", "from": [0, 0], "angle": a, "len": L * 0.9, "w": 3.6, "taper": 1.1, "tone": [0.2, 2.0]} for a, L in rays]]},
        {"shapes": [
            {"kind": "ring", "at": [0, 6], "r": 14.0, "ry": 5.0, "w": 3.0, "tone": [0.8, 2.4]},
            *[{"kind": "streak", "from": at(a, 8), "angle": a, "len": L * 0.8, "w": 2.8, "taper": 1.2, "tone": [1.2, 3.4]} for a, L in rays],
            {"kind": "disc", "at": [0, 0], "r": 5.0, "tone": [0.0, 1.1]}]},
        {"shapes": [
            puff(-5.0, -3.0, 4.0, [0.5, 2.2], -1), puff(5.5, -4.0, 4.5, [0.5, 2.2], 1),
            {"kind": "ring", "at": [0, 7], "r": 24.0, "ry": 8.0, "w": 2.6, "tone": [1.8, 3.6]},
            {"kind": "disc", "at": [0, 0], "r": 2.5, "tone": [1.0, 2.2]},
            *[{"kind": "streak", "from": at(a, 15), "angle": a, "len": L * 0.55, "w": 2.2, "tone": [2.2, 4.2]} for a, L in rays],
            *[{"kind": "chip", "at": at(a, L * 1.35, 0.5), "s": 2.4, "tone": 1.8} for a, L in rays]]},
        {"shapes": [
            puff(-7.5, -8.0, 5.5, [0.8, 2.5], -1), puff(7.0, -9.0, 6.0, [0.8, 2.5], 1), puff(0.0, -4.0, 4.0, [1.0, 2.6], 1),
            {"kind": "ring", "at": [0, 8], "r": 32.0, "ry": 10.0, "w": 2.0, "tone": [3.0, 4.6]},
            *[{"kind": "streak", "from": at(a, 21, 1.0), "angle": a, "len": L * 0.3, "w": 1.6, "tone": [3.2, 4.8]} for a, L in up],
            *[{"kind": "chip", "at": at(a, L * 1.65, 2.2), "s": 2.2, "tone": 2.6} for a, L in rays]]},
        {"shapes": [
            puff(-9.5, -12.5, 6.0, [1.1, 2.7], -1), puff(9.0, -13.5, 6.2, [1.1, 2.7], 1), puff(0.5, -8.5, 4.8, [1.2, 2.8], 1),
            *[{"kind": "chip", "at": at(a, L * 1.9, 4.8), "s": 2.0, "tone": 3.2} for a, L in rays[:6]]]},
        {"shapes": [
            puff(-11.0, -17.0, 5.5, [1.5, 2.9], -1), puff(10.5, -18.0, 5.8, [1.5, 2.9], 1), puff(0.0, -13.0, 4.4, [1.6, 3.0], 1),
            *[{"kind": "chip", "at": at(a, L * 2.05, 8.0), "s": 1.6, "tone": 4.0} for a, L in rays[:4]]]},
        {"shapes": [
            puff(-12.5, -21.0, 4.4, [2.0, 3.0], -1), puff(12.0, -22.5, 4.8, [2.0, 3.0], 1), puff(0.5, -17.0, 3.4, [2.0, 3.0], 1),
            *[{"kind": "chip", "at": at(a, L * 2.15, 11.5), "s": 1.2, "tone": 4.8} for a, L in rays[1:3]]]},
        {"shapes": [puff(-13.5, -24.5, 3.0, [2.5, 3.0], -1), puff(13.0, -26.0, 3.2, [2.5, 3.0], 1), puff(0.0, -20.5, 2.2, [2.5, 3.0], 1)]},
    ]
    return {"name": "burst_die", "family": "hot+dust", "trigger": "enemy_died, at the enemy's centre",
            "frame": [64, 64], "anchor": [32, 40], "fps": 24, "floor": 20, "scale": 2, "sheet": f"{SHEETS}/burst_die.png",
            "ramps": {"dust": DUST, "hot": HOT}, "default_ramp": "hot", "edge": {"hot": "none", "dust": "character"},
            "strip": {"cell": [104, 76], "feet": [60, 64], "at": [0, TARGET_CENTRE_DY], "lineup_frame": 1, "ground": "bg1", "floor": "bg2",
                      "actors": [dict(PLAYER, clip=ATTACK, clip_name="attack", at=[-32, 0]),
                                 dict(TARGET, clip=TARGET_DEAD, clip_name="dead", at=[0, 0], flip=True, modulate=[0.6, 0.6, 0.6, 0.55])]},
            "frames": frames}


def main():
    ap = argparse.ArgumentParser(description="write the three example effects as json")
    ap.add_argument("--studio", default=".")
    args = ap.parse_args()
    out = os.path.join(os.path.abspath(args.studio), "vfx")
    os.makedirs(out, exist_ok=True)
    for effect in (spark_hit(), dust_land(), burst_die()):
        path = os.path.join(out, effect["name"] + ".json")
        with open(path, "w", encoding="utf-8") as f:
            json.dump(effect, f, indent=1)
        n = len(effect["frames"])
        print(f"{effect['name']:>10}: {n} frames at {effect['fps']} fps = {1000 * n / effect['fps']:.0f} ms, frame {effect['frame']} -> {path}")


if __name__ == "__main__":
    sys.exit(main())
