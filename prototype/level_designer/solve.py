"""Spike 2: in-room reachability with the kit's moves.

A flood over standing tiles and wall-touch points. From each standing tile
the player can walk, walk off an edge, jump (three steers, three take-off
points), ground dash, and with the Sidewinder air-dash once per flight;
from a wall touched while falling the Mag-Hook allows a wall jump, never off
the same wall twice in one flight. Flights are integrated at the physics
step with the real body box against the grid: solids block, one-way
platforms catch a falling body only, void ends the flight, doors and
markers are touched by overlap.

    python prototype/level_designer/solve.py                       # the district: every room with the kit at arrival
    python prototype/level_designer/solve.py --rooms catwalks --kit mag_hook
    python prototype/level_designer/solve.py --fixture prototype/level_designer/fixtures/catwalks_old.room
    python prototype/level_designer/solve.py --png                 # also draw reach.png
"""
import argparse
import collections
import copy
import math
import os
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from roomspec import TILE, CELL, load_all, parse  # noqa: E402
from envelope import Envelope, load_config  # noqa: E402
from reach import kit_at_arrival, SPECS, CONFIG, START, ABILITIES  # noqa: E402

DT = 1.0 / 60.0
BODY_W = 48.0
BODY_H = 88.0
MAX_FLIGHT = 6.0  # a four-cell riser at terminal velocity takes four seconds
PICKUPS = {"item", "hack", "ability", "hp_up", "ram_up", "quest_item", "save"}


class Sim:
    def __init__(self, room, env, kit):
        self.r = room
        self.kit = kit
        c = env.c
        self.g_rise = env.rise_gravity()
        self.g_fall = env.fall_gravity()
        self.v_jump = -2.0 * c["jump_height"] / c["jump_time_to_apex"]
        self.v_wall = -math.sqrt(2.0 * self.g_rise * c["wall_jump_height"])
        self.run = c["run_speed"]
        self.max_fall = c["max_fall_speed"]
        self.dash_speed = c["dash_distance"] / c["dash_duration"]
        self.dash_t = c["dash_duration"]
        self.push = c["wall_jump_push"]
        self.lock = c["wall_jump_lockout_time"]
        self.apex_t = c["jump_time_to_apex"]
        self.hook = "mag_hook" in kit
        self.air = "sidewinder" in kit
        self.W = room.width * TILE
        self.H = room.height * TILE
        self.stand = set()
        self.walls = set()
        self.touched = set()
        self.exits = set()
        self.queue = collections.deque()
        self.steps = 0
        self.lifts = getattr(room, "lifts", [])
        self.trace = None
        self.door_side = {d: room.door_side(room.door_rect(d)) for d in room.doors if room.door_rect(d)}

    # --- geometry ---------------------------------------------------------------

    def cells(self, px, py):
        x0 = int((px - BODY_W / 2) // TILE)
        x1 = int((px + BODY_W / 2 - 1) // TILE)
        y0 = int((py - BODY_H) // TILE)
        y1 = int((py - 1) // TILE)
        return [(x, y) for y in range(y0, y1 + 1) for x in range(x0, x1 + 1)]

    def blocked(self, cs):
        return any(self.r.is_solid(x, y) for x, y in cs)

    def touch(self, cs, vy=0.0):
        """Cells the body overlaps. A door counts as an exit only when the body
        enters it the way the door is used: rising into a ceiling door,
        falling into a floor door, any way into a side door."""
        for c in cs:
            ch = self.r.tile(*c)
            if ch.isdigit() and ch not in self.exits:
                side = self.door_side.get(ch, "left")
                if side == "up" and vy >= 0.0:
                    pass
                elif side == "down" and vy <= 0.0:
                    pass
                else:
                    self.exits.add(ch)
            self.touched.add(c)

    # --- states -------------------------------------------------------------------

    def add_stand(self, x, y):
        if (x, y) in self.stand or not self.r.is_standable(x, y) or self.r.is_solid(x, y - 2):
            return
        self.stand.add((x, y))
        self.queue.append(("stand", x, y))
        self.touch(self.cells((x + 0.5) * TILE, y * TILE))
        for rest, high in self.lifts:  # ride the lift either way
            if (x, y) in rest:
                for c in high:
                    self.add_stand(*c)
            elif (x, y) in high:
                for c in rest:
                    self.add_stand(*c)

    def add_wall(self, px, py, side, col, wall_from):
        if (col, side) == wall_from:
            return  # the wall just jumped off refuses the player for the flight
        row = int(py // TILE)
        key = (col, side, row)
        if key in self.walls:
            return
        self.walls.add(key)
        if self.hook:
            self.queue.append(("wall", px, py, side, col))

    def run_all(self):
        while self.queue:
            item = self.queue.popleft()
            if item[0] == "stand":
                self.expand_stand(item[1], item[2])
            else:
                self.expand_wall(*item[1:])

    def expand_stand(self, x, y):
        py = y * TILE
        centre = (x + 0.5) * TILE
        # walk, or walk off the edge
        for dx in (-1, 1):
            nx = x + dx
            if self.r.is_ground(nx, y):
                self.add_stand(nx, y)
            elif not self.r.is_solid(nx, y - 1) and not self.r.is_solid(nx, y - 2):
                edge = (x + 1) * TILE if dx > 0 else x * TILE
                for vx in (dx * self.run, dx * self.run * 0.5, 0.0):
                    self.fly(edge + dx * (BODY_W / 2 + 1), py, vx, 0.0)
        # jump: from the centre and from the edge in the steer's direction
        for vx in (-self.run, 0.0, self.run):
            starts = [centre]
            if vx:
                starts.append((x + 1) * TILE + BODY_W / 2 - 1 if vx > 0 else x * TILE - BODY_W / 2 + 1)
            for sx in starts:
                for dash_at in self.dash_times():
                    self.fly(sx, py, vx, self.v_jump, dash_at=dash_at)
        # ground dash, altitude held, no jump at its end
        for dx in (-1, 1):
            for steer in (0.0, dx * self.run):
                self.fly(centre, py, dx * self.dash_speed, 0.0, ground_dash=True, steer=steer)

    def expand_wall(self, px, py, side, col):
        # kick away from the wall for the lockout, then steer
        for steer in (-self.run, 0.0, self.run):
            for dash_at in self.dash_times():
                self.fly(px, py, -side * self.push, self.v_wall, wall_from=(col, side), lock=self.lock, steer=steer, dash_at=dash_at)

    def dash_times(self):
        return [None] + ([0.12, self.apex_t, 0.55] if self.air else [])

    # --- a flight -----------------------------------------------------------------

    def fly(self, px, py, vx, vy, wall_from=None, lock=0.0, steer=None, dash_at=None, ground_dash=False):
        t = 0.0
        dashing = self.dash_t if ground_dash else 0.0
        dashed = ground_dash
        dash_dir = 1 if vx > 0 else -1
        while t < MAX_FLIGHT:
            self.steps += 1
            if self.trace is not None:
                self.trace.append((round(t, 3), round(px), round(py), round(vx), round(vy)))
            # phase bookkeeping
            if dash_at is not None and not dashed and t >= dash_at and vx != 0.0:
                dashed = True
                dashing = self.dash_t
                dash_dir = 1 if vx > 0 else -1
            if dashing > 0.0:
                vx_now = dash_dir * self.dash_speed
                vy = 0.0
                g = 0.0
                dashing -= DT
                if dashing <= 0.0 and steer is not None:
                    vx = steer
            else:
                vx_now = vx if (lock <= 0.0 or steer is None) else vx
                if lock > 0.0:
                    lock -= DT
                    if lock <= 0.0 and steer is not None:
                        vx = steer
                g = self.g_rise if vy < 0.0 else self.g_fall
            # horizontal move
            nx = px + vx_now * DT
            cs = self.cells(nx, py)
            if self.blocked(cs):
                # Pressed against a wall: keep pressing (the player holds into
                # it), so the touch registers the moment the body starts to
                # fall. A dash ends here.
                side = 1 if vx_now > 0 else -1
                col = int((nx + side * BODY_W / 2) // TILE)
                if vy > 0.0:
                    self.add_wall(px, py, side, col, wall_from)
                if dashing > 0.0:
                    dashing = 0.0
                    vx = steer if steer is not None else 0.0
            else:
                px = nx
                self.touch(cs, vy)
            # vertical move
            ny = py + vy * DT
            if vy > 0.0:
                # landing on ground under any footprint column
                feet_row_prev = int((py - 1) // TILE)
                feet_row = int((ny - 1) // TILE)
                if feet_row != feet_row_prev:
                    x0 = int((px - BODY_W / 2) // TILE)
                    x1 = int((px + BODY_W / 2 - 1) // TILE)
                    cols = [int(px // TILE)] + [c for c in range(x0, x1 + 1) if c != int(px // TILE)]
                    for c in cols:
                        ch = self.r.tile(c, feet_row)
                        if ch == "#" or ch == "=":
                            self.add_stand(c, feet_row)
                            return
                        if ch == "v":
                            return  # the void: back to safe ground
            else:
                cs = self.cells(px, ny)
                if self.blocked(cs):
                    vy = 0.0  # a ceiling
                    ny = py
            py = ny
            cs = self.cells(px, py)
            self.touch(cs, vy)
            if px < 0 or px > self.W or py < 0 or py > self.H + TILE:
                return
            vy = min(vy + g * DT, self.max_fall)
            t += DT


# --- Lifts ----------------------------------------------------------------------------

def with_lifts(room):
    """A copy of the room whose lift decks are one-way platforms at rest and at
    the top, with the deck pairs on `.lifts` so the solver can ride them."""
    room.lifts = []
    if not any(t == "lift" for t, _ in room.markers.values()):
        return room
    r = copy.deepcopy(room)
    grid = [list(row) for row in r.grid]
    lifts = []
    for c, (typ, args) in room.markers.items():
        if typ != "lift":
            continue
        parts = args.split()
        w = int(parts[0]) if parts else 6
        top = int(parts[1]) if len(parts) > 1 else 1
        for lx, ly in room.positions_of(c):
            rest = {(x, ly) for x in range(lx, lx + w)}
            high = {(x, top) for x in range(lx, lx + w)}
            for x, y in rest | high:
                if 0 <= y < len(grid) and 0 <= x < len(grid[y]) and grid[y][x] != "#":
                    grid[y][x] = "="
            lifts.append((rest, high))
    r.grid = ["".join(row) for row in grid]
    r.lifts = lifts
    return r


def player_start(room):
    ps = room.positions_of("P")
    x, y = ps[0]
    return ("stand", x, y + 1)


# --- The district at door level ---------------------------------------------------

class District:
    """The progression walked as (room, door arrived by) states, each room's
    passage decided by the solver with the kit owned at the time."""

    def __init__(self, rooms, env):
        self.by = {r.id: r for r in rooms}
        self.env = env
        self.cache = {}

    def sim(self, rid, via, kit):
        key = (rid, via, frozenset(kit))
        if key not in self.cache:
            room = self.by[rid]
            if isinstance(via, tuple):
                start = via  # an explicit ("stand", x, y), e.g. the floor under a drop
            elif via:
                start = door_spawn(room, via)
            else:
                start = player_start(room)
            self.cache[key] = run_from(room, self.env, set(kit), start)
        return self.cache[key]

    def flood(self, origin, kit):
        """States reachable with a fixed kit, and the cells touched per room."""
        seen = {origin}
        frontier = [origin]
        touched = {}
        while frontier:
            rid, via = frontier.pop()
            room = self.by[rid]
            s = self.sim(rid, via, kit)
            touched.setdefault(rid, set()).update(s.touched)
            for d in s.exits:
                if d in room.oneway or d not in room.doors:
                    continue
                need = room.requires.get(d)
                if need and need not in kit:
                    continue
                nxt = tuple(room.doors[d])
                if nxt not in seen:
                    seen.add(nxt)
                    frontier.append(nxt)
        return seen, touched

    def grants(self, touched, owned):
        grown = set()
        for rid, cells in touched.items():
            room = self.by[rid]
            for c, (typ, args) in room.markers.items():
                need = room.requires.get(c)
                if need and need not in owned:
                    continue
                if not any(p in cells for p in room.positions_of(c)):
                    continue
                grant = ABILITIES.get(args) if typ == "ability" else (args if typ == "hack" else None)
                if grant and grant not in owned:
                    grown.add(grant)
        return grown

    def walk(self, origin=(START, None), kit=()):
        """The kit grows from what is touched; returns the kit at first arrival
        per room, the state it was first reached in, and the final kit."""
        owned = set(kit)
        first = {}
        first_state = {}
        changed = True
        while changed:
            changed = False
            seen, touched = self.flood(origin, owned)
            for rid, via in sorted(seen, key=lambda s: (s[0], str(s[1] or ""))):
                first.setdefault(rid, frozenset(owned))
                first_state.setdefault(rid, (via, frozenset(owned)))
            grown = self.grants(touched, owned)
            if grown:
                owned |= grown
                changed = True
            if "sidewinder_carried" in owned and any(rid == "mezz" for rid, _ in seen) and "sidewinder" not in owned:
                owned.add("sidewinder")
                changed = True
        return first, first_state, owned


# --- Spawns and runs ----------------------------------------------------------------

def door_spawn(room, digit):
    """(kind, x, y): a standing tile, or a fall start for a ceiling door."""
    rect = room.door_rect(digit)
    x, y, w, h = rect
    side = room.door_side(rect)
    if side == "left":
        return ("stand", x + w, y + h)
    if side == "right":
        return ("stand", x - 1, y + h)
    if side == "up":
        return ("fall", (x + w / 2.0) * TILE, (y + h) * TILE + TILE)
    right_x, left_x = x + w, x - 1
    if room.is_standable(right_x, y) and room.is_solid(right_x, y):
        return ("stand", right_x, y)
    if room.is_standable(left_x, y) and room.is_solid(left_x, y):
        return ("stand", left_x, y)
    return ("stand", x, y)


def run_from(room, env, kit, start):
    sim = Sim(room, env, kit)
    if start[0] == "stand":
        sim.add_stand(start[1], start[2])
    else:
        for vx in (-sim.run, 0.0, sim.run):
            sim.fly(start[1], start[2], vx, 0.0)
    sim.run_all()
    return sim


def pickups_of(room):
    out = {}
    for c, (typ, args) in room.markers.items():
        if typ in PICKUPS:
            for at in room.positions_of(c):
                out[at] = (typ, args, c)
    return out


def gate_checks(room, env, kit, findings, label=None):
    """Declared air_dash gates: the far lip must be unreachable from the near lip
    without the Sidewinder and reachable with it."""
    name = label or room.id
    for kind, v in room.gates:
        if kind != "air_dash":
            continue
        x1, y, x2 = v
        near, far = (x1, y), (x2, y)
        without = run_from(room, env, kit - {"sidewinder"}, ("stand",) + near)
        if far in without.stand:
            findings.append(f"{name}: air_dash gate {v} BYPASSED: the far lip is reachable without the Sidewinder (kit {sorted(kit - {'sidewinder'}) or '-'})")
        with_it = run_from(room, env, kit | {"sidewinder"}, ("stand",) + near)
        if far not in with_it.stand:
            findings.append(f"{name}: air_dash gate {v}: the far lip is NOT reachable even with the Sidewinder")
        yield (name, v, far in without.stand, far in with_it.stand)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--rooms", nargs="*")
    ap.add_argument("--kit", nargs="*", help="abilities to grant instead of the kit at arrival")
    ap.add_argument("--fixture", help="a .room file to check on its own (gate checks with and without the Sidewinder)")
    ap.add_argument("--png", action="store_true")
    ap.add_argument("--override", nargs="*", default=[], help=".room files that replace the district's rooms of the same id (to judge a fix before it lands)")
    a = ap.parse_args()
    env = Envelope(load_config(CONFIG))
    loaded = load_all(SPECS)
    for path in a.override:
        with open(path, encoding="utf-8") as f:
            fixed = parse(f.read(), path)
        loaded = [fixed if r.id == fixed.id else r for r in loaded]
        print(f"override: {fixed.id} from {path}")
    rooms = [with_lifts(r) for r in loaded]
    first, final_kit = kit_at_arrival(rooms)
    final_kit = set(final_kit) - {"sidewinder_carried"}
    notes = []

    if a.fixture:
        with open(a.fixture, encoding="utf-8") as f:
            room = parse(f.read(), a.fixture)
        kit = set(a.kit or ["mag_hook"])
        findings = []
        t0 = time.time()
        for name, v, bypass, ok in gate_checks(room, env, kit, findings, label=os.path.basename(a.fixture)):
            print(f"{name}: gate {v}: far lip without Sidewinder: {'REACHABLE' if bypass else 'blocked'}; with: {'reachable' if ok else 'BLOCKED'}")
        print(f"({time.time() - t0:.1f}s)")
        for f in findings:
            print("-", f)
        return

    print("# In-room reachability: the Stacks with the kit at arrival\n")
    findings = []
    rows = []
    overlays = {}
    t0 = time.time()
    for r in rooms:
        if a.rooms and r.id not in a.rooms:
            continue
        kit = set(a.kit) if a.kit is not None else set(first.get(r.id, ()))
        picks = pickups_of(r)
        reach_union = set()
        touched_union = set()
        for digit in sorted(r.doors):
            # Arriving by this door, the player is at least as equipped as when
            # the room on the other side was first reached.
            partner = r.doors[digit][0]
            kit_d = kit | set(first.get(partner, ())) if a.kit is None else kit
            sim = run_from(r, env, kit_d, door_spawn(r, digit))
            reach_union |= sim.stand
            touched_union |= sim.touched
            can_leave = {d for d in r.doors if d != digit and d in sim.exits and d not in r.oneway
                         and not (r.requires.get(d) and r.requires[d] not in kit_d)}
            got = sorted(f"{picks[p][2]}:{picks[p][1]}" for p in picks if p in sim.touched)
            rows.append((r.id, digit, ",".join(sorted(kit_d)) or "-", len(sim.stand), ",".join(sorted(can_leave)) or "-", " ".join(got) or "-", sim.steps))
        for p, (typ, args, c) in picks.items():
            need = r.requires.get(c)
            if p in touched_union or (need and need not in kit):
                continue
            # Unreachable on arrival: which later ability opens it, if any?
            opens = None
            for ability in sorted(final_kit - kit):
                touched = set()
                for digit in sorted(r.doors):
                    touched |= run_from(r, env, kit | {ability}, door_spawn(r, digit)).touched
                if p in touched:
                    opens = ability
                    break
            if opens:
                notes.append(f"{r.id}: pickup {c} ({typ} {args}) at {p} needs {opens} beyond the kit at arrival {sorted(kit) or '-'}; declare `requires {c} {opens}` or accept the geometry gate")
            else:
                findings.append(f"{r.id}: pickup {c} ({typ} {args}) at {p} is unreachable with the kit at arrival {sorted(kit) or '-'} and with any single later ability")
        list(gate_checks(r, env, kit, findings))
        overlays[r.id] = (reach_union, touched_union)
    # The district at door level, against the room-level walk's claims.
    if not a.rooms and a.kit is None:
        dist = District(rooms, env)
        t1 = time.time()
        first_door, first_state, kit_door = dist.walk()
        for rid in first:
            if rid not in first_door:
                findings.append(f"{rid}: the room-level walk reaches it, the geometry does not (an in-room passage was assumed on the way)")
        for ability in sorted(final_kit - kit_door):
            findings.append(f"{ability} is never granted once rooms are solved for real")
        traps = []
        for rid, (via, kit_then) in sorted(first_state.items()):
            origins = [(via, f"arriving by door {via}")]
            room = dist.by[rid]
            if via and room.door_side(room.door_rect(via)) == "up":
                # A drop in: a player can wall-jump back up the shaft before
                # landing, but nobody stays in the shaft. Test the floor too.
                landed = dist.sim(rid, via, kit_then).stand
                if landed:
                    floor = max(landed, key=lambda t: (t[1], t[0]))
                    origins.append((("stand",) + floor, f"after landing at {floor} from door {via}"))
            for origin, how in origins:
                back_first, _, back_kit = dist.walk((rid, origin), kit_then)
                if "mezz" not in back_first and not (back_kit - set(kit_then)):
                    traps.append(f"{rid}: {how} with kit {sorted(kit_then) or '-'}, neither the Mezz nor any new ability can be reached again (a trap)")
                    break
        findings.extend(traps)
        print(f"Door-level walk: {len(first_door)} of {len(rooms)} rooms, final kit {sorted(kit_door)}, {len(dist.cache)} room solves, {time.time() - t1:.1f}s")
        order = sorted(first_door.items(), key=lambda kv: (len(kv[1]), kv[0]))
        print("Kit at first arrival (door level): " + "; ".join(f"{rid} [{','.join(sorted(k)) or '-'}]" for rid, k in order))
    print(f"Solved in {time.time() - t0:.1f}s\n")
    print("| room | arrive by | kit | standing tiles | can leave by | pickups touched | steps |")
    print("|---|---|---|---|---|---|---|")
    for row in rows:
        print("| " + " | ".join(str(v) for v in row) + " |")
    print("\n## Findings\n")
    if not findings:
        print("- none")
    for f in findings:
        print("-", f)
    print("\n## Notes (geometry gates the walk does not know about)\n")
    if not notes:
        print("- none")
    for n in notes:
        print("-", n)
    if a.png:
        draw(rooms, overlays, os.path.join(HERE, "reach.png"))
        print(f"\noverlay: {os.path.join(HERE, 'reach.png')}")


def draw(rooms, overlays, path):
    from PIL import Image, ImageDraw
    S = 4
    minx = min(r.cell[0] for r in rooms)
    miny = min(r.cell[1] for r in rooms)
    maxx = max(r.cell[0] + r.size[0] for r in rooms)
    maxy = max(r.cell[1] + r.size[1] for r in rooms)
    im = Image.new("RGB", ((maxx - minx) * CELL[0] * S, (maxy - miny) * CELL[1] * S), (12, 12, 16))
    d = ImageDraw.Draw(im)
    for r in rooms:
        if r.id not in overlays:
            continue
        reach, touched = overlays[r.id]
        ox = (r.cell[0] - minx) * CELL[0] * S
        oy = (r.cell[1] - miny) * CELL[1] * S
        for y, row in enumerate(r.grid):
            for x, c in enumerate(row):
                if c == "#":
                    col = (70, 70, 80)
                elif c == "v":
                    col = (90, 30, 110)
                elif c == "~":
                    col = (30, 110, 130)
                elif (x, y) in touched:
                    col = (30, 60, 40)
                else:
                    col = (22, 22, 28)
                if r.is_standable(x, y):
                    col = (40, 200, 90) if (x, y) in reach else (220, 50, 50)
                if c.isdigit():
                    col = (60, 200, 200)
                elif c not in "#.=v~" and r.markers.get(c, ("",))[0] in PICKUPS:
                    col = (255, 230, 60) if (x, y) in touched else (255, 120, 0)
                d.rectangle([ox + x * S, oy + y * S, ox + x * S + S - 1, oy + y * S + S - 1], fill=col)
        d.text((ox + 3, oy + 2), r.id, fill=(200, 200, 210))
    im.save(path)


if __name__ == "__main__":
    main()
