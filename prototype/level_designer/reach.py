"""Spike: every level gap and every ledge in the district, classified against the
movement envelope with the kit the player owns when first reaching the room,
compared with what the room specs declare as gates.

    python prototype/level_designer/reach.py            # the report
    python prototype/level_designer/reach.py --all      # plain gaps and steps too
    python prototype/level_designer/reach.py --map      # also draw prototype/level_designer/district.png
"""
import argparse
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from roomspec import TILE, CELL, ENEMIES, load_all  # noqa: E402
from envelope import Envelope, load_config  # noqa: E402

PROJECT = os.path.dirname(os.path.dirname(HERE))
SPECS = os.path.join(PROJECT, "game", "tools", "stacks")
CONFIG = os.path.join(PROJECT, "game", "src", "player", "movement_config.tres")
START = "unit_14c"
ABILITIES = {
    "ability.mag_hook": "mag_hook",
    "ability.cyberdeck": "cyberdeck",
    "item.sidewinder_carried": "sidewinder_carried",
}


# --- The district walk (a port of test_stacks._reachable) ---------------------

def kit_at_arrival(rooms):
    """room id -> the kit owned when the room is first reached from the flat."""
    by = {r.id: r for r in rooms}
    owned = set()
    first = {}
    changed = True
    while changed:
        changed = False
        reached = {START}
        frontier = [START]
        while frontier:
            cur = by[frontier.pop()]
            for digit, (target, _) in cur.doors.items():
                need = cur.requires.get(digit)
                if need and need not in owned:
                    continue
                if digit in cur.oneway:
                    continue
                if target not in reached:
                    reached.add(target)
                    frontier.append(target)
        for rid in reached:
            first.setdefault(rid, frozenset(owned))
        for rid in reached:
            spec = by[rid]
            for c, (typ, args) in spec.markers.items():
                if not spec.positions_of(c):
                    continue
                need = spec.requires.get(c)
                if need and need not in owned:
                    continue
                grant = ABILITIES.get(args) if typ == "ability" else (args if typ == "hack" else None)
                if grant and grant not in owned:
                    owned.add(grant)
                    changed = True
        if "sidewinder_carried" in owned and "mezz" in reached and "sidewinder" not in owned:
            owned.add("sidewinder")
            changed = True
    return first, owned


# --- Gaps -----------------------------------------------------------------------

def level_gaps(spec):
    """(x1, y, x2): ground lips on row y with nothing to stand on between, open above."""
    out = []
    for y in range(1, spec.height):
        x = 0
        while x < spec.width - 1:
            if not spec.is_standable(x, y):
                x += 1
                continue
            x2 = x + 1
            while x2 < spec.width and not spec.is_ground(x2, y):
                x2 += 1
            if x2 < spec.width and x2 > x + 1 and spec.is_open(x2, y - 1):
                if all(spec.is_open(g, y - 1) for g in range(x + 1, x2)):
                    out.append((x, y, x2))
            x = x2
    return out


def effective_gap(spec, env, x1, y, x2):
    """The widest hop across the gap once standable tiles inside it, no deeper
    than a jump below the lip row, are counted as stepping stones. Returns
    (tiles, deepest support or None)."""
    max_depth = int(env.jump_height() // TILE)
    supports = []
    for x in range(x1 + 1, x2):
        for d in range(1, max_depth + 1):
            if spec.is_standable(x, y + d):
                supports.append((x, d))
                break
    if not supports:
        return x2 - x1 - 1, None
    edges = [x1] + sorted({x for x, _ in supports}) + [x2]
    return max(b - a - 1 for a, b in zip(edges, edges[1:])), max(d for _, d in supports)


def classify_gap(env, gap_px):
    travel = gap_px - env.BODY_WIDTH
    m = env.GATE_MARGIN
    if travel * m <= env.max_gap(False):
        return "plain"
    if travel <= env.max_gap(False):
        return "tight-plain"
    if travel < env.max_gap(False) * m:
        return "tight-gate"
    if travel * m <= env.max_gap(True):
        return "gate"
    if travel <= env.max_gap(True):
        return "tight-implant"
    return "beyond"


def crossable(env, gap_px, kit):
    return gap_px - env.BODY_WIDTH <= env.max_gap("sidewinder" in kit)


# --- Ledges -------------------------------------------------------------------

def ledges(spec, env):
    """A standable tile beside a solid column that tops out on another standable tile.
    Returns (x_base, y_base, side, x_wall, y_top, h_tiles, facing_w_tiles)."""
    out = []
    seen = set()
    for y in range(spec.height):
        for x in range(spec.width):
            if not spec.is_standable(x, y):
                continue
            for side, dx in (("right", 1), ("left", -1)):
                wx = x + dx
                if not spec.is_solid(wx, y):
                    continue
                t = y
                while t - 1 >= 0 and spec.is_solid(wx, t - 1):
                    t -= 1
                if t == 0 or not spec.is_open(wx, t - 1):
                    continue  # the room's ring, or a wall to the ceiling
                h = y - t  # feet on row y to feet on row t
                if h <= 0:
                    continue  # level floor, not a ledge
                key = (wx, t, side)
                if key in seen:
                    continue
                seen.add(key)
                # the facing wall on the player's side, across open tiles at the base row
                fx = x
                w = 0
                while fx - dx >= 0 and fx - dx < spec.width and spec.is_open(fx - dx, y - 1) and spec.is_open(fx - dx, y - 2):
                    fx -= dx
                    w += 1
                facing = w + 1 if spec.is_solid(fx - dx, y - 1) and 0 <= fx - dx < spec.width else None
                out.append((x, y, side, wx, t, h, facing))
    return out


def classify_ledge(env, h_tiles, facing_tiles):
    h = h_tiles * TILE
    if h <= env.jump_height():
        return "step"
    shaft = facing_tiles is not None and env.is_climbable_shaft(facing_tiles * TILE)
    if h < env.jump_height() * env.GATE_MARGIN:
        return "tight-wall" + ("+shaft" if shaft else "")
    return "wall" + ("+shaft" if shaft else "")


# --- Report -------------------------------------------------------------------

def under_text(kind, depth):
    return {"floor": f"floor {depth} down", "void": "void", "hazard": "hazard", "none": "nothing"}[kind]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--all", action="store_true", help="list plain gaps and steps too")
    ap.add_argument("--map", action="store_true", help="draw district.png with the findings")
    ap.add_argument("--rooms", nargs="*", help="only these room ids")
    a = ap.parse_args()

    rooms = load_all(SPECS)
    env = Envelope(load_config(CONFIG))
    for r in rooms:
        for e in r.errors:
            print("spec error:", e)
    first, final_kit = kit_at_arrival(rooms)

    print("# Reach check: the Stacks against the envelope\n")
    print("Envelope from movement_config.tres:", env.summary())
    print(f"Valid Sidewinder gate: {env.max_gap(False) * env.GATE_MARGIN + env.BODY_WIDTH:.0f}px .. {env.max_gap(True) / env.GATE_MARGIN + env.BODY_WIDTH:.0f}px lip to lip"
          f" ({(env.max_gap(False) * env.GATE_MARGIN + env.BODY_WIDTH) / TILE:.1f} .. {(env.max_gap(True) / env.GATE_MARGIN + env.BODY_WIDTH) / TILE:.1f} tiles)")
    print(f"Plain jump: up to {(env.max_gap(False) / env.GATE_MARGIN + env.BODY_WIDTH) / TILE:.1f} tiles. Step: up to {env.jump_height() / TILE:.1f} tiles."
          f" Shaft the Hook climbs: up to {(env.wall_jump_reach() / env.GATE_MARGIN + env.BODY_WIDTH) / TILE:.1f} tiles wide.\n")
    unreached = [r.id for r in rooms if r.id not in first]
    if unreached:
        print("Never reached from the flat:", unreached)
    print(f"Final kit after the walk: {sorted(final_kit)}\n")

    findings = []
    gap_rows = []
    ledge_rows = []
    counts = {}
    declared_gates = {}
    for r in rooms:
        if a.rooms and r.id not in a.rooms:
            continue
        kit = first.get(r.id, frozenset())
        declared = {(v[0], v[1], v[2]) for k, v in r.gates if k == "air_dash"}
        declared_gates[r.id] = declared
        counts[r.id] = {"plain": 0, "step": 0}
        for (x1, y, x2) in level_gaps(r):
            tiles = x2 - x1 - 1
            eff, support = effective_gap(r, env, x1, y, x2)
            px = eff * TILE
            cls = classify_gap(env, px)
            kind, depth = r.under(x1 + 1 + tiles // 2, y)
            is_declared = (x1, y, x2) in declared
            deadly = kind in ("void", "hazard")
            if eff == 0 and not a.all and not is_declared:
                counts[r.id]["walk-down"] = counts[r.id].get("walk-down", 0) + 1
                continue  # pillar tops over a floor: you walk down, not a gap
            if cls == "plain" and not a.all and not is_declared:
                counts[r.id]["plain"] += 1
                continue
            eff_text = f"{eff} (support {support} down)" if support else str(eff)
            gap_rows.append((r.id, y, x1, x2, tiles, eff_text, cls, under_text(kind, depth), "yes" if is_declared else "", "yes" if crossable(env, px, kit) else "NO", ",".join(sorted(kit)) or "-"))
            if is_declared and cls != "gate":
                findings.append(f"{r.id}: declared air_dash gate at row {y} x{x1}..{x2} ({tiles} tiles) is BYPASSED: a standable tile {support} down inside it makes the widest hop {eff} tiles, class {cls}" if support else
                                f"{r.id}: declared air_dash gate at row {y} x{x1}..{x2} is {tiles} tiles, class {cls}, not a valid gate")
            if not is_declared and cls in ("gate", "tight-gate", "tight-implant") and "sidewinder" not in kit and deadly:
                findings.append(f"{r.id}: UNDECLARED gate-class gap at row {y} x{x1}..{x2} ({tiles} tiles, {cls}) over {under_text(kind, depth)}, reached without the Sidewinder")
            if cls == "beyond" and deadly:
                findings.append(f"{r.id}: gap at row {y} x{x1}..{x2} ({tiles} tiles) over {under_text(kind, depth)} is beyond the whole kit")
            if kind == "floor" and depth * TILE > env.jump_height() and cls != "plain":
                findings.append(f"{r.id}: row {y} x{x1}..{x2} is a one-way drop of {depth} tiles (no jump back up the same way)")
            if cls == "tight-plain" and deadly:
                findings.append(f"{r.id}: gap at row {y} x{x1}..{x2} ({tiles} tiles) over {under_text(kind, depth)} is crossable by the starting kit but under the 15% margin")
        for d in declared:
            if d not in {(g[0], g[1], g[2]) for g in level_gaps(r)}:
                findings.append(f"{r.id}: declared air_dash gate {d} was not found as a level gap")
        for (x, y, side, wx, t, h, facing) in ledges(r, env):
            cls = classify_ledge(env, h, facing)
            if cls == "step" and not a.all:
                counts[r.id]["step"] += 1
                continue
            ledge_rows.append((r.id, y, x, side, h, facing if facing is not None else "-", cls, ",".join(sorted(kit)) or "-"))
            if cls.startswith("tight-wall"):
                findings.append(f"{r.id}: a {h}-tile ledge at x{wx} row {t} (from row {y}, {side}) is a wall by only {h * TILE - env.jump_height():.0f}px, under the margin" + (" (shaft beside it)" if "shaft" in cls else ""))

    print("## Declared gates, re-judged (mirrors tests/test_stacks.gd)\n")
    print("| room | gate | values | measure | verdict |")
    print("|---|---|---|---|---|")
    for r in rooms:
        if a.rooms and r.id not in a.rooms:
            continue
        for kind, v in r.gates:
            if kind == "air_dash":
                x1, y, x2 = v
                gap = (x2 - x1 - 1) * TILE
                clean = r.is_solid(x1, y) and r.is_solid(x2, y) and all(not r.is_solid(x, y) and not r.is_solid(x, y - 1) for x in range(x1 + 1, x2))
                hop, support = effective_gap(r, env, x1, y, x2)
                verdict = "valid" if clean and env.is_valid_air_dash_gate(hop * TILE) else "INVALID"
                hop_text = f", widest hop {hop * TILE:.0f}px (support {support} down)" if support else ""
                print(f"| {r.id} | air_dash | {v} | {gap:.0f}px lip to lip{hop_text} | {verdict} |")
            elif kind == "shaft":
                x1, x2, y0, y1 = v
                width = (x2 - x1 + 1) * TILE
                walls = all(r.is_solid(x1 - 1, y) and r.is_solid(x2 + 1, y) and all(not r.is_solid(x, y) for x in range(x1, x2 + 1)) for y in range(y0, y1 + 1))
                verdict = "climbable" if walls and env.is_climbable_shaft(width) else "INVALID"
                print(f"| {r.id} | shaft | {v} | {width:.0f}px wide, {y1 - y0 + 1} tall | {verdict} |")
            elif kind == "tease":
                x, y = v
                ledge_row = y + 1
                left = x
                while r.is_solid(left - 1, ledge_row):
                    left -= 1
                right = x
                while r.is_solid(right + 1, ledge_row):
                    right += 1
                heights = []
                for sx in (left - 1, right + 1):
                    fr = ledge_row
                    while fr < r.height and not r.is_solid(sx, fr):
                        fr += 1
                    heights.append((fr - ledge_row) * TILE)
                verdict = "out of reach" if all(env.is_valid_tease_height(h) for h in heights) else "INVALID"
                print(f"| {r.id} | tease | {v} | ledge {right - left + 1} wide, drops {[int(h) for h in heights]}px | {verdict} |")
    print()

    print("## Level gaps that are not plain jumps\n")
    print("| room | row | x1..x2 | tiles | widest hop | class | under | declared | crossable on arrival | kit on arrival |")
    print("|---|---|---|---|---|---|---|---|---|---|")
    for row in gap_rows:
        print("| " + " | ".join(str(v) for v in row) + " |")
    print(f"\nPlain gaps not listed: {sum(c['plain'] for c in counts.values())}\n")

    print("## Ledges that are not steps\n")
    print("| room | base row | base x | side | height (tiles) | facing wall (tiles) | class | kit on arrival |")
    print("|---|---|---|---|---|---|---|---|")
    for row in ledge_rows:
        print("| " + " | ".join(str(v) for v in row) + " |")
    print(f"\nSteps not listed: {sum(c['step'] for c in counts.values())}\n")

    print("## Findings\n")
    if not findings:
        print("- none")
    for f in findings:
        print("-", f)

    if a.map:
        draw_map(rooms, env, first, os.path.join(HERE, "district.png"))
        print(f"\nmap: {os.path.join(HERE, 'district.png')}")


# --- Map ----------------------------------------------------------------------

def draw_map(rooms, env, first, path):
    from PIL import Image, ImageDraw
    S = 4  # px per tile
    minx = min(r.cell[0] for r in rooms)
    miny = min(r.cell[1] for r in rooms)
    maxx = max(r.cell[0] + r.size[0] for r in rooms)
    maxy = max(r.cell[1] + r.size[1] for r in rooms)
    W = (maxx - minx) * CELL[0] * S
    H = (maxy - miny) * CELL[1] * S
    im = Image.new("RGB", (W, H), (12, 12, 16))
    d = ImageDraw.Draw(im)
    colour = {"#": (70, 70, 80), ".": (22, 22, 28), "=": (120, 120, 130), "v": (90, 30, 110), "~": (30, 110, 130), "P": (255, 255, 255)}
    for r in rooms:
        ox = (r.cell[0] - minx) * CELL[0] * S
        oy = (r.cell[1] - miny) * CELL[1] * S
        for y, row in enumerate(r.grid):
            for x, c in enumerate(row):
                if c in colour:
                    col = colour[c]
                elif c.isdigit():
                    col = (60, 200, 90)
                elif c in ENEMIES:
                    col = (220, 60, 60)
                else:
                    col = (230, 200, 60)
                d.rectangle([ox + x * S, oy + y * S, ox + x * S + S - 1, oy + y * S + S - 1], fill=col)
        kit = first.get(r.id, frozenset())
        declared = {(v[0], v[1], v[2]) for k, v in r.gates if k == "air_dash"}
        for (x1, y, x2) in level_gaps(r):
            eff, _ = effective_gap(r, env, x1, y, x2)
            cls = classify_gap(env, eff * TILE)
            if cls == "plain" and (x1, y, x2) not in declared:
                continue
            if (x1, y, x2) in declared and cls != "gate":
                col = (255, 255, 255)  # a declared gate that is not one
                yy = oy + y * S - 1
                d.line([ox + (x1 + 1) * S, yy, ox + x2 * S, yy], fill=col, width=3)
                continue
            col = {"gate": (255, 0, 255), "tight-gate": (255, 140, 0), "tight-plain": (255, 230, 0), "tight-implant": (255, 0, 120), "beyond": (255, 40, 40)}[cls]
            yy = oy + y * S - 1
            d.line([ox + (x1 + 1) * S, yy, ox + x2 * S, yy], fill=col, width=2)
        for (x, y, side, wx, t, h, facing) in ledges(r, env):
            cls = classify_ledge(env, h, facing)
            if cls == "step":
                continue
            col = (80, 160, 255) if "shaft" in cls else (255, 255, 255)
            xx = ox + wx * S + (0 if side == "right" else S - 1)
            d.line([xx, oy + t * S, xx, oy + (y + 1) * S], fill=col, width=1)
        d.text((ox + 3, oy + 2), r.id + ("" if "sidewinder" in kit else "") , fill=(200, 200, 210))
    im.save(path)


if __name__ == "__main__":
    main()
