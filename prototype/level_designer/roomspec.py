"""A Python port of src/world/room_spec.gd, enough for the reach spike."""
import glob
import os

TILE = 60.0
CELL = (32, 18)
GROUND = "#="  # what feet stand on
ENEMIES = "edrEB"


class Room:
    def __init__(self):
        self.id = ""
        self.name = ""
        self.style = "residential"
        self.cell = (0, 0)
        self.size = (1, 1)
        self.doors = {}     # digit -> (target_room, target_door)
        self.markers = {}   # char -> (type, args)
        self.gates = []     # (kind, [ints])
        self.requires = {}  # digit or char -> ability
        self.oneway = set()
        self.grid = []
        self.source = ""
        self.errors = []

    @property
    def width(self):
        return self.size[0] * CELL[0]

    @property
    def height(self):
        return self.size[1] * CELL[1]

    def tile(self, x, y):
        if y < 0 or y >= len(self.grid) or x < 0 or x >= len(self.grid[y]):
            return "#"
        return self.grid[y][x]

    def is_solid(self, x, y):
        return self.tile(x, y) == "#"

    def is_ground(self, x, y):
        return self.tile(x, y) in GROUND

    def is_open(self, x, y):
        """A body in flight passes through it: anything but solid."""
        return self.tile(x, y) != "#"

    def is_standable(self, x, y):
        return self.is_ground(x, y) and self.is_open(x, y - 1)

    def positions_of(self, c):
        return [(x, y) for y, row in enumerate(self.grid) for x, ch in enumerate(row) if ch == c]

    def door_rect(self, digit):
        """(x, y, w, h) of a door run; doors are rectangular runs on an edge."""
        ps = self.positions_of(digit)
        if not ps:
            return None
        xs = [p[0] for p in ps]
        ys = [p[1] for p in ps]
        return (min(xs), min(ys), max(xs) - min(xs) + 1, max(ys) - min(ys) + 1)

    def door_side(self, rect):
        x, y, w, h = rect
        if x == 0:
            return "left"
        if x + w == self.width:
            return "right"
        if y == 0:
            return "up"
        return "down"

    def under(self, x, y):
        """What is below tile (x, y): ('floor', depth) | ('void', depth) | ('hazard', depth) | ('none', depth)."""
        d = 1
        while y + d < self.height:
            c = self.tile(x, y + d)
            if c in GROUND:
                return ("floor", d)
            if c == "v":
                return ("void", d)
            if c == "~":
                return ("hazard", d)
            d += 1
        return ("none", d)


def parse(text, source=""):
    r = Room()
    r.source = source
    in_grid = False
    for raw in text.split("\n"):
        line = raw.rstrip("\r")
        if in_grid:
            if line.strip():
                r.grid.append(line)
            continue
        t = line.strip()
        if not t or t.startswith("//"):
            continue
        if t == "grid":
            in_grid = True
            continue
        parts = t.split()
        key = parts[0]
        if key == "room":
            r.id = parts[1]
        elif key == "name":
            r.name = t[5:].strip()
        elif key == "style":
            r.style = parts[1]
        elif key == "cell":
            r.cell = (int(parts[1]), int(parts[2]))
        elif key == "size":
            r.size = (int(parts[1]), int(parts[2]))
        elif key == "door":
            r.doors[parts[1]] = (parts[2], parts[3])
        elif key == "marker":
            rest = t[t.find(parts[2]) + len(parts[2]):].strip()
            r.markers[parts[1]] = (parts[2], rest)
        elif key == "requires":
            r.requires[parts[1]] = parts[2]
        elif key == "oneway":
            r.oneway.add(parts[1])
        elif key == "gate":
            r.gates.append((parts[1], [int(v) for v in parts[2:]]))
        else:
            r.errors.append(f"unknown header line: {t}")
    if len(r.grid) != r.height:
        r.errors.append(f"{r.id}: grid has {len(r.grid)} rows, size says {r.height}")
    for y, row in enumerate(r.grid):
        if len(row) != r.width:
            r.errors.append(f"{r.id}: row {y} has {len(row)} columns, size says {r.width}")
    return r


def load_all(dir_path):
    out = []
    for p in sorted(glob.glob(os.path.join(dir_path, "*.room"))):
        with open(p, encoding="utf-8") as f:
            out.append(parse(f.read(), p))
    return out
