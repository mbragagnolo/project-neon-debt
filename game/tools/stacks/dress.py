"""Write a dress.json per room from dress_vocab.json and the room's own spec.

    python tools/stacks/dress.py                  # every room
    python tools/stacks/dress.py catwalks mezz    # just these
    python tools/stacks/dress.py --dry            # print the counts, write nothing

The vocabulary is the decision -- what colour a district's lamps are, how far
apart they hang, what an accent means -- and it lives in dress_vocab.json.
This only places it at each room's real anchors, which it reads out of the
`.room` spec:

  key     the district's lamps, walked along every floor run at its spacing
  ledge   one over each one-way platform, because a ledge that has to be
          landed on should be the thing the eye finds
  marker  an accent at everything the header declares, coloured by what it is
  fill    one wide dim wash at the room's centre

Every file carries `decor: seeded`, so the generator keeps the clutter it
already places from the room id's seed and this adds light on top. A fully
authored room (14-C) has no such key and is not touched here.

A file written by this is a starting point, not a verdict: edit any room's
dress.json by hand afterwards, or add an override under `rooms` in the
vocabulary when the whole district wants the change. The judge is
`level-artist/scripts/shoot.py` and the budget, never this script.
"""
import argparse
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
TILE = 60
VOCAB = os.path.join(HERE, "dress_vocab.json")
HAND_AUTHORED = {"unit_14c"}      # rooms whose dress.json is written by hand


def load_spec(path):
    """{header keys, markers, grid} out of a .room file."""
    head, grid, in_grid = {"markers": {}, "doors": []}, [], False
    for raw in open(path, encoding="utf-8"):
        line = raw.rstrip("\r\n")
        if in_grid:
            if line:
                grid.append(line)
            continue
        if line.strip() == "grid":
            in_grid = True
            continue
        parts = line.split(None, 1)
        if not parts:
            continue
        key, rest = parts[0], (parts[1] if len(parts) > 1 else "")
        if key == "marker":
            bits = rest.split(None, 2)
            if bits:
                head["markers"][bits[0]] = bits[1] if len(bits) > 1 else "default"
        elif key == "door":
            head["doors"].append(rest)
        else:
            head[key] = rest
    head["grid"] = grid
    return head


def cells(grid):
    w = max((len(r) for r in grid), default=0)
    return [r.ljust(w, "#") for r in grid], w, len(grid)


def floor_runs(grid, w, h):
    """[(y, x0, x1)] of air tiles that have something solid under them: the
    rows a lamp would be hung over."""
    runs = []
    for y in range(h - 1):
        x = 0
        while x < w:
            if grid[y][x] in ".=" and grid[y + 1][x] in "#=":
                x0 = x
                while x < w and grid[y][x] in ".=" and grid[y + 1][x] in "#=":
                    x += 1
                runs.append((y, x0, x - 1))
            else:
                x += 1
    return runs


def ledges(grid, w, h):
    """[(y, x0, x1)] of one-way platform runs."""
    out = []
    for y in range(h):
        x = 0
        while x < w:
            if grid[y][x] == "=":
                x0 = x
                while x < w and grid[y][x] == "=":
                    x += 1
                out.append((y, x0, x - 1))
            else:
                x += 1
    return out


def marker_cells(grid, w, h, markers):
    out = []
    for y in range(h):
        for x in range(w):
            c = grid[y][x]
            if c in markers:
                out.append((c, x, y))
    return out


def light(name, x_px, y_px, spec, extra=None):
    e = {"name": name, "at": [int(x_px), int(y_px)],
         "color": [round(float(v), 3) for v in spec["color"]],
         "energy": round(float(spec["energy"]), 3),
         "scale": round(float(spec["scale"]), 3)}
    if extra:
        e.update(extra)
    return e


def merge(base, over):
    out = dict(base)
    for k, v in (over or {}).items():
        if k.startswith("_"):
            continue
        out[k] = dict(out[k], **v) if isinstance(v, dict) and isinstance(out.get(k), dict) else v
    return out


def dress_for(room, spec, vocab):
    style = spec.get("style", "mezz")
    styles = vocab["styles"]
    if style not in styles:
        raise SystemExit(f"{room}: style {style!r} is not in dress_vocab.json")
    v = merge(styles[style], (vocab.get("rooms") or {}).get(room))
    marks = vocab["markers"]
    grid, w, h = cells(spec["grid"])
    every = int(v.get("every_tiles", 9))
    lights = []

    # The district's lamps along every floor run. The spacing is a property of
    # the room and not of a run: a stairwell is a floor run per step, and
    # spacing them only within a run hung sixty lamps in west_stair.
    n, placed = 0, []
    for (y, x0, x1) in floor_runs(grid, w, h):
        if x1 - x0 + 1 < 3:
            continue
        start = x0 + max(1, (x1 - x0 + 1) % every // 2)
        for x in range(start, x1 + 1, every):
            if any(abs(x - px) < every and abs(y - py) < every for px, py in placed):
                continue
            placed.append((x, y))
            n += 1
            lights.append(light(f"lamp_{n}", (x + 0.5) * TILE, (y - 0.5) * TILE, v["key"]))

    # a ledge the player has to land on is worth seeing
    for i, (y, x0, x1) in enumerate(ledges(grid, w, h), 1):
        lights.append(light(f"ledge_{i}", (x0 + x1 + 1) * 0.5 * TILE, (y - 0.4) * TILE, v["ledge"]))

    # everything the header declares
    for i, (c, x, y) in enumerate(marker_cells(grid, w, h, spec["markers"]), 1):
        kind = spec["markers"][c].split()[0]
        lights.append(light(f"{kind}_{i}", (x + 0.5) * TILE, (y + 0.4) * TILE,
                            marks.get(kind, marks["default"])))

    # one wide wash so the ambient is not doing all the work on its own
    lights.append(light("fill", w * TILE * 0.5, h * TILE * 0.45, v["fill"],
                        {"scale_xy": [round(w / max(h, 1), 2), 1.0]}))

    return {
        "_doc": f"{spec.get('name', room)} ({style}). Written by tools/stacks/dress.py from "
                f"dress_vocab.json, which is where the district's lighting is decided. Edit here "
                f"for this room alone, or in the vocabulary for the whole style; re-running the "
                f"script overwrites this file.",
        "decor": "seeded",
        "_decor": "keep the clutter the generator places from the room id's seed; this file adds light.",
        "ambient": [round(float(c), 3) for c in v["ambient"]],
        "door_lamp": dict(v["door_lamp"]),
        "lights": lights,
    }


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("rooms", nargs="*", help="room ids; every room when empty")
    ap.add_argument("--dry", action="store_true")
    a = ap.parse_args()

    with open(VOCAB, encoding="utf-8") as f:
        vocab = json.load(f)
    names = a.rooms or sorted(
        os.path.splitext(f)[0] for f in os.listdir(HERE) if f.endswith(".room"))
    wrote = 0
    for room in names:
        if room in HAND_AUTHORED:
            print(f"  {room:22s} hand-authored, skipped")
            continue
        path = os.path.join(HERE, f"{room}.room")
        if not os.path.exists(path):
            sys.exit(f"no {path}")
        data = dress_for(room, load_spec(path), vocab)
        print(f"  {room:22s} {len(data['lights']):3d} light(s)")
        if not a.dry:
            with open(os.path.join(HERE, f"{room}.dress.json"), "w", encoding="utf-8") as f:
                json.dump(data, f, indent=2)
                f.write("\n")
            wrote += 1
    print(f"{wrote} file(s) written" if not a.dry else "dry run, nothing written")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
