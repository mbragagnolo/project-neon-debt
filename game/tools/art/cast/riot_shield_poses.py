"""The Riot shield: one part, one frame. It is a plain Sprite2D in riot.tscn
(Facing/Shield), not a PixelAnim, so the sheet is a single frame and the
clip table is only what the bake prints."""


def clips(rig):
    return {"idle": {"frames": [{"rot": {}, "offset_art": (0, 0)}], "fps": 0.0, "loop": False, "grounded": False}}
