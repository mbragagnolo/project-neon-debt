"""Neon Debt's screen furniture as ASCII grids, one character per art pixel.

Moved here from `game/tools/art/make_fx.py`, where the interface had been
sitting inside the effects script since M7. The ui-artist's `sprites.py`
reads this file, draws every grid against the project's palette and writes
the PNGs pre-scaled, so the frames are authored where the rest of the
interface is and not beside the hit sparks.

Every grid is art pixels. The PNGs land at `assets/ui/<name>.png` scaled by
`ui.json`'s `scale` (3), so an 8x8 grid is a 24x24 texture and a nine-patch
margin of 6 texture px is 2 art px.
"""

# The legend is the effects script's, unchanged, minus the characters no
# interface grid uses. A character maps to a key in the project's palette.
LEGEND = {
    "o": "outline",
    "a": "amber",
    "w": "white",
    "S": "steel3",
    "b": "bg0",
    "B": "bg1",
}

GRIDS = {
    # The HUD's frame: a lit steel ring on a lifted ground, behind the bars.
    "hud_frame": [
        "oSSSSSSo",
        "SBBBBBBS",
        "SBBBBBBS",
        "SBBBBBBS",
        "SBBBBBBS",
        "SBBBBBBS",
        "SBBBBBBS",
        "oSSSSSSo",
    ],
    # The menus' frame: the same ring with its corners cut, on the darkest
    # ground, so a panel over a room reads as a hole and not as a sticker.
    "panel_frame": [
        "ooSSSSoo",
        "oSbbbbSo",
        "SbbbbbbS",
        "SbbbbbbS",
        "SbbbbbbS",
        "SbbbbbbS",
        "oSbbbbSo",
        "ooSSSSoo",
    ],
    # Ammo. On is amber with a white core so a full magazine reads at a
    # glance; off keeps the ring so the count of slots never changes.
    "pip_on": ["oooooo", "oaaaao", "oawwao", "oaaaao", "oaaaao", "oooooo"],
    "pip_off": ["oooooo", "oBBBBo", "oBBBBo", "oBBBBo", "oBBBBo", "oooooo"],
    # The quickslot, the one frame big enough to hold a word.
    "slot": [
        "oSSSSSSSSSSSSSSSSSSSSSSo",
        "SbbbbbbbbbbbbbbbbbbbbbbS",
        "SbbbbbbbbbbbbbbbbbbbbbbS",
        "SbbbbbbbbbbbbbbbbbbbbbbS",
        "SbbbbbbbbbbbbbbbbbbbbbbS",
        "SbbbbbbbbbbbbbbbbbbbbbbS",
        "SbbbbbbbbbbbbbbbbbbbbbbS",
        "SbbbbbbbbbbbbbbbbbbbbbbS",
        "SbbbbbbbbbbbbbbbbbbbbbbS",
        "SbbbbbbbbbbbbbbbbbbbbbbS",
        "SbbbbbbbbbbbbbbbbbbbbbbS",
        "SbbbbbbbbbbbbbbbbbbbbbbS",
        "SbbbbbbbbbbbbbbbbbbbbbbS",
        "SbbbbbbbbbbbbbbbbbbbbbbS",
        "SbbbbbbbbbbbbbbbbbbbbbbS",
        "SbbbbbbbbbbbbbbbbbbbbbbS",
        "SbbbbbbbbbbbbbbbbbbbbbbS",
        "SbbbbbbbbbbbbbbbbbbbbbbS",
        "SbbbbbbbbbbbbbbbbbbbbbbS",
        "SbbbbbbbbbbbbbbbbbbbbbbS",
        "SbbbbbbbbbbbbbbbbbbbbbbS",
        "SbbbbbbbbbbbbbbbbbbbbbbS",
        "SbbbbbbbbbbbbbbbbbbbbbbS",
        "oSSSSSSSSSSSSSSSSSSSSSSo",
    ],
    # The pointer. Outlined on every side, because it crosses both the
    # darkest room and the brightest sign.
    "cursor": ["o.......", "oo......", "owo.....", "owwo....", "owwwo...", "owwo....", "owo.....", "oo......"],
    # A locked door, a locked slot, a locked hack: one shape everywhere.
    "lock": ["..oooo..", ".oaaaao.", ".oa..ao.", "oaaaaaao", "oaaooaao", "oaaooaao", "oaaaaaao", ".oooooo."],
}
