"""The cast: enemies and NPCs, each a sheet of uniform frames facing right.

Every frame of a character is its base body with limbs or props moved, so
each enemy is one silhouette the player learns. Tells are animation *and*
the state tint the engine blends on top (Enemy.tint), so the greybox
readability survives the art.
"""
import os
from pixel import draw, save, sheet, preview, shift, overlay, blank

HERE = os.path.dirname(os.path.abspath(__file__))


def frame_of(w, h, layers, legend):
    return draw(overlay(blank(w, h), *layers), legend)


def emit(name, frames_by_clip, order, w, h):
    frames = []
    clips = {}
    for clip in order:
        clips[clip] = (len(frames), len(frames_by_clip[clip]))
        frames.extend(frames_by_clip[clip])
    img = sheet(frames)
    path = save(img, "sprites/%s.png" % name)
    preview(img, os.path.join(HERE, "preview_%s.png" % name), 6)
    print("%s: %s -> %s" % (name, clips, path))
    return clips


# ---------------------------------------------------------------------------
# Scav — 20x28. Hooded, hunched, rust and olive, a length of pipe.
# ---------------------------------------------------------------------------
SW, SH = 20, 28
SL = {
    "o": "outline", "k": "olive_l", "K": "grey", "r": "rust2", "R": "sodium",
    "s": "skin2", "S": "skin2_d", "e": "amber", "p": "grey_d", "P": "grey",
    "b": "black", "B": "black_l", "d": "rust0",
}
SCAV_HEAD = [   # a hood, face in shadow, one amber eye
    ".....ooooo..........",
    "....okkkkko.........",
    "...okkKkkkko........",
    "...okkkkkkko........",
    "...okoSSSeko........",
    "...okoSSSSko........",
    "....okSSSko.........",
    ".....ooooo..........",
]
SCAV_TORSO = [
    "....orrrrrro........",
    "...orrRrrrrro.......",
    "...orrrrrrrro.......",
    "...orrrrrrrro.......",
    "...orrrrrrrro.......",
    "....orrrrrro........",
    "....oddddddo........",
]
SCAV_LEGS_STAND = [
    "....okko.okko.......",
    "....okko.okko.......",
    "....okko.okko.......",
    "....obbo.obbo.......",
    "...obBbo.obBbo......",
    "...ooooo.ooooo......",
]
SCAV_LEGS_RUN = [
    ["....okko.okko.......", "...okko...okko......", "..okko.....okko.....", "..obbo.....obbo.....", ".obBbo.....obBbo....", ".ooooo.....ooooo...."],
    ["....okko.okko.......", "....okko..okko......", "...okko...okko......", "...obbo....obbo.....", "..obBbo....obBbo....", "..ooooo....ooooo...."],
    ["....okko.okko.......", "....okko.okko.......", "....okko.okko.......", "....obbo.obbo.......", "...obBbo.obBbo......", "...ooooo.ooooo......"],
    ["....okko.okko.......", "...okko...okko......", "..okko.....okko.....", "..obbo.....obbo.....", ".obBbo.....obBbo....", ".ooooo.....ooooo...."],
]
SCAV_ARM = ["...........opo......", "...........opo......", "...........oso......", "............o......."]
PIPE_DOWN = ["............oPo.....", "............opo.....", "............opo.....", "............opo.....", "............opo....."]
PIPE_RAISED = ["..............oPo...", ".............opo....", "............opo.....", "...........opo......"]
PIPE_SWUNG = ["...........opopopoPo"]


def scav_frame(head_dy=0, torso_dy=0, legs=SCAV_LEGS_STAND, arm=SCAV_ARM, arm_at=(0, 9), pipe=PIPE_DOWN, pipe_at=(0, 10), lean=0):
    layers = [
        shift(SCAV_TORSO, lean, 15 + torso_dy, (SW, SH)),
        shift(SCAV_HEAD, lean, 7 + head_dy, (SW, SH)),
        shift(legs, 0, 22, (SW, SH)),
        shift(arm, lean, arm_at[1] + 7, (SW, SH)),
        shift(pipe, lean + pipe_at[0], pipe_at[1] + 7, (SW, SH)),
    ]
    return frame_of(SW, SH, layers, SL)


def scav_frames(legend):
    global SL
    saved = SL
    SL = legend
    f = {}
    f["idle"] = [scav_frame(), scav_frame(head_dy=1, torso_dy=1, arm_at=(0, 10), pipe_at=(0, 11))]
    f["run"] = [scav_frame(legs=SCAV_LEGS_RUN[i], head_dy=(1 if i in (0, 2) else 0), torso_dy=(1 if i in (0, 2) else 0)) for i in range(4)]
    f["windup"] = [scav_frame(head_dy=2, torso_dy=1, lean=-1, pipe=PIPE_RAISED, pipe_at=(1, 4), arm=["..........opo.......", "...........opo......", "............oso....."], arm_at=(0, 8))]
    f["lunge"] = [scav_frame(head_dy=1, lean=2, pipe=PIPE_SWUNG, pipe_at=(0, 11), arm=["..........opopo.....", "..............oso..."], arm_at=(0, 10), legs=SCAV_LEGS_RUN[0])]
    f["recover"] = [scav_frame(head_dy=3, torso_dy=2, lean=3, pipe=["............opo.....", ".............opo....", "..............oPo..."], pipe_at=(0, 12), legs=SCAV_LEGS_RUN[1])]
    f["stagger"] = [scav_frame(head_dy=-1, lean=-2, pipe=PIPE_DOWN, pipe_at=(0, 9))]
    f["dead"] = [draw([
        "....................",
        "....................",
        "....................",
        "....................",
        "....................",
        "....................",
        "....................",
        "....................",
        "....................",
        "....................",
        "....................",
        "....................",
        "....................",
        "....................",
        "....................",
        "....................",
        "....................",
        "....................",
        "....................",
        "....................",
        "....oooo............",
        "...okkkkoorrrrrooo..",
        "..okkSSekorrrrrrkko.",
        "..okkSSSkorrRrrrkko.",
        "...okkkkoorrrrrrbbo.",
        "....oooo..ooooooooo.",
        "....................",
        "....................",
    ], SL)]
    SL = saved
    return f


# ---------------------------------------------------------------------------
# Watcher drone — 18x12. A disc, an eye, a rotor.
# ---------------------------------------------------------------------------
DW, DH = 18, 12
DL = {"o": "outline", "s": "steel2", "S": "steel3", "d": "steel1", "e": "red", "E": "white",
      "r": "grey_d", "R": "grey", "c": "cyan", "k": "black"}
DRONE_BODY = [
    "......oooooo........",
    "....oossssssoo......",
    "..oosSSSSSSSSsoo....",
    ".osSSSSSSSSSSSSso...",
    ".osssssssssssssso...",
    "..oddddddddddddo....",
    "...oddddddddddo.....",
    "....oooooooooo......",
]


def drone_frame(rotor, eye, tilt=0, lights=True):
    rows = overlay(blank(DW, DH), shift(rotor, 0, 0, (DW, DH)), shift(DRONE_BODY, 0, 2, (DW, DH)), shift(eye, 0, 5, (DW, DH)))
    if lights:
        rows = overlay(rows, shift(["........c..c........"], 0, 8, (DW, DH)))
    if tilt:
        rows = shift(rows, 0, tilt, (DW, DH))
    return draw(rows, DL)


ROTOR_A = ["...rRRRRRRRRRRRRr...", "........orro........"]
ROTOR_B = ["....RrrRRRRRrrR.....", "........orro........"]
EYE_ON = ["...........oeeo.....", "...........oEeo....."]
EYE_HOT = ["..........oeeeeo....", "..........oEEeeo...."]
EYE_OFF = ["...........okko.....", "...........okko....."]


def drone_frames():
    return {
        "hover": [drone_frame(ROTOR_A, EYE_ON), drone_frame(ROTOR_B, EYE_ON, tilt=1)],
        "aim": [drone_frame(ROTOR_A, EYE_HOT)],
        "stunned": [drone_frame(["....................", "........orro........"], EYE_OFF, tilt=2, lights=False)],
        "dead": [drone_frame(["....................", "........orro........"], EYE_OFF, tilt=3, lights=False)],
    }


# ---------------------------------------------------------------------------
# Riot unit — 26x34, plus the shield 8x36 on the Facing node.
# ---------------------------------------------------------------------------
RW, RH = 26, 34
RL = {"o": "outline", "a": "steel1", "A": "steel2", "h": "steel3", "v": "cyan", "V": "cyan_d",
      "b": "black", "B": "black_l", "y": "amber", "k": "concrete1", "K": "concrete2"}
RIOT_HEAD = [
    "........oooooooo..........",
    ".......oaaaaaaaao.........",
    "......oaaAAAAAaaao........",
    "......oaaaaaaaaaao........",
    "......oaVvvvvvvVao........",
    "......oaaaaaaaaaao........",
    ".......oaaaaaaaao.........",
    "........oooooooo..........",
]
RIOT_TORSO = [
    ".....oaaaaaaaaaaaao.......",
    "....oaaAAAAAAAAAaaao......",
    "...oaaaAAAAAAAAAAaaao.....",
    "...oaaaAAAAAyAAAAaaao.....",
    "...oaaaAAAAAAAAAAaaao.....",
    "...oaaaaAAAAAAAAaaaao.....",
    "....oaaaaaaaaaaaaaao......",
    ".....oaaaaaaaaaaaao.......",
    "......oooooooooooo........",
]
RIOT_LEGS = [
    [".......okkko.okkko........", ".......okkko.okkko........", ".......oKKko.oKKko........", ".......okkko.okkko........", ".......obbbo.obbbo........", "......obBbbo.obBbbo.......", "......oooooo.oooooo......."],
    ["......okkko...okkko.......", ".....okkko.....okkko......", "....oKKko.......oKKko.....", "....okkko.......okkko.....", "...obbbo.........obbbo....", "..obBbbo.........obBbbo...", "..oooooo.........oooooo..."],
    [".......okkko.okkko........", ".......okkko.okkko........", ".......oKKko.oKKko........", ".......okkko.okkko........", ".......obbbo.obbbo........", "......obBbbo.obBbbo.......", "......oooooo.oooooo......."],
    ["......okkko...okkko.......", ".....okkko.....okkko......", "....oKKko.......oKKko.....", "....okkko.......okkko.....", "...obbbo.........obbbo....", "..obBbbo.........obBbbo...", "..oooooo.........oooooo..."],
]


def riot_frame(legs=RIOT_LEGS[0], head_dy=0, torso_dy=0, lean=0):
    layers = [
        shift(RIOT_TORSO, lean, 18 + torso_dy, (RW, RH)),
        shift(RIOT_HEAD, lean, 10 + head_dy, (RW, RH)),
        shift(legs, 0, 27, (RW, RH)),
    ]
    return frame_of(RW, RH, layers, RL)


def riot_frames():
    return {
        "idle": [riot_frame(), riot_frame(head_dy=1)],
        "run": [riot_frame(legs=RIOT_LEGS[i], head_dy=(1 if i % 2 else 0)) for i in range(4)],
        "windup": [riot_frame(head_dy=2, torso_dy=1, lean=-2)],
        "lunge": [riot_frame(legs=RIOT_LEGS[1], head_dy=-1, lean=3)],
        "recover": [riot_frame(head_dy=2, torso_dy=1, lean=2)],
        "stagger": [riot_frame(head_dy=-1, lean=-3)],
        "stunned": [riot_frame(head_dy=3, torso_dy=2)],
        "dead": [riot_frame(head_dy=6, torso_dy=5, legs=RIOT_LEGS[1])],
    }


SHIELD = [
    ".oooooo.",
    "oaaaaaao",
    "oaAAAAao",
    "oaAvvAao",
    "oaAvvAao",
    "oaAvvAao",
    "oaAvvAao",
    "oaAvvAao",
    "oaAvvAao",
    "oaAvvAao",
    "oaAvvAao",
    "oaAAAAao",
    "oaaaaaao",
    "oaAAAAao",
    "oaAAAAao",
    "oaAAAAao",
    "oaAAAAao",
    "oaAAAAao",
    "oaAAAAao",
    "oaAAAAao",
    "oaAAAAao",
    "oaAAAAao",
    "oaAAAAao",
    "oaAAAAao",
    "oaAAAAao",
    "oaAAAAao",
    "oaAAAAao",
    "oaAAAAao",
    "oaAAAAao",
    "oaAAAAao",
    "oaAAAAao",
    "oaaaaaao",
    "oaaaaaao",
    "oaaaaaao",
    "oaaaaaao",
    ".oooooo.",
]


# ---------------------------------------------------------------------------
# The Landlord — 28x44. A long chrome-trimmed coat, the deck on the chest,
# a baton. Tall, still, expensive.
# ---------------------------------------------------------------------------
LW, LH = 28, 44
LL = {"o": "outline", "h": "hair", "H": "hair_h", "s": "skin", "S": "skin_d", "c": "black",
      "C": "black_l", "m": "chrome", "M": "chrome_d", "v": "cyan", "V": "cyan_d", "b": "black",
      "w": "white", "g": "grey", "G": "grey_d", "e": "magenta"}
LAND_HEAD = [
    "..........oooooo............",
    ".........ohhhhhho...........",
    "........ohhHHhhhho..........",
    "........ohhhhhhhho..........",
    "........ohsssssssho.........",
    "........osssssssso..........",
    "........ossSseSsso..........",
    "........osssssssso..........",
    ".........osSSSSso...........",
    "..........oooooo............",
]
LAND_COAT = [
    "........occcccccco..........",
    "......occcmcccccmccco.......",
    ".....occccmccvvccmcccco.....",
    "....occcccmccvvccmccccco....",
    "....occcccmccccccmccccco....",
    "....occcccmccccccmccccco....",
    "....oCcccccccccccccccCco....",
    "....oCccccccccccccccccco....",
    "....occcccccccccccccccco....",
    "....occcccccccccccccccco....",
    "....occcccccccccccccccco....",
    ".....occccccccccccccco......",
    ".....occccccccccccccco......",
    ".....occccccccccccccco......",
    ".....oCccccccccccccCco......",
    "......ocmmmmmmmmmmmco.......",
]
LAND_LEGS = [
    ["........occo...occo.........", "........occo...occo.........", "........oCCo...oCCo.........", "........occo...occo.........", "........obbo...obbo.........", ".......obbbo...obbbo........", ".......ooooo...ooooo........"],
    [".......occo.....occo........", "......occo.......occo.......", ".....oCCo.........oCCo......", ".....occo.........occo......", "....obbo...........obbo.....", "...obbbo...........obbbo....", "...ooooo...........ooooo...."],
    ["........occo...occo.........", "........occo...occo.........", "........oCCo...oCCo.........", "........occo...occo.........", "........obbo...obbo.........", ".......obbbo...obbbo........", ".......ooooo...ooooo........"],
    [".......occo.....occo........", "......occo.......occo.......", ".....oCCo.........oCCo......", ".....occo.........occo......", "....obbo...........obbo.....", "...obbbo...........obbbo....", "...ooooo...........ooooo...."],
]
LAND_ARM = [".....................oco....", ".....................oco....", ".....................oco....", ".....................oco....", ".....................oso....", "......................o....."]
BATON_DOWN = ["......................owo...", "......................ogo...", "......................ogo...", "......................ogo...", "......................ogo...", "......................ogo..."]
BATON_UP = ["..........................ow", ".........................og.", "........................og..", ".......................og...", "......................og...."]
BATON_SWING = [".....................ogggggw"]


def land_frame(legs=LAND_LEGS[0], head_dy=0, coat_dy=0, lean=0, arm=LAND_ARM, arm_at=(0, 12), baton=BATON_DOWN, baton_at=(0, 17), deck_hot=False):
    coat = LAND_COAT
    if deck_hot:
        coat = [r.replace("v", "w") for r in coat]
    layers = [
        shift(coat, lean, 21 + coat_dy, (LW, LH)),
        shift(LAND_HEAD, lean, 12 + head_dy, (LW, LH)),
        shift(legs, 0, 37, (LW, LH)),
        shift(arm, lean + arm_at[0], arm_at[1] + 12, (LW, LH)),
        shift(baton, lean + baton_at[0], baton_at[1] + 12, (LW, LH)),
    ]
    return frame_of(LW, LH, layers, LL)


def landlord_frames():
    return {
        "idle": [land_frame(), land_frame(head_dy=1, coat_dy=1, arm_at=(0, 13), baton_at=(0, 18))],
        "run": [land_frame(legs=LAND_LEGS[i], head_dy=(1 if i % 2 else 0)) for i in range(4)],
        "windup": [land_frame(head_dy=1, lean=-2, arm=["....................oco.....", ".....................oco....", "......................oco...", ".......................oso.."], arm_at=(0, 11), baton=BATON_UP, baton_at=(0, 5))],
        "lunge": [land_frame(legs=LAND_LEGS[1], lean=3, arm=[".....................ocococo", "...........................o"], arm_at=(0, 13), baton=BATON_SWING, baton_at=(0, 14))],
        "recover": [land_frame(head_dy=3, coat_dy=2, lean=2, arm_at=(0, 14), baton_at=(0, 19))],
        "slam_windup": [land_frame(head_dy=6, coat_dy=5, legs=LAND_LEGS[1], arm=["...................oco......", "...................oco......", "...................oso......"], arm_at=(0, 24), baton=["...................ogo......", "...................ogo......"], baton_at=(0, 27))],
        "beam": [land_frame(lean=1, deck_hot=True, arm=[".....................ocococo"], arm_at=(0, 14), baton=["...........................w"], baton_at=(0, 14))],
        "stagger": [land_frame(head_dy=-1, lean=-3)],
        "phase": [land_frame(head_dy=-1, deck_hot=True, arm=["....................oco.....", "...................oco......", "..................oso......."], arm_at=(3, 10), baton=BATON_UP, baton_at=(0, 4))],
        "dead": [land_frame(head_dy=10, coat_dy=9, legs=[".....occcccccccccccccco.....", "......ooooooooooooooooo.....", "............................", "............................", "............................", "............................", "............................"], arm_at=(0, 22), baton_at=(-4, 30))],
    }


# ---------------------------------------------------------------------------
# NPCs — Stitch 22x30, Marisol 20x30. Two idle frames each.
# ---------------------------------------------------------------------------
NL = {"o": "outline", "s": "skin2", "S": "skin2_d", "t": "skin", "T": "skin_d", "h": "hair",
      "H": "hair_h", "a": "concrete2", "A": "concrete3", "g": "green", "G": "green_d",
      "w": "white", "k": "olive", "K": "olive_l", "r": "rust2", "R": "rust1", "p": "violet",
      "P": "violet_d", "b": "black", "B": "black_l", "e": "amber", "y": "grey"}
STITCH = [
    "......oooooooo........",
    ".....ohhhhhhhho.......",
    "....ohhggggggho.......",   # goggles pushed up
    "....ohhGggggGho.......",
    "....ossssssssso.......",
    "....osSssssSsso.......",
    "....ossssssssso.......",
    ".....osSSSSSso........",
    "....oaaaaaaaaao.......",
    "...oaaawwwwwaaao......",   # the apron
    "..oaaaawwwwwaaaao.....",
    "..oaaaawwwwwaaaao.....",
    "..oaaaawwwwwaaaao.....",
    "..osaaawwwwwaaaso.....",
    "..oso.awwwwwa.oso.....",
    "...o..awwwwwa..o......",
    "......awwwwwa.........",
    "......awwwwwa.........",
    ".....okkkkkkkko.......",
    ".....okkko.okkko......",
    ".....okkko.okkko......",
    ".....oKKko.oKKko......",
    ".....okkko.okkko......",
    ".....okkko.okkko......",
    ".....obbbo.obbbo......",
    "....obBbbo.obBbbo.....",
    "....oooooo.oooooo.....",
    "......................",
    "......................",
    "......................",
]
MARISOL = [
    ".....oooooooo.......",
    "....oppppppppo......",   # a headscarf
    "...opppPpppppppo....",
    "...opptttttttppo....",
    "...opttTtttTttpo....",
    "...opttttttttppo....",
    "....otttttttto......",
    ".....otTTTTto.......",
    "....orrrrrrrro......",   # the cardigan
    "...orrRrrrrrrro.....",
    "..orrrrrrrrrrrro....",
    "..orrrrrrrrrrrro....",
    "..otrrrrrrrrrrto....",
    "..ototrrrrrrtoto....",   # arms folded
    "...o.otttttto.o.....",
    ".....orrrrrro.......",
    ".....orrrrrro.......",
    ".....oRRRRRRo.......",
    ".....obbbbbbo.......",
    ".....obbbbbbo.......",
    ".....obbbbbbo.......",
    ".....obbbbbbo.......",
    ".....obbbbbbo.......",
    ".....obbbbbbo.......",
    ".....obbo.obbo......",
    "....obBbo.obBbo.....",
    "....ooooo.ooooo.....",
    "....................",
    "....................",
    "....................",
]


def npc_frames(rows, w, h):
    base = draw([r.ljust(w, ".")[:w] for r in rows], NL)
    bob = draw(shift([r.ljust(w, ".")[:w] for r in rows[:-4]], 0, 1, (w, h)) if False else overlay(blank(w, h), shift([r.ljust(w, ".")[:w] for r in rows[:18]], 0, 1, (w, h)), shift([r.ljust(w, ".")[:w] for r in rows], 0, 0, (w, h))[18:] and [r.ljust(w, ".")[:w] for r in rows]), NL)
    # Simpler: the bob frame shifts the whole upper body down one pixel.
    upper = [r.ljust(w, ".")[:w] for r in rows[:18]]
    lower = [r.ljust(w, ".")[:w] for r in rows[18:]]
    bob_rows = overlay(blank(w, h), shift(lower, 0, 18, (w, h)), shift(upper, 0, 1, (w, h)))
    bob = draw(bob_rows, NL)
    return {"idle": [base, bob]}


if __name__ == "__main__":
    scav_pal = dict(SL)
    emit("scav", scav_frames(scav_pal), ["idle", "run", "windup", "lunge", "recover", "stagger", "dead"], SW, SH)
    elite_pal = dict(SL)
    elite_pal.update({"k": "black_l", "K": "concrete1", "r": "red_d", "R": "red", "e": "magenta", "d": "black"})
    emit("elite_scav", scav_frames(elite_pal), ["idle", "run", "windup", "lunge", "recover", "stagger", "dead"], SW, SH)
    emit("drone", drone_frames(), ["hover", "aim", "stunned", "dead"], DW, DH)
    emit("riot", riot_frames(), ["idle", "run", "windup", "lunge", "recover", "stagger", "stunned", "dead"], RW, RH)
    save(draw(SHIELD, RL), "sprites/riot_shield.png")
    emit("landlord", landlord_frames(), ["idle", "run", "windup", "lunge", "recover", "slam_windup", "beam", "stagger", "phase", "dead"], LW, LH)
    emit("stitch", npc_frames(STITCH, 22, 30), ["idle"], 22, 30)
    emit("marisol", npc_frames(MARISOL, 20, 30), ["idle"], 20, 30)
