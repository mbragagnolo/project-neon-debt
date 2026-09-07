"""Generate a character's canonical still (docs/art/cast.md) with a local
diffusion model, and lay the candidates out on a contact sheet.

    python tools/art/gen_still.py dani --seeds 1-8
    python tools/art/gen_still.py dani --seeds 1-8 --run shaded
    python tools/art/gen_still.py dani --seeds 1-4 --prop wrench

Reads `tools/art/cast/<name>.json` (`still` block: model, size, prompt,
seeds are on the command line so a re-roll is a one-flag change). Writes
`tools/art/work/<name>/still_<seed>.png` (full size, never committed) and
`tools/art/work/<name>/contact.png`: every candidate next to itself
downscaled to the target height, because the pick has to be judged at the
size it will be seen at, not at 1216 px. `--run <tag>` puts a sweep in
`work/<name>/<tag>/` instead, so a prompt change can be compared against
the previous sweep instead of overwriting it.

Provenance: the sheet's JSON sidecar records model, prompt, seed and the
library versions, so a chosen seed is reproducible to the extent the
libraries allow.

VRAM: the 8 GB config from fakemon-forge — fp16, model CPU offload, VAE
tiling, Euler-a. Do not `.to("cuda")` a pipeline after offload is enabled.
"""
import argparse
import json
import os
import sys
import time

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CAST = os.path.join(HERE, "cast")
WORK = os.path.join(HERE, "work")


def parse_seeds(spec):
    out = []
    for part in spec.split(","):
        if "-" in part:
            a, b = part.split("-")
            out.extend(range(int(a), int(b) + 1))
        else:
            out.append(int(part))
    return out


def load_pipeline(model_id):
    import torch
    from diffusers import EulerAncestralDiscreteScheduler, StableDiffusionXLPipeline

    pipe = StableDiffusionXLPipeline.from_pretrained(
        model_id, torch_dtype=torch.float16, local_files_only=True, use_safetensors=True
    )
    pipe.scheduler = EulerAncestralDiscreteScheduler.from_config(pipe.scheduler.config)
    pipe.set_progress_bar_config(disable=True)
    if torch.cuda.is_available():
        pipe.enable_model_cpu_offload()
        pipe.enable_vae_tiling()
    return pipe


class Encoder:
    """Prompt -> SDXL embeddings without the 77-token cliff.

    CLIP truncates silently at 77 tokens and a look paragraph is ~170, so the
    clothing tags never reached the model on the first run. compel chunks the
    prompt across several 77-token windows for both encoders; if compel is not
    importable we fall back to the pipeline's plain `prompt`, which truncates,
    and say so loudly."""

    def __init__(self, pipe):
        import torch
        self.pipe = pipe
        try:
            from compel import Compel, ReturnedEmbeddingsType
            self.compel = Compel(
                tokenizer=[pipe.tokenizer, pipe.tokenizer_2],
                text_encoder=[pipe.text_encoder, pipe.text_encoder_2],
                returned_embeddings_type=ReturnedEmbeddingsType.PENULTIMATE_HIDDEN_STATES_NON_NORMALIZED,
                requires_pooled=[False, True],
                truncate_long_prompts=False,
                # Offload hooks move the encoders to the GPU on forward; compel
                # must put its token ids there too or the embedding lookup fails.
                device="cuda" if torch.cuda.is_available() else "cpu",
            )
            # Weighted fragments ("(cyan trim)1.25") subtract an empty-prompt
            # embedding that each provider builds on *its* device, and that was
            # read off the encoder while it sat on the CPU for offload. Pin it.
            device = "cuda" if torch.cuda.is_available() else "cpu"
            cp = self.compel.conditioning_provider
            for provider in getattr(cp, "embedding_providers", [cp]):
                provider.device = device
        except Exception as e:  # noqa: BLE001
            print("compel unavailable, prompts will truncate at 77 tokens:", e, flush=True)
            self.compel = None

    def kwargs(self, prompt, negative):
        if self.compel is None:
            return {"prompt": prompt, "negative_prompt": negative}
        import torch
        cond, pooled = self.compel(prompt)
        ncond, npooled = self.compel(negative)
        # compel's pad_conditioning_tensors_to_same_length is broken for SDXL on
        # this transformers version; pad the shorter one with empty-prompt chunks
        # ourselves, which is what it does.
        if cond.shape[1] != ncond.shape[1]:
            empty, _ = self.compel("")
            while ncond.shape[1] < cond.shape[1]:
                ncond = torch.cat([ncond, empty.to(ncond.device, ncond.dtype)], dim=1)
            while cond.shape[1] < ncond.shape[1]:
                cond = torch.cat([cond, empty.to(cond.device, cond.dtype)], dim=1)
        return {
            "prompt_embeds": cond, "pooled_prompt_embeds": pooled,
            "negative_prompt_embeds": ncond, "negative_pooled_prompt_embeds": npooled,
        }


def generate(pipe, encoder, still, seed):
    import torch

    g = torch.Generator("cuda" if torch.cuda.is_available() else "cpu").manual_seed(seed)
    result = pipe(
        width=still["width"],
        height=still["height"],
        num_inference_steps=still["steps"],
        guidance_scale=still["cfg"],
        generator=g,
        **encoder.kwargs(still["prompt"], still["negative"]),
    )
    return result.images[0]


def target_preview(img, height_art_px, scale):
    """The candidate as it would be seen: content bbox scaled so its height is
    `height_art_px`, then blown up `scale`x with nearest, on a dark ground."""
    from PIL import ImageOps

    bbox = _content_bbox(img)
    crop = img.crop(bbox) if bbox else img
    ratio = height_art_px / crop.height
    small = crop.resize((max(1, round(crop.width * ratio)), height_art_px), Image.LANCZOS)
    big = small.resize((small.width * scale, small.height * scale), Image.NEAREST)
    return big


def _content_bbox(img, tolerance=28):
    """Bounding box of everything that is not the flat background, taking the
    background colour from the corners."""
    rgb = img.convert("RGB")
    w, h = rgb.size
    corners = [rgb.getpixel((0, 0)), rgb.getpixel((w - 1, 0)), rgb.getpixel((0, h - 1)), rgb.getpixel((w - 1, h - 1))]
    bg = tuple(sum(c[i] for c in corners) // 4 for i in range(3))
    px = rgb.load()
    xs, ys = [], []
    for y in range(0, h, 2):
        for x in range(0, w, 2):
            p = px[x, y]
            if abs(p[0] - bg[0]) + abs(p[1] - bg[1]) + abs(p[2] - bg[2]) > tolerance * 3:
                xs.append(x)
                ys.append(y)
    if not xs:
        return None
    return (max(0, min(xs) - 4), max(0, min(ys) - 4), min(w, max(xs) + 6), min(h, max(ys) + 6))


def contact_sheet(entries, target, out_path):
    """entries: [(seed, full_image)] -> grid of (thumb | target-size preview)."""
    cols = 4
    thumb_h = 420
    cell_w, cell_h = 0, thumb_h + 24
    cells = []
    for seed, img in entries:
        thumb = img.copy()
        thumb.thumbnail((10000, thumb_h))
        prev = target_preview(img, target["height_art_px"], target["scale"])
        cell = Image.new("RGB", (thumb.width + prev.width + 24, cell_h), (18, 20, 28))
        cell.paste(thumb, (0, 24))
        cell.paste(prev, (thumb.width + 16, cell_h - prev.height - 8))
        ImageDraw.Draw(cell).text((4, 4), f"seed {seed}", fill=(255, 220, 80))
        cells.append(cell)
        cell_w = max(cell_w, cell.width)
    rows = (len(cells) + cols - 1) // cols
    sheet = Image.new("RGB", (cell_w * cols, cell_h * rows), (10, 12, 18))
    for i, c in enumerate(cells):
        sheet.paste(c, ((i % cols) * cell_w, (i // cols) * cell_h))
    sheet.save(out_path)
    return out_path


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("name")
    ap.add_argument("--seeds", default="1-8")
    ap.add_argument("--sheet-only", action="store_true", help="rebuild contact.png from existing stills")
    ap.add_argument("--run", default="", help="sweep subfolder under work/<name>/ (default: work/<name>/ itself)")
    ap.add_argument("--prop", default="", help="generate props.<prop> from the cast json instead of the character")
    args = ap.parse_args()

    spec = json.load(open(os.path.join(CAST, f"{args.name}.json"), encoding="utf-8"))
    still, target = spec["still"], spec["target"]
    run = args.run
    if args.prop:
        # A prop (the wrench) is its own still: the character's model settings,
        # the prop's prompt, previewed at the prop's own art height.
        prop = spec["props"][args.prop]
        still = {**still, **{k: v for k, v in prop.items() if not k.startswith("_")}}
        target = {**target, "height_art_px": prop.get("height_art_px", target["height_art_px"])}
        run = os.path.join(f"prop_{args.prop}", args.run) if args.run else f"prop_{args.prop}"
    out_dir = os.path.join(WORK, args.name, run) if run else os.path.join(WORK, args.name)
    os.makedirs(out_dir, exist_ok=True)
    # Godot must not import the candidates (it would try, they sit inside the project).
    open(os.path.join(WORK, ".gdignore"), "a").close()
    seeds = parse_seeds(args.seeds)

    entries = []
    if not args.sheet_only:
        import diffusers
        import torch

        t0 = time.time()
        pipe = load_pipeline(still["model"])
        encoder = Encoder(pipe)
        print(f"pipeline ready in {time.time() - t0:.0f}s", flush=True)
        for seed in seeds:
            path = os.path.join(out_dir, f"still_{seed}.png")
            if os.path.exists(path):
                print(f"seed {seed}: exists, skipping", flush=True)
                continue
            t1 = time.time()
            img = generate(pipe, encoder, still, seed)
            img.save(path)
            peak = torch.cuda.max_memory_allocated() / 2**30 if torch.cuda.is_available() else 0
            print(f"seed {seed}: {time.time() - t1:.0f}s, peak {peak:.2f} GiB -> {path}", flush=True)
        sidecar = {
            "model": still["model"], "prompt": still["prompt"], "negative": still["negative"],
            "width": still["width"], "height": still["height"], "steps": still["steps"],
            "cfg": still["cfg"], "scheduler": still["scheduler"], "seeds": seeds,
            "diffusers": diffusers.__version__, "torch": torch.__version__,
        }
        json.dump(sidecar, open(os.path.join(out_dir, "stills.json"), "w"), indent=2)

    for seed in seeds:
        path = os.path.join(out_dir, f"still_{seed}.png")
        if os.path.exists(path):
            entries.append((seed, Image.open(path).convert("RGB")))
    if entries:
        print("contact sheet:", contact_sheet(entries, target, os.path.join(out_dir, "contact.png")))


if __name__ == "__main__":
    sys.exit(main())
