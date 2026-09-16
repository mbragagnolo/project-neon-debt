"""The player: Dani, 22x32, facing right.

A slim figure in a padded navy jacket with a cyan trim, a cracked magenta
visor over the eyes, dark trousers, work boots. The wrench rides in the
right hand. Every frame is the same head and torso with the limbs moved,
so the silhouette is one silhouette.
"""
import os
from pixel import draw, save, sheet, preview, shift, overlay, blank, flip

W, H = 22, 32
L = {
    "o": "outline", "h": "hair", "H": "hair_h", "s": "skin", "S": "skin_d",
    "m": "magenta", "M": "magenta_d", "j": "navy", "J": "navy_l", "d": "navy_d",
    "c": "cyan", "p": "black_l", "P": "steel1", "b": "black", "B": "black_l",
    "g": "black_l", "w": "grey", "W": "white", "t": "cyan_d",
}

HEAD = [
    "......oooooo..........",
    ".....ohhhhhho.........",
    "....ohhHHhhhho........",
    "....ohhhhhhhho........",
    "....ohsssssssо".replace("о", "o"),
    "....osmmmmmso.........",
    "....ossssssso.........",
    ".....osSSSso..........",
]
# Fix the odd row: keep rows exactly W wide.
HEAD = [r.ljust(W, ".")[:W] for r in HEAD]

TORSO = [
    ".....ojjjjjjo.........",
    "....ojjcjjjjjo........",
    "...ojjjcjjjjjjo.......",
    "...ojjjcjjjjJjo.......",
    "...ojjjcjjjjJjo.......",
    "...ojjjcjjjjJjo.......",
    "....ojjcjjjjjo........",
    ".....ojjjjjjo.........",
    ".....odddddo..........",
    ".....oppppppo.........",
]
TORSO = [r.ljust(W, ".")[:W] for r in TORSO]

# Arms are separate so they can swing. Left arm (far side) sits behind.
ARM_R_DOWN = [
    "............ogo.......",
    "............ogo.......",
    "............ogo.......",
    "............ogo.......",
    "............oso.......",
    ".............o........",
]
ARM_L_DOWN = [
    "...ogo................",
    "...ogo................",
    "...ogo................",
    "...ogo................",
    "...oso................",
    "....o.................",
]


def arms(dy=0, right=ARM_R_DOWN, left=ARM_L_DOWN):
    return overlay(blank(W, H), shift(left, 0, 10 + dy, (W, H)), shift(right, 0, 10 + dy, (W, H)))


# Legs: rows 19..31 of the frame. Each pose is a 22x13 grid.
LEGS_STAND = [
    ".....oppo.oppo........",
    ".....oppo.oppo........",
    ".....oPPo.oPPo........",
    ".....oppo.oppo........",
    ".....oppo.oppo........",
    ".....oppo.oppo........",
    ".....obbo.obbo........",
    ".....obbo.obbo........",
    "....obBbo.obBbo.......",
    "....obbbbo.obbbbo.....",
    "....oooooo.oooooo.....",
    "......................",
    "......................",
]
# Run cycle: six poses, contact - down - pass - up (each side).
LEGS_RUN = [
    [   # 0 right leg forward, left back
        ".....oppo.oppo........",
        "....oppo...oppo.......",
        "...oPPo.....oPPo......",
        "..oppo.......oppo.....",
        ".oppo.........oppo....",
        ".obbo.........obbo....",
        ".obbo.........obbo....",
        "obBbo.........obBbo...",
        "obbbbo.........obbbbo.",
        "oooooo.........oooooo.",
        "......................",
        "......................",
        "......................",
    ],
    [   # 1 landing
        ".....oppo.oppo........",
        ".....oppo..oppo.......",
        "....oPPo....oPPo......",
        "....oppo.....oppo.....",
        "...oppo.......oppo....",
        "...obbo.......obbo....",
        "...obbo.......obbo....",
        "..obBbo.......obBbo...",
        "..obbbbo......obbbbo..",
        "..oooooo......oooooo..",
        "......................",
        "......................",
        "......................",
    ],
    [   # 2 passing: legs together, one knee up
        ".....oppo.oppo........",
        ".....oppo.oppo........",
        ".....oPPo.oPPo........",
        ".....oppo.oppoo.......",
        ".....oppo..oppo.......",
        ".....obbo..obbo.......",
        ".....obbo..obboo......",
        "....obBbo...obbo......",
        "....obbbbo..oooo......",
        "....oooooo............",
        "......................",
        "......................",
        "......................",
    ],
    [   # 3 left leg forward, right back
        ".....oppo.oppo........",
        "....oppo...oppo.......",
        "...oPPo.....oPPo......",
        "..oppo.......oppo.....",
        ".oppo.........oppo....",
        ".obbo.........obbo....",
        ".obbo.........obbo....",
        "obBbo.........obBbo...",
        "obbbbo.........obbbbo.",
        "oooooo.........oooooo.",
        "......................",
        "......................",
        "......................",
    ],
    [   # 4 landing (mirror)
        ".....oppo.oppo........",
        "....oppo..oppo........",
        "...oPPo....oPPo.......",
        "..oppo.....oppo.......",
        ".oppo.......oppo......",
        ".obbo.......obbo......",
        ".obbo.......obbo......",
        "obBbo.......obBbo.....",
        "obbbbo......obbbbo....",
        "oooooo......oooooo....",
        "......................",
        "......................",
        "......................",
    ],
    [   # 5 passing (mirror)
        ".....oppo.oppo........",
        ".....oppo.oppo........",
        ".....oPPo.oPPo........",
        "....ooppo.oppo........",
        "....oppo..oppo........",
        "....obbo..obbo........",
        "...oobbo..obbo........",
        "...obbo...obBbo.......",
        "...oooo..obbbbo.......",
        ".........oooooo.......",
        "......................",
        "......................",
        "......................",
    ],
]
LEGS_JUMP = [
    ".....oppo.oppo........",
    "....oppo...oppo.......",
    "....oPPo...oPPo.......",
    "...oppo.....oppo......",
    "...oppo.....oppo......",
    "...obbo.....obbo......",
    "..obBbo.....obBbo.....",
    "..obbbo.....obbbo.....",
    "..ooooo.....ooooo.....",
    "......................",
    "......................",
    "......................",
    "......................",
]
LEGS_FALL = [
    ".....oppo.oppo........",
    ".....oppo.oppo........",
    ".....oPPo.oPPo........",
    "....oppo...oppo.......",
    "....oppo...oppo.......",
    "....obbo...obbo.......",
    "...obBbo...obBbo......",
    "...obbbo...obbbo......",
    "...ooooo...ooooo......",
    "......................",
    "......................",
    "......................",
    "......................",
]
LEGS_DASH = [
    "......oppo.oppo.......",
    ".....oppo...opppo.....",
    "....oPPo.....oPPPo....",
    "...oppo........oppo...",
    "..oppo..........obbo..",
    "..obbo..........obBbo.",
    ".obBbo...........obbbo",
    ".obbbo............oooo",
    ".ooooo................",
    "......................",
    "......................",
    "......................",
    "......................",
]
LEGS_WALL = [
    ".....oppo.oppo........",
    ".....oppo.oppo........",
    ".....oPPo.oPPo........",
    ".....oppo.oppo........",
    "....oppo..oppo........",
    "....obbo..obbo........",
    "....obbo..obbo........",
    "...obBbo..obBbo.......",
    "...obbbo..obbbo.......",
    "...ooooo..ooooo.......",
    "......................",
    "......................",
    "......................",
]

# The wrench, in the right hand: a grey shaft with a jaw. Drawn relative to
# the frame; the arm decides where the hand is.
WRENCH_DOWN = [
    "..............oWo.....",
    "..............owo.....",
    "..............owo.....",
    "..............owo.....",
    ".............oWWo.....",
    ".............oWWWo....",
]
# Attack: the arm sweeps forward; three frames (raise, strike, follow-through).
ARM_R_RAISE = [
    "............ogo.......",
    ".............ogo......",
    "..............ogo.....",
    "...............oso....",
]
ARM_R_STRIKE = [
    "............ogogogoso.",
]
ARM_R_FOLLOW = [
    "............ogo.......",
    "............ogo.......",
    ".............ogso.....",
]


def frame(head_dy=0, torso_dy=0, legs=LEGS_STAND, arm_r=ARM_R_DOWN, arm_dy=0, wrench=None, wrench_at=(0, 0)):
    base = blank(W, H)
    layers = [
        shift(ARM_L_DOWN, 0, 10 + arm_dy, (W, H)),
        shift(TORSO, 0, 8 + torso_dy, (W, H)),
        shift(HEAD, 0, 0 + head_dy, (W, H)),
        shift(legs, 0, 19, (W, H)),
        shift(arm_r, 0, 10 + arm_dy, (W, H)),
    ]
    if wrench:
        layers.append(shift(wrench, wrench_at[0], wrench_at[1], (W, H)))
    return draw(overlay(base, *layers), L)


def build():
    frames = {}
    frames["idle"] = [frame(wrench=WRENCH_DOWN, wrench_at=(0, 12)), frame(head_dy=1, torso_dy=1, arm_dy=1, wrench=WRENCH_DOWN, wrench_at=(0, 13))]
    frames["run"] = [frame(legs=LEGS_RUN[i], head_dy=(0 if i in (0, 3) else -1), torso_dy=(0 if i in (0, 3) else -1), arm_dy=(0 if i in (0, 3) else -1), wrench=WRENCH_DOWN, wrench_at=(0, 12 if i in (0, 3) else 11)) for i in range(6)]
    frames["jump"] = [frame(legs=LEGS_JUMP, arm_dy=-2, wrench=WRENCH_DOWN, wrench_at=(0, 10))]
    frames["fall"] = [frame(legs=LEGS_FALL, arm_dy=-1, wrench=WRENCH_DOWN, wrench_at=(0, 11))]
    frames["dash"] = [frame(legs=LEGS_DASH, head_dy=1, torso_dy=1, arm_dy=1, wrench=WRENCH_DOWN, wrench_at=(0, 13))]
    frames["wall"] = [frame(legs=LEGS_WALL, head_dy=0, wrench=WRENCH_DOWN, wrench_at=(0, 12))]
    frames["attack"] = [
        frame(arm_r=ARM_R_RAISE, wrench=[
            "..............oWo.....", "..............owo.....", "...............owo....", "...............oWWo...", "...............oWWWo.."], wrench_at=(2, 6)),
        frame(arm_r=ARM_R_STRIKE, torso_dy=0, wrench=[
            "..................oWWo", "...................oWWo", "....................oo"], wrench_at=(0, 10)),
        frame(arm_r=ARM_R_FOLLOW, wrench=[
            "...............oWo....", "...............owo....", "................owo...", "................oWWo..", "................oWWWo."], wrench_at=(0, 11)),
    ]
    frames["hurt"] = [frame(head_dy=1, torso_dy=1, arm_dy=2, legs=LEGS_FALL, wrench=WRENCH_DOWN, wrench_at=(0, 14))]
    return frames


if __name__ == "__main__":
    frames = build()
    order = ["idle", "run", "jump", "fall", "dash", "wall", "attack", "hurt"]
    all_frames = []
    index = {}
    for name in order:
        index[name] = (len(all_frames), len(frames[name]))
        all_frames.extend(frames[name])
    img = sheet(all_frames)
    path = save(img, "sprites/player.png")
    print("wrote", path, "frames:", index)
    preview(img, os.path.join(os.path.dirname(os.path.abspath(__file__)), "preview_player.png"), 6)
