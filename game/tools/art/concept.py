"""Room concept: one composed still of a room from its brief, read for its
layout and cut into elements (docs/art/environment.md, section 4).

    python tools/art/concept.py unit_14c gen --seeds 1-10 [--variant flat]
    python tools/art/concept.py unit_14c sheet [--variant flat]
    python tools/art/concept.py unit_14c cut                 # the chosen still -> source/<room>/<element>.png + a box overlay
    python tools/art/concept.py unit_14c props --seeds 1-4   # a still per hi-bit element on a flat ground, sheet at target size
    python tools/art/concept.py unit_14c props --seeds 1-4 --only piano,crt
    python tools/art/concept.py unit_14c bake [--only piano] [--work-only]

Reads `tools/art/sets/<room>.json` (kind "concept"). Stills land in
`work/concepts/<room>/[<variant>/]still_<seed>.png` with a contact sheet at
half size, two columns, because a concept is judged for what is where and
how the light falls, not for its pixels. The characters' lesson applies in
reverse here: NoobAI composes a subject, which is exactly what a concept
needs.

The pick goes into the json as `chosen_variant` / `chosen_seed`. The cut
list (`elements`: name, box on the still, plane, method) drives the rest:
`cut` crops every box into `source/<room>/` as the reference each artist
reads; `props` generates each `hibit` element as its own still on a flat
ground (a composed scene cannot be keyed, a prop on grey can) with the
concept crop beside every candidate at target size; `bake` keys the chosen
still and runs it through the character downscale to `assets/props/`. The
heights come from the figure, not from the concept's boxes.
"""
import argparse
import json
import os
import sys
import time

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import gen_still  # noqa: E402
import rig  # noqa: E402
import swatch  # noqa: E402
from pixel import save as save_scaled  # noqa: E402

SETS = os.path.join(HERE, "sets")
WORK = os.path.join(HERE, "work", "concepts")
SOURCE = os.path.join(HERE, "source")


def load_set(name):
    return json.load(open(os.path.join(SETS, f"{name}.json"), encoding="utf-8"))


def save_set(name, spec):
    json.dump(spec, open(os.path.join(SETS, f"{name}.json"), "w", encoding="utf-8"), indent=2)


def work_dir(name, variant=""):
    d = os.path.join(WORK, name, variant) if variant else os.path.join(WORK, name)
    os.makedirs(d, exist_ok=True)
    open(os.path.join(HERE, "work", ".gdignore"), "a").close()
    return d


def chosen_still(spec):
    still = spec["still"]
    variant = still.get("chosen_variant", "")
    seed = still.get("chosen_seed")
    if seed is None:
        sys.exit("no chosen_seed in the set json")
    path = os.path.join(work_dir(spec["name"], variant), f"still_{seed}.png")
    return Image.open(path).convert("RGB"), variant, seed


def elements(spec, only=None):
    names = set(only.split(",")) if only else None
    return [e for e in spec["elements"] if names is None or e["name"] in names]


# --- The pipeline, shared with swatch.py ------------------------------------------------

def load_pipe(still):
    t0 = time.time()
    if still.get("family") == "sd15":
        pipe, encoder = swatch.load_sd15(still["model"]), None
    else:
        pipe = gen_still.load_pipeline(still["model"])
        encoder = gen_still.Encoder(pipe)
    print(f"pipeline ready in {time.time() - t0:.0f}s", flush=True)
    return pipe, encoder


def run_still(pipe, encoder, still, seed):
    if encoder is None:
        return swatch.generate_sd15(pipe, still, seed)
    return gen_still.generate(pipe, encoder, still, seed)


# --- Concept ---------------------------------------------------------------------------

def cmd_gen(spec, args):
    still = swatch.still_cfg(spec, args.variant)
    out_dir = work_dir(spec["name"], args.variant)
    seeds = gen_still.parse_seeds(args.seeds)
    import diffusers
    import torch

    pipe, encoder = load_pipe(still)
    for seed in seeds:
        path = os.path.join(out_dir, f"still_{seed}.png")
        if os.path.exists(path):
            print(f"seed {seed}: exists, skipping", flush=True)
            continue
        t1 = time.time()
        run_still(pipe, encoder, still, seed).save(path)
        peak = torch.cuda.max_memory_allocated() / 2**30 if torch.cuda.is_available() else 0
        print(f"seed {seed}: {time.time() - t1:.0f}s, peak {peak:.2f} GiB -> {path}", flush=True)
    json.dump({**still, "seeds": seeds, "diffusers": diffusers.__version__, "torch": torch.__version__},
              open(os.path.join(out_dir, "stills.json"), "w"), indent=2)
    cmd_sheet(spec, args)


def cmd_sheet(spec, args):
    out_dir = work_dir(spec["name"], args.variant)
    cells = []
    for f in sorted(os.listdir(out_dir), key=lambda s: (len(s), s)):
        if not (f.startswith("still_") and f.endswith(".png")):
            continue
        seed = f[6:-4]
        img = Image.open(os.path.join(out_dir, f)).convert("RGB")
        half = img.resize((img.width // 2, img.height // 2), Image.LANCZOS)
        cell = Image.new("RGB", (half.width, half.height + 20), (18, 20, 28))
        cell.paste(half, (0, 20))
        ImageDraw.Draw(cell).text((4, 4), f"seed {seed}", fill=(255, 220, 80))
        cells.append(cell)
    if not cells:
        print("no stills in", out_dir)
        return
    cw, ch = cells[0].width, cells[0].height
    cols = 2
    rows = (len(cells) + cols - 1) // cols
    sheet = Image.new("RGB", (cw * cols + 8 * (cols - 1), ch * rows + 8 * (rows - 1)), (10, 12, 18))
    for n, c in enumerate(cells):
        sheet.paste(c, ((n % cols) * (cw + 8), (n // cols) * (ch + 8)))
    path = os.path.join(out_dir, f"contact{'_' + args.tag if args.tag else ''}.png")
    sheet.save(path)
    print("contact sheet:", path)


# --- The cut ---------------------------------------------------------------------------

def cmd_cut(spec, args):
    """Every element's box cropped out of the chosen still into source/<room>/,
    and the still with the boxes drawn on it, to check the list."""
    still, variant, seed = chosen_still(spec)
    out_dir = os.path.join(SOURCE, spec["name"])
    os.makedirs(out_dir, exist_ok=True)
    still.save(os.path.join(out_dir, "concept.png"))
    overlay = still.copy()
    d = ImageDraw.Draw(overlay)
    colours = {"outside": (120, 200, 255), "back": (255, 220, 80), "play": (255, 120, 80), "near": (200, 120, 255)}
    for e in spec["elements"]:
        if not e.get("box"):
            continue
        x0, y0, x1, y1 = e["box"]
        still.crop((x0, y0, x1, y1)).save(os.path.join(out_dir, f"{e['name']}.png"))
        c = colours.get(e["plane"], (255, 255, 255))
        d.rectangle([x0, y0, x1 - 1, y1 - 1], outline=c, width=2)
        d.text((x0 + 4, y0 + 3), f"{e['name']} [{e['plane']}/{e['method']}]", fill=c)
    path = os.path.join(work_dir(spec["name"]), "cut_debug.png")
    overlay.save(path)
    print(f"{len(spec['elements'])} elements -> {out_dir}; overlay {path}")


# --- Prop stills --------------------------------------------------------------------------

def prop_cfg(spec, element):
    base = dict(spec["prop_still"])
    cfg = {k: v for k, v in base.items() if not k.startswith("_") and k != "prefix"}
    cfg["prompt"] = base.get("prefix", "") + element["prompt"]
    cfg["negative"] = element.get("negative", base["negative"])
    return cfg


def cmd_props(spec, args):
    props = [e for e in elements(spec, args.only) if e.get("prompt") and e["method"] in ("hibit", "plane")]
    seeds = gen_still.parse_seeds(args.seeds)
    import torch

    pipe, encoder = load_pipe(spec["prop_still"])
    for e in props:
        out_dir = work_dir(spec["name"], os.path.join("props", e["name"]))
        cfg = prop_cfg(spec, e)
        for seed in seeds:
            path = os.path.join(out_dir, f"still_{seed}.png")
            if os.path.exists(path):
                continue
            t1 = time.time()
            run_still(pipe, encoder, cfg, seed).save(path)
            peak = torch.cuda.max_memory_allocated() / 2**30 if torch.cuda.is_available() else 0
            print(f"{e['name']} seed {seed}: {time.time() - t1:.0f}s, peak {peak:.2f} GiB", flush=True)
        json.dump({**cfg, "seeds": seeds}, open(os.path.join(out_dir, "stills.json"), "w"), indent=2)
    cmd_prop_sheet(spec, args)


def cmd_prop_sheet(spec, args):
    """One row per element: the concept crop at target size, then every
    candidate at target size (content bbox scaled to `height_art`, at 2x),
    so the pick is made at the size the prop will have next to Dani."""
    scale = int(spec["target"].get("scale", 2))
    rows = []
    for e in elements(spec, args.only):
        if not (e.get("prompt") and e["method"] in ("hibit", "plane")):
            continue
        out_dir = work_dir(spec["name"], os.path.join("props", e["name"]))
        cells = []
        ref = os.path.join(SOURCE, spec["name"], f"{e['name']}.png")
        if os.path.exists(ref):
            crop = Image.open(ref).convert("RGB")
            ratio = e["height_art"] * scale / crop.height
            cells.append(("concept", crop.resize((max(1, round(crop.width * ratio)), e["height_art"] * scale), Image.LANCZOS)))
        for f in sorted(os.listdir(out_dir), key=lambda s: (len(s), s)):
            if f.startswith("still_") and f.endswith(".png"):
                img = Image.open(os.path.join(out_dir, f)).convert("RGB")
                cells.append((f"seed {f[6:-4]}", gen_still.target_preview(img, e["height_art"], scale)))
        if not cells:
            continue
        h = max(c.height for _, c in cells) + 22
        w = sum(c.width + 16 for _, c in cells) + 140
        row = Image.new("RGB", (w, h), (18, 20, 28))
        d = ImageDraw.Draw(row)
        d.text((4, 4), f"{e['name']}  {e['height_art']} art px", fill=(255, 220, 80))
        x = 140
        for label, c in cells:
            row.paste(c, (x, h - c.height))
            d.text((x, 4), label, fill=(200, 200, 200))
            x += c.width + 16
        rows.append(row)
    if not rows:
        print("no prop stills")
        return
    dani = os.path.join(os.path.dirname(os.path.dirname(HERE)), "assets", "sprites", "player.png")
    frame = Image.open(dani).convert("RGBA").crop((0, 0, 96, 128)) if os.path.exists(dani) else None
    W = max(r.width for r in rows) + (frame.width + 16 if frame else 0)
    H = sum(r.height + 6 for r in rows)
    sheet = Image.new("RGB", (W, H), (10, 12, 18))
    y = 0
    for r in rows:
        sheet.paste(r, (0, y))
        if frame:
            sheet.paste(frame, (W - frame.width - 8, y + r.height - frame.height), frame)
        y += r.height + 6
    path = os.path.join(work_dir(spec["name"]), "props_contact.png")
    sheet.save(path)
    print("prop sheet:", path)


# --- Bake ---------------------------------------------------------------------------------

def cmd_bake(spec, args):
    """Key the chosen prop still, scale it so its content is `height_art`
    tall at still resolution, downscale with the character settings, save at
    2x to assets/props/<room>_<name>.png (or work/ with --work-only)."""
    target = spec["target"]
    scale = int(target.get("scale", 2))
    out_dir = work_dir(spec["name"], "bakes")
    baked = []
    for e in elements(spec, args.only):
        if e["method"] != "hibit" or e.get("chosen_seed") is None:
            continue
        path = os.path.join(work_dir(spec["name"], os.path.join("props", e["name"])), f"still_{e['chosen_seed']}.png")
        still = Image.open(path).convert("RGB")
        keyed = rig.key_background(still, tolerance=int(e.get("key_tolerance", 30)), seeds=e.get("key_seeds", ()))
        bbox = rig.content_bbox(keyed)
        crop = keyed.crop(bbox)
        art_h = int(e["height_art"])
        art_w = max(1, round(crop.width * art_h / crop.height))
        # the character pipeline expects the still on a canvas whose blocks map to art px
        art = rig.downscale(crop, (art_w, art_h), target)
        baked.append((e["name"], art))
        art.save(os.path.join(out_dir, f"{e['name']}.png"))
        if not args.work_only:
            save_scaled(art, f"props/{spec['name']}_{e['name']}.png", scale=scale)
        print(f"{e['name']}: {art_w}x{art_h} art px, {rig.colour_count(art)} colours")
    if baked:
        z = 3
        w = sum(a.width * z + 12 for _, a in baked)
        h = max(a.height for _, a in baked) * z + 20
        sheet = Image.new("RGBA", (w, h), (30, 34, 44, 255))
        x = 0
        for name, a in baked:
            sheet.alpha_composite(a.resize((a.width * z, a.height * z), Image.NEAREST), (x, h - a.height * z))
            ImageDraw.Draw(sheet).text((x, 2), name, fill=(255, 220, 80))
            x += a.width * z + 12
        sheet.save(os.path.join(out_dir, "bakes.png"))


# --- Planes -------------------------------------------------------------------------------

def element(spec, name):
    for e in spec["elements"]:
        if e["name"] == name:
            return e
    sys.exit(f"no element {name}")


def cmd_inpaint(spec, args):
    """The play-plane props painted out of the chosen still, so the back wall
    plane is the wall alone: the boxes named in the wall element's `inpaint`
    list become a mask, dilated, and the model refills them from the wall
    around them with the flat prompt minus the props."""
    import numpy as np
    import torch
    from diffusers import EulerAncestralDiscreteScheduler, StableDiffusionXLInpaintPipeline

    still, variant, seed = chosen_still(spec)
    wall = element(spec, "wall")
    mask = Image.new("L", still.size, 0)
    d = ImageDraw.Draw(mask)
    pad = int(wall.get("inpaint_pad", 14))
    for name in wall.get("inpaint", []):
        x0, y0, x1, y1 = element(spec, name)["box"]
        d.rectangle([x0 - pad, y0 - pad, x1 + pad, y1 + pad], fill=255)
    out_dir = work_dir(spec["name"], "wall")
    mask.save(os.path.join(out_dir, "mask.png"))
    cfg = swatch.still_cfg(spec, variant)
    cfg = dict(cfg)
    cfg["prompt"] = wall.get("inpaint_prompt", cfg["prompt"])
    cfg["negative"] = wall.get("inpaint_negative", cfg["negative"])
    t0 = time.time()
    pipe = StableDiffusionXLInpaintPipeline.from_pretrained(
        cfg["model"], torch_dtype=torch.float16, local_files_only=True, use_safetensors=True
    )
    pipe.scheduler = EulerAncestralDiscreteScheduler.from_config(pipe.scheduler.config)
    pipe.set_progress_bar_config(disable=True)
    if torch.cuda.is_available():
        pipe.enable_model_cpu_offload()
        pipe.enable_vae_tiling()
    encoder = gen_still.Encoder(pipe)
    print(f"inpaint pipeline ready in {time.time() - t0:.0f}s", flush=True)
    for s in gen_still.parse_seeds(args.seeds):
        t1 = time.time()
        g = torch.Generator("cuda" if torch.cuda.is_available() else "cpu").manual_seed(s)
        result = pipe(image=still, mask_image=mask, width=still.width, height=still.height,
                      strength=float(wall.get("inpaint_strength", 0.95)), num_inference_steps=cfg["steps"],
                      guidance_scale=cfg["cfg"], generator=g, **encoder.kwargs(cfg["prompt"], cfg["negative"])).images[0]
        # keep the original outside the mask exactly; the model may drift elsewhere
        m = np.array(mask.resize(result.size))[..., None] / 255.0
        merged = np.array(still.resize(result.size)) * (1 - m) + np.array(result) * m
        path = os.path.join(out_dir, f"inpaint_{s}.png")
        Image.fromarray(merged.astype(np.uint8)).save(path)
        print(f"inpaint seed {s}: {time.time() - t1:.0f}s -> {path}", flush=True)


def plane_art(crop, art_size, cfg):
    """A crop of the concept as a far plane: a box downscale (a plane is seen
    blurred, the k-centroid's hard edges would fight that), then the palette
    snap. `cfg` may carry `levels` like the swatch tool's."""
    if cfg.get("levels"):
        crop = swatch.levels(crop, cfg["levels"])
    t = {"downscale": cfg.get("downscale", "box"), "k": cfg.get("k", 2), "accent": cfg.get("accent"),
         "lines": cfg.get("lines"), "edge": 1.0, "palette": cfg.get("palette")}
    return rig.downscale(crop.convert("RGBA"), art_size, t)


def wall_plane(spec, still, wall, window, art_w, art_h):
    """The back wall authored at plane resolution: the ring's plaster noise
    in a dark ramp, the concept's pilasters, the window frame with its glass
    cut out, pale rectangles where things were taken, a wiring run along the
    top, and the pieces the concept keeps on the wall (shelf, pinboard)
    pasted from their crops."""
    import numpy as np
    import ring
    from pixel import PALETTE

    wx0, wy0, wx1, wy1 = wall["box"]
    fx, fy = art_w / (wx1 - wx0), art_h / (wy1 - wy0)

    def to_plane(box):
        return (int((box[0] - wx0) * fx), int((box[1] - wy0) * fy), int((box[2] - wx0) * fx), int((box[3] - wy0) * fy))

    rng = np.random.default_rng(int(wall.get("seed", 3)))
    size = max(art_w, art_h)
    size += (-size) % 60
    field = ring.mottle(size, wall.get("noise", {"cells": [6, 12, 30, 60], "weights": [0.3, 0.3, 0.25, 0.15], "grain": 0.1}), rng)[:art_h, :art_w]
    ramp = wall.get("ramp", ["bg0", "bg1", "bg2", "bg3"])
    base = ramp.index(wall.get("base", "bg2"))
    th = wall.get("steps", {"dark": 0.3, "light": 0.85})
    step = np.full((art_h, art_w), base)
    step[field < th["dark"]] = base - 1
    step[field > th["light"]] = base + 1
    # a darker band under the ceiling and a grime band above the floor
    step[:3] = np.minimum(step[:3], base - 1)
    step[art_h - 4:][field[art_h - 4:] < 0.6] = base - 1
    lut = np.array([PALETTE[k] for k in ramp], dtype=np.uint8)
    rgb = lut[np.clip(step, 0, len(ramp) - 1)]
    alpha = np.full((art_h, art_w), 255, dtype=np.uint8)

    def fill(box, key, edge_l=None, edge_r=None):
        x0, y0, x1, y1 = box
        rgb[y0:y1, x0:x1] = PALETTE[key]
        if edge_l:
            rgb[y0:y1, x0] = PALETTE[edge_l]
        if edge_r:
            rgb[y0:y1, x1 - 1] = PALETTE[edge_r]

    pil = wall.get("pilaster", {"fill": "bg1", "lit": "bg3", "shade": "bg0"})
    for px0, px1 in wall.get("pilasters", []):
        x0, x1 = int((px0 - wx0) * fx), int((px1 - wx0) * fx)
        fill((x0, 0, x1, art_h), pil["fill"], pil["lit"], pil["shade"])
        # panel noise inside the pilaster too
        band = rgb[:, x0:x1]
        band[field[:, x0:x1] < 0.25] = PALETTE[pil["shade"]]
    pale_keys = wall.get("pale_keys", ["bg3", "bg2"])
    for box in wall.get("pale", []):
        x0, y0, x1, y1 = to_plane(box)
        rgb[y0:y1, x0:x1] = PALETTE[pale_keys[0]]
        rgb[y0:y1, x0:x1][field[y0:y1, x0:x1] < 0.4] = PALETTE[pale_keys[1]]
        rgb[y0, x0:x1] = PALETTE[pale_keys[1]]
        rgb[y0:y1, x0] = PALETTE[pale_keys[1]]
    # the wiring run the brief asks for: two lines along the top with clips
    run_y = int(wall.get("wiring_y", 6))
    rgb[run_y, :] = PALETTE["steel1"]
    rgb[run_y + 1, :] = PALETTE["steel0"]
    for x in range(8, art_w, 40):
        rgb[run_y - 1:run_y + 3, x:x + 2] = PALETTE["steel0"]
    # the pieces the concept keeps on the wall, from their crops
    for name in wall.get("keep", []):
        e = element(spec, name)
        if name == "window":
            continue
        x0, y0, x1, y1 = to_plane(e["box"])
        crop = still.crop(tuple(e["box"]))
        piece = plane_art(crop, (max(1, x1 - x0), max(1, y1 - y0)), {"downscale": "box", "palette": wall.get("palette")})
        rgb[y0:y1, x0:x1] = np.array(piece)[..., :3]
    # the window: a frame around the glass, mullions across it, the glass cut out
    gx0, gy0, gx1, gy1 = to_plane(window["box"])
    gy0 = max(gy0, 0)
    frame = int(wall.get("frame", 3))
    fill((gx0, gy0, gx1, gy1), "black")
    rgb[gy0, gx0:gx1] = PALETTE["bg1"]
    rgb[gy0:gy1, gx0] = PALETTE["bg1"]
    rgb[gy1 - 1, gx0:gx1] = PALETTE["black_l"]
    rgb[gy0:gy1, gx1 - 1] = PALETTE["black_l"]
    ix0, iy0, ix1, iy1 = gx0 + frame, gy0 + frame, gx1 - frame, gy1 - frame
    alpha[iy0:iy1, ix0:ix1] = 0
    for mx in wall.get("mullions_x", [840]):
        x = int((mx - wx0) * fx)
        alpha[iy0:iy1, x - 1:x + 1] = 255
        rgb[iy0:iy1, x - 1:x + 1] = PALETTE["black"]
    for my in wall.get("mullions_y", [320]):
        y = int((my - wy0) * fy)
        alpha[y - 1:y + 1, ix0:ix1] = 255
        rgb[y - 1:y + 1, ix0:ix1] = PALETTE["black"]
    out = np.dstack([rgb, alpha]).astype(np.uint8)
    return Image.fromarray(out, "RGBA"), (ix0, iy0, ix1, iy1)


def skyline_block(w, h, cfg):
    """The block opposite, authored: a night sky falling from void to the
    ramp's top, towers as flat silhouettes near enough to fill the glass,
    rows of small windows mostly dark, a few lit cold and one or two warm.
    The rain is the engine's (particles over the glass)."""
    import numpy as np
    from pixel import PALETTE

    rng = np.random.default_rng(int(cfg.get("seed", 5)))
    sky = cfg.get("sky", ["void", "bg0", "bg1", "bg2"])
    img = Image.new("RGBA", (w, h), PALETTE[sky[0]] + (255,))
    px = img.load()
    for y in range(h):
        t = y / max(1, h - 1)
        k = min(len(sky) - 1, int(t * len(sky)))
        for x in range(w):
            if rng.random() < 0.985:
                px[x, y] = PALETTE[sky[k]] + (255,)
    towers = cfg.get("towers", {"width": [22, 48], "height": [0.45, 0.95], "gap": [0, 4], "body": "bg1", "edge": "bg2",
                                 "lit": "steel3", "lit_cold": "cyan_d", "lit_warm": "amber_d", "density": 0.12, "pitch": 4})
    x = -int(rng.integers(0, 10))
    while x < w:
        tw = int(rng.integers(*towers["width"]))
        th = int(h * rng.uniform(*towers["height"]))
        top = h - th
        for yy in range(top, h):
            for xx in range(max(0, x), min(w, x + tw)):
                px[xx, yy] = PALETTE[towers["body"]] + (255,)
        for xx in range(max(0, x), min(w, x + tw)):
            px[xx, top] = PALETTE[towers["edge"]] + (255,)
        if 0 <= x < w:
            for yy in range(top, h):
                px[x, yy] = PALETTE[towers["edge"]] + (255,)
        pitch = int(towers.get("pitch", 4))
        for yy in range(top + 3, h - 1, pitch):
            for xx in range(x + 2, x + tw - 1, pitch):
                if 0 <= xx < w and rng.random() < towers["density"]:
                    key = towers["lit_warm"] if rng.random() < 0.15 else (towers["lit_cold"] if rng.random() < 0.3 else towers["lit"])
                    px[xx, yy] = PALETTE[key] + (255,)
        x += tw + int(rng.integers(*towers["gap"]))
    return img


def cmd_planes(spec, args):
    """The back wall (authored on the concept's layout) and the outside (its
    own still, or the concept's glass mirrored until there is one) as planes
    at their own pixel size, written to assets/tiles/. Updates the room's
    dress json with where the outside plane sits."""
    import numpy as np

    still, variant, seed = chosen_still(spec)
    wall = element(spec, "wall")
    window = element(spec, "window")
    outside = element(spec, "outside")
    out_dir = work_dir(spec["name"], "planes")
    room = wall.get("room", [60, 420, 1860, 1020])
    px = int(wall.get("px", 3))
    art_w, art_h = (room[2] - room[0]) // px, (room[3] - room[1]) // px
    wall_art, glass = wall_plane(spec, still, wall, window, art_w, art_h)
    wall_art.save(os.path.join(out_dir, "back_wall.png"))
    save_scaled(wall_art, f"tiles/back_{spec['name']}.png", scale=px)
    # the outside fills the glass at its own coarser pixel
    opx = int(outside.get("px", 4))
    ow, oh = (glass[2] - glass[0]) * px // opx, (glass[3] - glass[1]) * px // opx
    chosen = outside.get("chosen_seed")
    src_path = os.path.join(work_dir(spec["name"], os.path.join("props", "outside")), f"still_{chosen}.png") if chosen else ""
    if outside["method"] == "pixel":
        outside_art = skyline_block(ow, oh, outside)
    elif chosen and os.path.exists(src_path):
        outside_art = plane_art(Image.open(src_path).convert("RGB"), (ow, oh), outside)
    else:
        print("no outside still chosen: the concept's glass, its clean half mirrored")
        gx0, gy0, gx1, gy1 = outside["box"]
        half = still.crop((gx0, gy0, gx0 + (gx1 - gx0) * 3 // 5, gy1))
        src = Image.new("RGB", (half.width * 2, half.height))
        src.paste(half, (0, 0))
        src.paste(half.transpose(Image.FLIP_LEFT_RIGHT), (half.width, 0))
        outside_art = plane_art(src, (ow, oh), outside)
    outside_art.save(os.path.join(out_dir, "outside.png"))
    save_scaled(outside_art, f"tiles/outside_{spec['name']}.png", scale=opx)
    at = [room[0] + glass[0] * px, room[1] + glass[1] * px]
    dress_path = os.path.join(os.path.dirname(HERE), "stacks", f"{spec['name']}.dress.json")
    if os.path.exists(dress_path):
        dress = json.load(open(dress_path, encoding="utf-8"))
        for plane in dress.get("planes", []):
            if plane.get("name") == "outside":
                plane["at"] = at
            if plane.get("name") == "back_wall":
                plane["at"] = [room[0], room[1]]
        json.dump(dress, open(dress_path, "w", encoding="utf-8"), indent=2)
    preview = Image.new("RGBA", wall_art.size, (7, 8, 15, 255))
    preview.alpha_composite(outside_art.resize(((glass[2] - glass[0]), (glass[3] - glass[1])), Image.NEAREST), (glass[0], glass[1]))
    preview.alpha_composite(wall_art)
    preview.resize((preview.width * px, preview.height * px), Image.NEAREST).save(os.path.join(out_dir, "planes_preview.png"))
    print(f"back wall {art_w}x{art_h} art px at {px}x ({rig.colour_count(wall_art)} colours), glass {glass};"
          f" outside {ow}x{oh} art px at {opx}x ({rig.colour_count(outside_art)} colours), placed at {at}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("name")
    ap.add_argument("command", choices=["gen", "sheet", "cut", "props", "prop_sheet", "bake", "inpaint", "planes"])
    ap.add_argument("--seeds", default="1-8")
    ap.add_argument("--variant", default="")
    ap.add_argument("--only", default=None, help="comma-separated element names")
    ap.add_argument("--tag", default="")
    ap.add_argument("--work-only", action="store_true")
    args = ap.parse_args()
    spec = load_set(args.name)
    {"gen": cmd_gen, "sheet": cmd_sheet, "cut": cmd_cut, "props": cmd_props,
     "prop_sheet": cmd_prop_sheet, "bake": cmd_bake, "inpaint": cmd_inpaint, "planes": cmd_planes}[args.command](spec, args)


if __name__ == "__main__":
    main()
