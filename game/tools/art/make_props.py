"""Props: everything the player walks up to, and the dressing around it."""
import os
from pixel import draw, save, preview, sheet, PALETTE
from make_tiles import solid, px, hline, vline, rect

HERE = os.path.dirname(os.path.abspath(__file__))

L = {
    "o": "outline", "s": "steel1", "S": "steel2", "t": "steel3", "T": "steel4",
    "c": "cyan", "C": "cyan_d", "m": "magenta", "M": "magenta_d", "a": "amber", "A": "amber_d",
    "g": "green", "G": "green_d", "v": "violet", "V": "violet_d", "r": "red", "R": "red_d",
    "w": "white", "y": "grey", "Y": "grey_d", "k": "black", "K": "black_l", "b": "bg0",
    "B": "bg1", "d": "bg2", "D": "bg3", "u": "rust1", "U": "rust2", "n": "sodium", "W": "warm",
    "e": "concrete1", "E": "concrete2", "l": "olive", "L": "olive_l",
}


def emit(name, rows, sub="props"):
    img = draw(rows, L)
    save(img, "%s/%s.png" % (sub, name))
    return img


SAVE_TERMINAL = [
    "....oooooooooooooooo....",
    "...osssssssssssssssso...",
    "...osSSSSSSSSSSSSSSso...",
    "...osSooooooooooooSso...",
    "...osSoccccccccccoSso...",
    "...osSocCCCCCCCCcoSso...",
    "...osSocCwwwwCCCcoSso...",
    "...osSocCCCCCCCCcoSso...",
    "...osSocCCCCCCCCcoSso...",
    "...osSocCCCCCCCCcoSso...",
    "...osSoccccccccccoSso...",
    "...osSooooooooooooSso...",
    "...osSSSSSSSSSSSSSSso...",
    "...osssssssssssssssso...",
    "...ossoooooooooooosso...",
    "...ossoaaoaaoaaoaosso...",
    "...ossoooooooooooosso...",
    "...ossoaaoaaoaaoaosso...",
    "...ossoooooooooooosso...",
    "...osssssssssssssssso...",
    "...osssssssssssssssso...",
    "...ossssssmmssssssss....".replace("....", "o..."),
    "...osssssssssssssssso...",
    "...osssssssssssssssso...",
    "...osssssssssssssssso...",
    "...osssssssssssssssso...",
    "...osssssssssssssssso...",
    "...osssssssssssssssso...",
    "...osssssssssssssssso...",
    "...osssssssssssssssso...",
    "...osssssssssssssssso...",
    "...osssssssssssssssso...",
    "...osssssssssssssssso...",
    "...osssssssssssssssso...",
    "...osssssssssssssssso...",
    "...osssssssssssssssso...",
    "...osssssssssssssssso...",
    "...osssssssssssssssso...",
    "...osssssssssssssssso...",
    "...osssssssssssssssso...",
    "...osssssssssssssssso...",
    "...osssssssssssssssso...",
    "..ossssssssssssssssss...".replace("...", "o.."),
    "..oooooooooooooooooooo..",
]
SAVE_TERMINAL = [r.ljust(24, ".")[:24] for r in SAVE_TERMINAL]

CHEST = [
    "........................",
    "....oooooooooooooooo....",
    "...olllllllllllllllllo..",
    "..olLLLLLLLLLLLLLLLLllo.",
    "..ollllllllaallllllllo..",
    "..ollllllllaallllllllo..",
    "..oooooooooooooooooooo..",
    "..ollllllllaallllllllo..",
    "..olllllllloollllllllo..",
    "..olllllllllllllllllllo.",
    "..ollllllllllllllllllo..",
    "..ollllllllllllllllllo..",
    "..ollllllllllllllllllo..",
    "..ollllllllllllllllllo..",
    "..ollllllllllllllllllo..",
    "..ollllllllllllllllllo..",
    "...ooooooooooooooooo....",
    "........................",
]
CHEST = [r.ljust(24, ".")[:24] for r in CHEST]

PROGRAM_TERMINAL = [
    "....oooooooooooo....",
    "...oSSSSSSSSSSSSo...",
    "...oSooooooooooSo...",
    "...oSoggggggggoSo...",
    "...oSoGwwGGGGGoSo...",
    "...oSoGGGGwwwGoSo...",
    "...oSoGGGGGGGGoSo...",
    "...oSoggggggggoSo...",
    "...oSooooooooooSo...",
    "...oSSSSSSSSSSSSo...",
    "...osssssssssssso...",
    "...osoaosososoaso...",
    "...osssssssssssso...",
    "...osoaoaososoaso...",
    "...osssssssssssso...",
    "...osoaosoaosoaso...",
    "...osssssssssssso...",
    "...osssssssssssso...",
    "...osssssssssssso...",
    "...osssssssssssso...",
    "...osssssssssssso...",
    "...osssssssssssso...",
    "...osssssssssssso...",
    "...osssssssssssso...",
    "...osssssssssssso...",
    "...osssssssssssso...",
    "...osssssssssssso...",
    "...osssssssssssso...",
    "...osssssssssssso...",
    "...osssssssssssso...",
    "...osssssssssssso...",
    "...osssssssssssso...",
    "...osssssssssssso...",
    "...osssssssssssso...",
    "..oooooooooooooooo..",
    "....................",
]
PROGRAM_TERMINAL = [r.ljust(20, ".")[:20] for r in PROGRAM_TERMINAL]

GADGET_CRATE = [
    "........................",
    "..oooooooooooooooooooo..",
    ".ossssssssssssssssssss..".replace("..", "o."),
    ".osSSSSSSSSSSSSSSSSSSso.",
    ".osSccccccccccccccccSso.",
    ".osSSSSSSSSSSSSSSSSSSso.",
    ".ossssssssssssssssssss..".replace("..", "o."),
    ".oooooooooooooooooooooo.",
    ".ossssssssssssssssssss..".replace("..", "o."),
    ".osSSSSSSSSSSSSSSSSSSso.",
    ".osSSSSSScccccSSSSSSSso.",
    ".osSSSSSScTTTcSSSSSSSso.",
    ".osSSSSSScccccSSSSSSSso.",
    ".osSSSSSSSSSSSSSSSSSSso.",
    ".ossssssssssssssssssss..".replace("..", "o."),
    "..oooooooooooooooooooo..",
    "........................",
    "........................",
]
GADGET_CRATE = [r.ljust(24, ".")[:24] for r in GADGET_CRATE]

IMPLANT_CRATE = [
    "........................",
    "..oooooooooooooooooooo..",
    ".owwwwwwwwwwwwwwwwwwwwo.",
    ".owwwwwwwwwwwwwwwwwwwwo.",
    ".owwwwwwwwwrrwwwwwwwwwo.",
    ".owwwwwwwwwrrwwwwwwwwwo.",
    ".owwwwwwwrrrrrrwwwwwwwo.",
    ".owwwwwwwrrrrrrwwwwwwwo.",
    ".owwwwwwwwwrrwwwwwwwwwo.",
    ".owwwwwwwwwrrwwwwwwwwwo.",
    ".owwwwwwwwwwwwwwwwwwwwo.",
    ".owyyyyyyyyyyyyyyyyyywo.",
    ".owwwwwwwwwwwwwwwwwwwwo.",
    ".owwwwwwwwwwwwwwwwwwwwo.",
    ".oyyyyyyyyyyyyyyyyyyyyo.",
    "..oooooooooooooooooooo..",
    "........................",
    "........................",
]
IMPLANT_CRATE = [r.ljust(24, ".")[:24] for r in IMPLANT_CRATE]

HP_UP = [
    "............",
    "...oooooo...",
    "..orrrrrro..",
    ".orrrwwrrro.",
    ".orrwwwwrro.",
    ".orrwwwwrro.",
    ".orrrwwrrro.",
    ".orrrrrrrro.",
    "..orrrrrro..",
    "...oooooo...",
    "............",
    "............",
    "............",
    "............",
]
RAM_UP = [
    "............",
    "..oooooooo..",
    ".ovvvvvvvvo.",
    ".ovVVVVVVvo.",
    ".ovVwwwwVvo.",
    ".ovVwVVwVvo.",
    ".ovVwwwwVvo.",
    ".ovVVVVVVvo.",
    ".ovvvvvvvvo.",
    "..oooooooo..",
    ".o.o.o.o.o..",
    "............",
    "............",
    "............",
]
CHIP = [
    "............",
    "....oooo....",
    "...occcco...",
    "...ocwwco...",
    "...ocwwco...",
    "...occcco...",
    "....oooo....",
    "...o.o.o.o..",
    "............",
    "............",
    "............",
    "............",
    "............",
    "............",
]

DOOR_FRAME = [   # 20 wide, 60 tall: a doorway with a lit lintel
    "oTTTTTTTTTTTTTTTTTTo",
    "oTccccccccccccccccTo",
    "oTTTTTTTTTTTTTTTTTTo",
] + ["otbbbbbbbbbbbbbbbbto"] * 54 + [
    "otbbbbbbbbbbbbbbbbto",
    "oTTTTTTTTTTTTTTTTTTo",
    "oooooooooooooooooooo",
]

BREACH_DOOR = [   # 20x60 nine-patch source: red-lit bulkhead
    "oooooooooooooooooooo",
    "ossssssssssssssssssso"[:20],
    "osSSSSSSSSSSSSSSSSSo",
    "osSooooooooooooooSSo",
    "osSorrrrrrrrrrrroSSo",
    "osSorRRRRRRRRRRroSSo",
    "osSorRRRRRRRRRRroSSo",
    "osSorrrrrrrrrrrroSSo",
    "osSooooooooooooooSSo",
] + ["osSSSSSSSSSSSSSSSSSo"] * 3 + ["osssssssssssssssssso"] * 4 + [
    "osSSSSSSSSSSSSSSSSSo",
] * 3 + ["osssssssssssssssssso"] * 37 + [
    "osssssssssssssssssso",
    "oooooooooooooooooooo",
]

GRATE = [
    "oSooooSooooSooooSooo",
    "SSSSSSSSSSSSSSSSSSSS",
    "oSooooSooooSooooSooo",
    "oSooooSooooSooooSooo",
    "oSooooSooooSooooSooo",
    "SSSSSSSSSSSSSSSSSSSS",
    "oSooooSooooSooooSooo",
    "oSooooSooooSooooSooo",
    "oSooooSooooSooooSooo",
    "SSSSSSSSSSSSSSSSSSSS",
    "oSooooSooooSooooSooo",
    "oSooooSooooSooooSooo",
    "oSooooSooooSooooSooo",
    "SSSSSSSSSSSSSSSSSSSS",
    "oSooooSooooSooooSooo",
    "oSooooSooooSooooSooo",
    "oSooooSooooSooooSooo",
    "SSSSSSSSSSSSSSSSSSSS",
    "oSooooSooooSooooSooo",
    "oSooooSooooSooooSooo",
]

LIFT_DECK = [
    "aaaakkkkaaaakkkkaaaa",
    "aaaakkkkaaaakkkkaaaa",
    "SSSSSSSSSSSSSSSSSSSS",
    "ssssssssssssssssssss",
    "sSssSssSssSssSssSssS",
    "ssssssssssssssssssss",
    "oooooooooooooooooooo",
    "....................",
]

TEASE_CRATE = [
    "..oooooooooooo..",
    ".oaaaaaaaaaaaao.",
    ".oaAAAAAAAAAAao.",
    ".oaAaaaaaaaaAao.",
    ".oaAaAAAAAAaAao.",
    ".oaAaAaaaaAaAao.",
    ".oaAaAaccaAaAao.",
    ".oaAaAaccaAaAao.",
    ".oaAaAaaaaAaAao.",
    ".oaAaAAAAAAaAao.",
    ".oaAaaaaaaaaAao.",
    ".oaAAAAAAAAAAao.",
    ".oaaaaaaaaaaaao.",
    ".oaaaaaaaaaaaao.",
    "..oooooooooooo..",
    "................",
]

SIGN_PANEL = [   # 12x12 nine-patch
    "oooooooooooo",
    "otttttttttto",
    "otBBBBBBBBto",
    "otBBBBBBBBto",
    "otBBBBBBBBto",
    "otBBBBBBBBto",
    "otBBBBBBBBto",
    "otBBBBBBBBto",
    "otBBBBBBBBto",
    "otBBBBBBBBto",
    "otttttttttto",
    "oooooooooooo",
]
SIGN_PANEL_WARN = [r.replace("t", "R") for r in SIGN_PANEL]

BREACH_TERMINAL = [
    "..oooooooo..",
    ".oSSSSSSSSo.",
    ".oSoooooooSo".replace("oooooooSo", "ooooooSo."),
    ".oSorrrroSo.",
    ".oSorRRroSo.",
    ".oSorrrroSo.",
    ".oSooooooSo.",
    ".oSSSSSSSSo.",
    ".oSaSaSaSSo.",
    ".oSSSSSSSSo.",
    "..oooooooo..",
    "....oSSo....",
    "....oSSo....",
    "....oSSo....",
    "...oooooo...",
    "............",
]
BREACH_TERMINAL = [r.ljust(12, ".")[:12] for r in BREACH_TERMINAL]

# --- Decor ---------------------------------------------------------------------------
PIPE_H = ["oooooooooooooooooooooooooooooooooooooooo", "oSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSo", "otSSSSSSSSStSSSSSSSSSStSSSSSSSSSSSStSSSo", "ossssssssssssssssssssssssssssssssssssso"[:40].ljust(40, "o"), "oooooooooooooooooooooooooooooooooooooooo", "........................................"]
PIPE_V = ["oooooo"] + ["oSStso"] * 38 + ["oooooo"]
VENT = [
    "oooooooooooooooooooo",
    "oSSSSSSSSSSSSSSSSSSo",
    "oSbbbbbbbbbbbbbbbbSo",
    "oSSSSSSSSSSSSSSSSSSo",
    "oSbbbbbbbbbbbbbbbbSo",
    "oSSSSSSSSSSSSSSSSSSo",
    "oSbbbbbbbbbbbbbbbbSo",
    "oSSSSSSSSSSSSSSSSSSo",
    "oSbbbbbbbbbbbbbbbbSo",
    "oSSSSSSSSSSSSSSSSSSo",
    "oooooooooooooooooooo",
    "....................",
]
POSTER_A = [
    "oooooooooooooooo",
    "oMMMMMMMMMMMMMMo",
    "oMmmmmmmmmmmmmMo",
    "oMmMMmmmmMMmmmMo",
    "oMmmmmmmmmmmmmMo",
    "oMmmwwwwwwwwmmMo",
    "oMmmwwwwwwwwmmMo",
    "oMmmmmmmmmmmmmMo",
    "oMmmmmmmmmmmmmMo",
    "oMmMMMMMMMMMMmMo",
    "oMmmmmmmmmmmmmMo",
    "oMmmmmmmmmmmmmMo",
    "oMMMMMMMMMMMMMMo",
    "oMMMMwwwwwwMMMMo",
    "oMMMMMMMMMMMMMMo",
    "oooooooooooooooo",
    "................",
    "................",
    "................",
    "................",
]
POSTER_B = [r.replace("M", "C").replace("m", "c") for r in POSTER_A]
LAMP = [
    "...oo...",
    "..oSSo..",
    ".oSSSSo.",
    ".onnnno.",
    ".oWWWWo.",
    "..oWWo..",
    "...oo...",
    "........",
    "........",
    "........",
]
WINDOW = [
    "oooooooooooooooooooooooo",
    "otttttttttttttttttttttto",
    "otWWWWWWWWWttWWWWWWWWWto",
    "otWWWWWWWWWttWWWWWWWWWto",
    "otWWWnWWWWWttWWWWWWWWWto",
    "otWWWWWWWWWttWWWWWWnWWto",
    "otWWWWWWWWWttWWWWWWWWWto",
    "otttttttttttttttttttttto",
    "otWWWWWWWWWttWWWWWWWWWto",
    "otWWWWWWWWWttWWWWWWWWWto",
    "otWWWWWWnWWttWWWWWWWWWto",
    "otWWWWWWWWWttWWWWWWWWWto",
    "otWWWWWWWWWttWWWWWWWWWto",
    "otttttttttttttttttttttto",
    "oooooooooooooooooooooooo",
    "........................",
]
CRATES = [
    "........................",
    "....oooooooooooo........",
    "....ouuuuuuuuuuo........",
    "....ouUUUUUUUUuo........",
    "....ouuuuuuuuuuo........",
    "....ouuuuuuuuuuo........",
    "oooooooooooooooooooooooo",
    "ouuuuuuuuuuoouuuuuuuuuuo",
    "ouUUUUUUUUuoouUUUUUUUUuo",
    "ouuuuuuuuuuoouuuuuuuuuuo",
    "ouuuuuuuuuuoouuuuuuuuuuo",
    "ouuuuuuuuuuoouuuuuuuuuuo",
    "ouuuuuuuuuuoouuuuuuuuuuo",
    "oooooooooooooooooooooooo",
    "........................",
    "........................",
    "........................",
    "........................",
    "........................",
    "........................",
]
BARREL = [
    "..oooooooo..",
    ".oSSSSSSSSo.",
    ".oSeeeeeeSo.",
    ".oSeeeeeeSo.",
    ".oSSSSSSSSo.",
    ".oSeeeeeeSo.",
    ".oSeeeeeeSo.",
    ".oSeeeeeeSo.",
    ".oSeeeeeeSo.",
    ".oSSSSSSSSo.",
    ".oSeeeeeeSo.",
    ".oSeeeeeeSo.",
    ".oSeeeeeeSo.",
    ".oSeeeeeeSo.",
    ".oSSSSSSSSo.",
    "..oooooooo..",
]
MONITOR = [
    "oooooooooooooooo",
    "oSSSSSSSSSSSSSSo",
    "oSggggggggggggSo",
    "oSgGGGGGGGGGGgSo",
    "oSgGwwGGGGGGGgSo",
    "oSgGGGGGwwwGGgSo",
    "oSgGGGGGGGGGGgSo",
    "oSggggggggggggSo",
    "oSSSSSSSSSSSSSSo",
    "oooooooooooooooo",
    "......oSSo......",
    "....oooooooo....",
]
CABLE = ["........................................", "oo....................................oo", "..oo................................oo..", "....oooo........................oooo....", "........oooooooooooooooooooooooo........", "........................................"]
FAN = [
    "..oooooooooooooooo..",
    ".oSSSSSSSSSSSSSSSSo.",
    "oSbbbbbbbbbbbbbbbbSo",
    "oSbbbbbbbSSbbbbbbbSo",
    "oSbbbbbbSSSSbbbbbbSo",
    "oSbbbSSSSSSSSSSbbbSo",
    "oSbbbbbSSSSSSbbbbbSo",
    "oSbbbbbbSSSSbbbbbbSo",
    "oSbbbbbbbSSbbbbbbbSo",
    "oSbbbbbbSSSSbbbbbbSo",
    "oSbbbbbSSSSSSbbbbbSo",
    "oSbbbSSSSSSSSSSbbbSo",
    "oSbbbbbbSSSSbbbbbbSo",
    "oSbbbbbbbSSbbbbbbbSo",
    "oSbbbbbbbbbbbbbbbbSo",
    "oSbbbbbbbbbbbbbbbbSo",
    "oSbbbbbbbbbbbbbbbbSo",
    ".oSSSSSSSSSSSSSSSSo.",
    "..oooooooooooooooo..",
    "....................",
]
AWNING = [
    "oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo",
    "ommmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmo",
    "oMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMo",
    "ommmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmo",
    "oMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMo",
    "ommmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmo",
    "oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo",
    "o.o.o.o.o.o.o.o.o.o.o.o.o.o.o.o.o.o.o.o.o.o.o.o.o.o.o.o.o.o.",
]
NEON_TUBE_H = ["oooooooooooooooooooooooooooooooooooooooo", "occccccccccccccccccccccccccccccccccccccco", "oooooooooooooooooooooooooooooooooooooooo"]
NEON_TUBE_M = [r.replace("c", "m") for r in NEON_TUBE_H]
BODY = [   # a dead worker, for the sump and the closet — lying down, 32 wide
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "................................",
    "......ooooo.....................",
    ".....olllllooooooooooooooooo....",
    "....olLLLllouuuuuuuuuuuuukkko...",
    "....ollllllouUUuuuuuuuuuukkko...",
    ".....olllllouuuuuuuuuuuuuooo....",
    "......ooooo.oooooooooooooo......",
]


if __name__ == "__main__":
    items = {
        "save_terminal": SAVE_TERMINAL, "chest": CHEST, "program_terminal": PROGRAM_TERMINAL,
        "gadget_crate": GADGET_CRATE, "implant_crate": IMPLANT_CRATE, "hp_up": HP_UP, "ram_up": RAM_UP,
        "chip": CHIP, "door_frame": DOOR_FRAME, "breach_door": BREACH_DOOR, "grate": GRATE,
        "lift_deck": LIFT_DECK, "tease_crate": TEASE_CRATE, "sign_panel": SIGN_PANEL,
        "sign_panel_warn": SIGN_PANEL_WARN, "breach_terminal": BREACH_TERMINAL,
        "pipe_h": PIPE_H, "pipe_v": PIPE_V, "vent": VENT, "poster_a": POSTER_A, "poster_b": POSTER_B,
        "lamp": LAMP, "window": WINDOW, "crates": CRATES, "barrel": BARREL, "monitor": MONITOR,
        "cable": CABLE, "fan": FAN, "awning": AWNING, "neon_tube_c": NEON_TUBE_H, "neon_tube_m": NEON_TUBE_M,
        "body": BODY,
    }
    imgs = []
    for name, rows in items.items():
        w = max(len(r) for r in rows)
        rows = [r.ljust(w, ".")[:w] for r in rows]
        imgs.append(emit(name, rows))
    # one preview sheet, padded to a common height
    from PIL import Image
    H = max(i.height for i in imgs)
    W = sum(i.width + 4 for i in imgs)
    out = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    x = 0
    for i in imgs:
        out.paste(i, (x, H - i.height))
        x += i.width + 4
    preview(out, os.path.join(HERE, "preview_props.png"), 4)
    print("props written:", len(items))
