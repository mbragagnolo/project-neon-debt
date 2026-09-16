"""Wall swatch: a material still from the diffusion model, downscaled to art
pixels, cut into the nine-patch the engine already tiles
(docs/art/environment.md, "Assets the pilot needs").

    python tools/art/swatch.py residential gen --seeds 1-6
    python tools/art/swatch.py residential gen --seeds 1-4 --variant sdxl
    python tools/art/swatch.py residential bake --seed 3 [--variant sdxl] [--tag t]
    python tools/art/swatch.py residential sheet [--variant sdxl]

Reads `tools/art/sets/<name>.json`. Stills land in `work/sets/<name>/`
(or `work/sets/<name>/<variant>/`) with a contact sheet that shows each
candidate at target size, because the pick is judged at 30 art px a tile,
not at 1024. The bake takes one still, makes one tile of it seamless at
full resolution, downscales it with the character pipeline's k-centroid +
line layer + palette snap, derives the eight edge tiles from it (a lit
floor lip on top, a dark ceiling underside, a lit and a shaded side) and
pushes the centre tile to the dark ramp, so only the ring of tiles that
touches air keeps its surface. Writes `assets/<sheet>` pre-scaled and a
preview slab with Dani on it in `work/sets/<name>/`.
"""
import argparse
import json
import os
import sys
import time

import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import gen_still  # noqa: E402
import rig  # noqa: E402
from pixel import PALETTE, save as save_scaled  # noqa: E402

SETS = os.path.join(HERE, "sets")
WORK = os.path.join(HERE, "work", "sets")
ASSETS = os.path.join(os.path.dirname(os.path.dirname(HERE)), "assets")


def load_set(name):
    return json.load(open(os.path.join(SETS, f"{name}.json"), encoding="utf-8"))


def still_cfg(spec, variant):
    still = dict(spec["still"])
    if variant:
        still.update(spec.get("variants", {})[variant])
    return {k: v for k, v in still.items() if not k.startswith("_")}


def work_dir(name, variant):
    d = os.path.join(WORK, name, variant) if variant else os.path.join(WORK, name)
    os.makedirs(d, exist_ok=True)
    open(os.path.join(HERE, "work", ".gdignore"), "a").close()
    return d


# --- Downscale -----------------------------------------------------------------------

def levels(img, cfg):
    """Stretch the still's tones onto the ramp before the snap. A diffusion
    texture sits in a narrow band of greys; mapped as-is it lands on one or
    two palette steps and the k-centroid vote turns it to speckle. `pct`
    picks the luma percentiles that become `lo` and `hi` (0..255), `tint`
    multiplies the channels afterwards (a cold wall: [0.9, 0.95, 1.1])."""
    a = np.array(img.convert("RGB"), dtype=np.float32)
    luma = a @ np.array(rig.LUMA, dtype=np.float32)
    p_lo, p_hi = np.percentile(luma, cfg.get("pct", [2, 98]))
    lo, hi = float(cfg.get("lo", 28)), float(cfg.get("hi", 150))
    a = (a - p_lo) * (hi - lo) / max(p_hi - p_lo, 1.0) + lo
    a *= np.array(cfg.get("tint", [1.0, 1.0, 1.0]), dtype=np.float32)
    return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), "RGB")


def art_swatch(still, target, size, lines=True):
    """The still (or a region of it) as art pixels: levels, k-centroid, the
    line layer, the palette snap. Edge shading is off: a texture has no
    silhouette."""
    if target.get("levels"):
        still = levels(still, target["levels"])
    t = {"downscale": "kcentroid", "k": target.get("k", 2), "accent": None,
         "lines": target.get("lines") if lines else None, "edge": 1.0,
         "palette": target.get("palette")}
    return rig.downscale(still.convert("RGBA"), (size, size), t)


def seamless(img, blend=0.18):
    """Make a region tile: roll it by half so its borders meet in the middle,
    then heal that cross seam with the original, which is continuous there.
    `blend` is the healing band as a fraction of the side."""
    a = np.array(img.convert("RGB"), dtype=np.float32)
    h, w = a.shape[:2]
    r = np.roll(np.roll(a, h // 2, 0), w // 2, 1)
    ys, xs = np.mgrid[0:h, 0:w]
    d = np.minimum(np.abs(xs - w / 2), np.abs(ys - h / 2))
    wgt = np.clip(1.0 - d / (blend * min(h, w)), 0.0, 1.0)[..., None]
    return Image.fromarray(np.clip(r * (1 - wgt) + a * wgt, 0, 255).astype(np.uint8), "RGB")


def flatten(img, radius):
    """High-pass: subtract the region's own blur and add its mean back. A
    diffusion still lights its wall (a bright floor band, a dark top), and a
    tile cut from it carries that gradient, which the wrap heal turns into a
    repeating blob. Stains and grain are smaller than `radius` and survive."""
    from PIL import ImageFilter
    rgb = img.convert("RGB")
    a = np.array(rgb, dtype=np.float32)
    blur = np.array(rgb.filter(ImageFilter.GaussianBlur(radius)), dtype=np.float32)
    out = a - blur + a.mean(axis=(0, 1), keepdims=True)
    return Image.fromarray(np.clip(out, 0, 255).astype(np.uint8), "RGB")


def fill_block(still, target, size=None):
    """One seamless block of the material: the region of the still that
    `block` art px cover (three tiles by default), flattened and healed at
    full resolution, then downscaled. Every region of the nine-patch is cut
    from this block, so the ring is one material and the repeat is the
    block's length, not a tile's."""
    B, S = int(size or target.get("block", 90)), int(target["swatch"])
    ppa = still.width / S
    fill = target.get("fill", {})
    ox, oy = fill.get("offset", [0, 0])
    box = (int(ox * ppa), int(oy * ppa), int((ox + B) * ppa), int((oy + B) * ppa))
    region = still.crop(box)
    if fill.get("flatten", 0.33):
        region = flatten(region, float(fill.get("flatten", 0.33)) * region.width)
    region = seamless(region, float(fill.get("blend", 0.18)))
    return art_swatch(region, target, B)


# --- The nine tiles -------------------------------------------------------------------

def tile_variant(base, kind, target):
    """An edge tile from the fill tile. `kind`: c, t, b, l, r, tl, tr, bl, br.
    Top is the floor lip (lit), bottom the ceiling underside (dark), left the
    lit side, right the shaded side; the centre is the fill pushed down the
    dark ramp so the interior of a solid falls to near-black."""
    arr = np.array(base, dtype=np.float32)
    H, W = arr.shape[:2]
    lip = target["lip"]
    if "t" in kind:
        arr[3:, :, :3] *= float(lip.get("top_face", 1.05))
        arr[2, :, :3] *= float(lip.get("top_highlight", 1.2))
        for i, key in enumerate(lip["top"]):
            arr[i, :, :3] = PALETTE[key]
    if "b" in kind:
        arr[:, :, :3] *= float(lip.get("bottom_face", 0.85))
        for i, key in enumerate(lip["bottom"]):
            arr[H - 1 - i, :, :3] = PALETTE[key]
    if "l" in kind:
        arr[:, 0, :3] *= float(lip.get("side_lit", 1.15))
        arr[:, 1, :3] *= 1.05
    if "r" in kind:
        arr[:, W - 1, :3] *= float(lip.get("side_shade", 0.85))
        arr[:, W - 2, :3] *= 0.95
    palette = target.get("palette")
    if kind == "c":
        d = target["dark"]
        tint = np.array(PALETTE[d.get("tint", "bg0")], dtype=np.float32)
        mix = float(d.get("mix", 0.5))
        arr[..., :3] = arr[..., :3] * float(d.get("factor", 0.3)) * (1 - mix) + tint * mix
        palette = d.get("palette", palette)
    img = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGBA")
    return rig.snap_to_palette(img, palette)


KINDS = [["tl", "t", "tr"], ["l", "c", "r"], ["bl", "b", "br"]]


def nine_patch(block, target):
    """Corners one tile square, edge strips the block's length, the centre the
    whole block darkened: a (T + B + T) square the engine's NinePatch reads
    with its 60 px margins unchanged."""
    T, B = int(target["tile"]), block.width
    cut = {
        "tl": block.crop((0, 0, T, T)), "t": block.crop((0, 0, B, T)), "tr": block.crop((B - T, 0, B, T)),
        "l": block.crop((0, 0, T, B)), "c": block, "r": block.crop((B - T, 0, B, B)),
        "bl": block.crop((0, B - T, T, B)), "b": block.crop((0, B - T, B, B)), "br": block.crop((B - T, B - T, B, B)),
    }
    tiles = {k: tile_variant(v, k, target) for k, v in cut.items()}
    out = Image.new("RGBA", (T + B + T, T + B + T))
    at = {"tl": (0, 0), "t": (T, 0), "tr": (T + B, 0), "l": (0, T), "c": (T, T), "r": (T + B, T),
          "bl": (0, T + B), "b": (T, T + B), "br": (T + B, T + B)}
    for k, pos in at.items():
        out.paste(tiles[k], pos)
    return out, tiles


def _tile_across(dst, src, x0, y0, x1, y1):
    """Repeat `src` over the box, clipped, the way NinePatch's tile mode does."""
    w, h = src.size
    y = y0
    while y < y1:
        x = x0
        while x < x1:
            dst.paste(src.crop((0, 0, min(w, x1 - x), min(h, y1 - y))), (x, y))
            x += w
        y += h


def slab(tiles, width, height):
    """A solid `width` x `height` art px drawn as the engine draws it: corners
    fixed, edge strips repeated along the edges, the centre repeated inside."""
    T = tiles["tl"].width
    out = Image.new("RGBA", (width, height))
    _tile_across(out, tiles["c"], T, T, width - T, height - T)
    _tile_across(out, tiles["t"], T, 0, width - T, T)
    _tile_across(out, tiles["b"], T, height - T, width - T, height)
    _tile_across(out, tiles["l"], 0, T, T, height - T)
    _tile_across(out, tiles["r"], width - T, T, width, height - T)
    out.paste(tiles["tl"], (0, 0))
    out.paste(tiles["tr"], (width - T, 0))
    out.paste(tiles["bl"], (0, height - T))
    out.paste(tiles["br"], (width - T, height - T))
    return out


def preview(tiles, target, out_path):
    """A room corner at screen pixels, then 2x for looking: the slab above,
    a wall on the left, the floor, air between, Dani on the floor. The three
    solids are separate rectangles, as the room generator carves them, so
    their rings meet the way they do in the game."""
    scale = int(target["scale"])
    T = tiles["tl"].width
    cols, floor_rows, ceil_rows, air_rows, wall_cols = 14, 3, 3, 6, 2
    W, H = cols * T, (ceil_rows + air_rows + floor_rows) * T
    art = Image.new("RGBA", (W, H), PALETTE["bg1"] + (255,))
    art.paste(slab(tiles, W, ceil_rows * T), (0, 0))
    art.paste(slab(tiles, wall_cols * T, air_rows * T), (0, ceil_rows * T))
    art.paste(slab(tiles, W, floor_rows * T), (0, (ceil_rows + air_rows) * T))
    screen = art.resize((art.width * scale, art.height * scale), Image.NEAREST)
    player = os.path.join(ASSETS, "sprites", "player.png")
    if os.path.exists(player):
        sheet_img = Image.open(player).convert("RGBA")
        frame = sheet_img.crop((0, 0, 96, min(128, sheet_img.height)))
        floor_y = (ceil_rows + air_rows) * T * scale
        screen.alpha_composite(frame, (wall_cols * T * scale + 120, floor_y - frame.height))
    big = screen.resize((screen.width * 2, screen.height * 2), Image.NEAREST)
    z = 3
    order = ["tl", "t", "tr", "l", "c", "r", "bl", "b", "br"]
    strip_w = sum(tiles[k].width * z + 6 for k in order)
    strip_h = max(tiles[k].height for k in order) * z + 20
    strip = Image.new("RGBA", (strip_w, strip_h), (10, 12, 18, 255))
    x = 0
    for kind in order:
        t = tiles[kind]
        strip.paste(t.resize((t.width * z, t.height * z), Image.NEAREST), (x, 20))
        ImageDraw.Draw(strip).text((x + 2, 4), kind, fill=(255, 220, 80))
        x += t.width * z + 6
    page = Image.new("RGBA", (max(big.width, strip.width), big.height + strip.height + 10), (10, 12, 18, 255))
    page.paste(strip, (0, 0))
    page.paste(big, (0, strip.height + 10))
    page.save(out_path)
    return out_path


# --- Commands --------------------------------------------------------------------------

def load_sd15(model_id):
    """The Stable Diffusion 1.5 family (DreamShaper 8), same 8 GB config as the
    SDXL loader. Texture prompts fit in 77 tokens, so no compel here."""
    import torch
    from diffusers import EulerAncestralDiscreteScheduler, StableDiffusionPipeline

    pipe = StableDiffusionPipeline.from_pretrained(
        model_id, torch_dtype=torch.float16, local_files_only=True, safety_checker=None
    )
    pipe.scheduler = EulerAncestralDiscreteScheduler.from_config(pipe.scheduler.config)
    pipe.set_progress_bar_config(disable=True)
    if torch.cuda.is_available():
        pipe.enable_model_cpu_offload()
        pipe.enable_vae_tiling()
    return pipe


def generate_sd15(pipe, still, seed):
    import torch

    g = torch.Generator("cuda" if torch.cuda.is_available() else "cpu").manual_seed(seed)
    return pipe(prompt=still["prompt"], negative_prompt=still["negative"], width=still["width"],
                height=still["height"], num_inference_steps=still["steps"], guidance_scale=still["cfg"],
                generator=g).images[0]


def cmd_gen(spec, args):
    still = still_cfg(spec, args.variant)
    out_dir = work_dir(spec["name"], args.variant)
    seeds = gen_still.parse_seeds(args.seeds)
    import diffusers
    import torch

    t0 = time.time()
    sd15 = still.get("family") == "sd15"
    if sd15:
        pipe = load_sd15(still["model"])
    else:
        pipe = gen_still.load_pipeline(still["model"])
        encoder = gen_still.Encoder(pipe)
    print(f"pipeline ready in {time.time() - t0:.0f}s", flush=True)
    for seed in seeds:
        path = os.path.join(out_dir, f"still_{seed}.png")
        if os.path.exists(path):
            print(f"seed {seed}: exists, skipping", flush=True)
            continue
        t1 = time.time()
        img = generate_sd15(pipe, still, seed) if sd15 else gen_still.generate(pipe, encoder, still, seed)
        img.save(path)
        peak = torch.cuda.max_memory_allocated() / 2**30 if torch.cuda.is_available() else 0
        print(f"seed {seed}: {time.time() - t1:.0f}s, peak {peak:.2f} GiB -> {path}", flush=True)
    json.dump({**still, "seeds": seeds, "diffusers": diffusers.__version__, "torch": torch.__version__},
              open(os.path.join(out_dir, "stills.json"), "w"), indent=2)
    cmd_sheet(spec, args)


def cmd_sheet(spec, args):
    """Every still next to itself at target size: the whole swatch as art
    pixels at 3x, and one tile of it repeated 3x3 so the seam shows."""
    target = spec["target"]
    out_dir = work_dir(spec["name"], args.variant)
    S, T = int(target["swatch"]), int(target["tile"])
    cells = []
    for f in sorted(os.listdir(out_dir)):
        if not (f.startswith("still_") and f.endswith(".png")):
            continue
        seed = f[6:-4]
        still = Image.open(os.path.join(out_dir, f)).convert("RGB")
        thumb = still.copy()
        thumb.thumbnail((300, 300))
        art = art_swatch(still, target, S, lines=False).resize((S * 3, S * 3), Image.NEAREST)
        block = fill_block(still, target)
        rep = Image.new("RGBA", (block.width * 2, block.height * 2))
        for j in range(2):
            for i in range(2):
                rep.paste(block, (i * block.width, j * block.height))
        rep = rep.resize((rep.width * 2, rep.height * 2), Image.NEAREST)
        cell = Image.new("RGB", (thumb.width + art.width + rep.width + 40, max(thumb.height, art.height, rep.height) + 24), (18, 20, 28))
        cell.paste(thumb, (0, 24))
        cell.paste(art, (thumb.width + 12, 24))
        cell.paste(rep, (thumb.width + art.width + 24, 24))
        ImageDraw.Draw(cell).text((4, 4), f"seed {seed}   still | swatch {S} art px at 3x | the block x2x2 at 2x", fill=(255, 220, 80))
        cells.append(cell)
    if not cells:
        print("no stills in", out_dir)
        return
    cw, ch = max(c.width for c in cells), cells[0].height
    sheet_img = Image.new("RGB", (cw * 2, ch * ((len(cells) + 1) // 2)), (10, 12, 18))
    for n, c in enumerate(cells):
        sheet_img.paste(c, ((n % 2) * cw, (n // 2) * ch))
    path = os.path.join(out_dir, f"contact{'_' + args.tag if args.tag else ''}.png")
    sheet_img.save(path)
    print("contact sheet:", path)


def cmd_bake(spec, args):
    target = spec["target"]
    variant = args.variant or spec["still"].get("chosen_variant", "")
    out_dir = work_dir(spec["name"], variant)
    seed = args.seed or spec["still"].get("chosen_seed")
    if seed is None:
        sys.exit("bake needs --seed (or chosen_seed in the set json)")
    still = Image.open(os.path.join(out_dir, f"still_{seed}.png")).convert("RGB")
    block = fill_block(still, target)
    patch, tiles = nine_patch(block, target)
    tag = f"_{args.tag}" if args.tag else ""
    prev = preview(tiles, target, os.path.join(WORK, spec["name"], f"preview{tag}.png"))
    patch.save(os.path.join(WORK, spec["name"], f"ninepatch{tag}.png"))
    print("preview:", prev, "| colours:", rig.colour_count(patch))
    if not args.work_only:
        path = save_scaled(patch, spec["sheet"], scale=int(target["scale"]))
        print("sheet:", path, f"{patch.width * target['scale']}x{patch.height * target['scale']}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("name")
    ap.add_argument("command", choices=["gen", "sheet", "bake"])
    ap.add_argument("--seeds", default="1-6")
    ap.add_argument("--seed", type=int, default=None)
    ap.add_argument("--variant", default="")
    ap.add_argument("--tag", default="")
    ap.add_argument("--set", action="append", help="override a target key for this run, e.g. --set swatch=200 or --set dark.factor=0.25")
    ap.add_argument("--work-only", action="store_true", help="bake to work/ only, leave assets/ alone")
    args = ap.parse_args()
    spec = load_set(args.name)
    for kv in args.set or []:
        # --set swatch=200 or --set dark.factor=0.25: a target override for this run only.
        k, v = kv.split("=", 1)
        cur = spec["target"]
        keys = k.split(".")
        for kk in keys[:-1]:
            cur = cur.setdefault(kk, {})
        cur[keys[-1]] = json.loads(v)
    {"gen": cmd_gen, "sheet": cmd_sheet, "bake": cmd_bake}[args.command](spec, args)


if __name__ == "__main__":
    main()
