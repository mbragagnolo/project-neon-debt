class_name RoomSpec
extends RefCounted
## A district room as text (docs/level-design/stacks.md).
##
## Rooms are authored as ASCII grids on the 60px greybox tile, one character
## per tile, with a small header naming the room, its map cell, its doors and
## its markers. `tools/make_stacks.gd` turns a spec into a scene; the tests
## read the specs directly to check the district's promises — every door has
## a partner, every gate clears the movement envelope, every item is where
## items.md put it.
##
## Reserved grid characters:
##   #  solid       .  air         =  one-way platform    ~  live hazard
##   v  void — a drop that returns the player to safe ground, with damage
##   0-9 doors (a run of the same digit on the room's edge is one door)
##   P  player start (the first room only)
##   e  Scav  d  Watcher drone  r  Riot unit  E  Elite Scav  B  the boss
## Anything else is a marker the header declares:
##   marker <char> <type> [args...]
## with types: save, npc <id>, sign <text>, notice, tease, grate <id> <side>,
## breach_door <id>, item <id>, hack <id>, ability <flag>, hp_up, ram_up,
## quest_item <id>, lift <width_tiles> <top_row>.
## Gates the tests check:
##   gate air_dash <x1> <y> <x2>     a level gap between two solid lips
##   gate shaft <x1> <x2> <y_top> <y_bottom>   two facing walls
##   gate tease <x> <y>              the ledge tile the tease stands on
## What a door or a marker needs before it can be passed or taken — the
## progression test walks the district with a growing kit:
##   requires <door digit or marker char> <mag_hook|cyberdeck|breach|sidewinder>
## A door that cannot be used to *leave* this room — a drop, or a grate that
## is solid from this side:
##   oneway <door digit>

const TILE := 60.0
const CELL_TILES := Vector2i(32, 18)
const RESERVED := "#.=~v0123456789PedrEB"

var id: StringName = &""
var display_name: String = ""
## Which set of walls, backdrop, lights and dressing the generator uses:
## residential, shaft, roof, mezz, gut, collections (docs/art/direction.md).
var style: String = "residential"
var cell: Vector2i = Vector2i.ZERO
var size: Vector2i = Vector2i.ONE
var doors: Dictionary = {}
var markers: Dictionary = {}
var gates: Array[Dictionary] = []
## door digit or marker char -> ability name
var requires: Dictionary = {}
## door digits this room cannot be left through
var oneway: PackedStringArray = PackedStringArray()
var grid: PackedStringArray = PackedStringArray()
var source: String = ""
var errors: PackedStringArray = PackedStringArray()


static func parse(text: String, source_path: String = "") -> RoomSpec:
	var spec := RoomSpec.new()
	spec.source = source_path
	var in_grid := false
	for raw: String in text.split("\n"):
		var line: String = raw.rstrip("\r")
		if in_grid:
			if line.strip_edges().is_empty():
				continue
			spec.grid.append(line)
			continue
		var trimmed: String = line.strip_edges()
		if trimmed.is_empty() or trimmed.begins_with("//"):
			continue
		if trimmed == "grid":
			in_grid = true
			continue
		var parts: PackedStringArray = trimmed.split(" ", false)
		match parts[0]:
			"room":
				spec.id = StringName(parts[1])
			"name":
				spec.display_name = trimmed.substr(5).strip_edges()
			"style":
				spec.style = parts[1]
			"cell":
				spec.cell = Vector2i(int(parts[1]), int(parts[2]))
			"size":
				spec.size = Vector2i(int(parts[1]), int(parts[2]))
			"door":
				spec.doors[parts[1]] = {"target_room": parts[2], "target_door": parts[3]}
			"marker":
				var rest: String = trimmed.substr(trimmed.find(parts[2]) + parts[2].length()).strip_edges()
				spec.markers[parts[1]] = {"type": parts[2], "args": rest}
			"requires":
				spec.requires[parts[1]] = parts[2]
			"oneway":
				spec.oneway.append(parts[1])
			"gate":
				var gate: Dictionary = {"kind": parts[1]}
				var numbers: Array[int] = []
				for index: int in range(2, parts.size()):
					numbers.append(int(parts[index]))
				gate["values"] = numbers
				spec.gates.append(gate)
			_:
				spec.errors.append("unknown header line: %s" % trimmed)
	spec._validate()
	return spec


static func load_file(path: String) -> RoomSpec:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		var spec := RoomSpec.new()
		spec.errors.append("cannot open %s" % path)
		return spec
	var text: String = file.get_as_text()
	file.close()
	return parse(text, path)


## Every spec in a directory, sorted by id.
static func load_all(dir_path: String = "res://tools/stacks") -> Array[RoomSpec]:
	var out: Array[RoomSpec] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	var names: PackedStringArray = PackedStringArray()
	for file_name: String in dir.get_files():
		if file_name.ends_with(".room"):
			names.append(file_name)
	names.sort()
	for file_name: String in names:
		out.append(load_file("%s/%s" % [dir_path, file_name]))
	return out


# --- Geometry -----------------------------------------------------------------

func width() -> int:
	return size.x * CELL_TILES.x


func height() -> int:
	return size.y * CELL_TILES.y


func pixel_size() -> Vector2:
	return Vector2(width(), height()) * TILE


func tile(x: int, y: int) -> String:
	if y < 0 or y >= grid.size() or x < 0 or x >= grid[y].length():
		return "#"
	return grid[y][x]


func is_solid(x: int, y: int) -> bool:
	return tile(x, y) == "#"


func is_air(x: int, y: int) -> bool:
	var c: String = tile(x, y)
	return c != "#" and c != "=" and c != "v" and c != "~"


## Feet position (px) of a marker standing on tile (x, y).
func tile_bottom_center(x: int, y: int) -> Vector2:
	return Vector2((float(x) + 0.5) * TILE, float(y + 1) * TILE)


func positions_of(c: String) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y: int in grid.size():
		for x: int in grid[y].length():
			if grid[y][x] == c:
				out.append(Vector2i(x, y))
	return out


## Greedy rectangles covering every tile equal to `c`: horizontal runs,
## merged downward while the run below is identical.
func rects_of(c: String) -> Array[Rect2i]:
	var taken: Dictionary = {}
	var out: Array[Rect2i] = []
	for y: int in grid.size():
		var x: int = 0
		while x < grid[y].length():
			if grid[y][x] != c or taken.has(Vector2i(x, y)):
				x += 1
				continue
			var run: int = 0
			while x + run < grid[y].length() and grid[y][x + run] == c and not taken.has(Vector2i(x + run, y)):
				run += 1
			var rows: int = 1
			while y + rows < grid.size():
				var same := true
				for dx: int in run:
					if tile(x + dx, y + rows) != c or taken.has(Vector2i(x + dx, y + rows)):
						same = false
						break
				if not same:
					break
				rows += 1
			for dy: int in rows:
				for dx: int in run:
					taken[Vector2i(x + dx, y + dy)] = true
			out.append(Rect2i(x, y, run, rows))
			x += run
	return out


func solid_rects() -> Array[Rect2i]:
	return rects_of("#")


## Contiguous regions of one character (a door, a breach-door column), as
## rectangles. Marker regions are expected to be rectangular.
func regions_of(c: String) -> Array[Rect2i]:
	return rects_of(c)


func door_regions() -> Dictionary:
	var out: Dictionary = {}
	for digit: String in doors:
		var regions: Array[Rect2i] = regions_of(digit)
		if not regions.is_empty():
			out[digit] = regions[0]
	return out


## Which edge a door sits on.
func door_side(rect: Rect2i) -> int:
	if rect.position.x == 0:
		return Door.Side.LEFT
	if rect.end.x == width():
		return Door.Side.RIGHT
	if rect.position.y == 0:
		return Door.Side.UP
	return Door.Side.DOWN


## Where an arriving player stands (px, room-local, feet).
##
## Side doors: a tile and a half in, on the floor the door run ends on. A
## ceiling door (arriving from above): centred in the hole, a tile down, so
## the fall continues. A floor door (arriving from below, still rising):
## *beside* the hole on solid ground — the momentum pops the player up next
## to it rather than back down through it.
func door_spawn(rect: Rect2i) -> Vector2:
	match door_side(rect):
		Door.Side.LEFT:
			return Vector2(float(rect.end.x) * TILE + TILE * 0.5, float(rect.end.y) * TILE)
		Door.Side.RIGHT:
			return Vector2(float(rect.position.x) * TILE - TILE * 0.5, float(rect.end.y) * TILE)
		Door.Side.UP:
			return Vector2((float(rect.position.x) + float(rect.size.x) * 0.5) * TILE, float(rect.end.y) * TILE + TILE)
	var floor_y: float = float(rect.position.y) * TILE
	var right_x: int = rect.end.x
	var left_x: int = rect.position.x - 1
	if is_air(right_x, rect.position.y - 1) and is_solid(right_x, rect.position.y):
		return Vector2((float(right_x) + 0.5) * TILE, floor_y)
	if is_air(left_x, rect.position.y - 1) and is_solid(left_x, rect.position.y):
		return Vector2((float(left_x) + 0.5) * TILE, floor_y)
	return Vector2((float(rect.position.x) + float(rect.size.x) * 0.5) * TILE, floor_y)


## The map cell a door belongs to, within the room.
func door_cell(rect: Rect2i) -> Vector2i:
	return Vector2i(rect.position.x / CELL_TILES.x, rect.position.y / CELL_TILES.y)


func has_marker_type(type: String) -> bool:
	for c: String in markers:
		if markers[c]["type"] == type and not positions_of(c).is_empty():
			return true
	return false


## Every marker of a type, as (char, args, tile) triples.
func markers_of_type(type: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for c: String in markers:
		if markers[c]["type"] != type:
			continue
		for at: Vector2i in positions_of(c):
			out.append({"char": c, "args": markers[c]["args"], "at": at})
	return out


func _validate() -> void:
	if id == &"":
		errors.append("no room id")
	if grid.size() != height():
		errors.append("%s: grid has %d rows, size says %d" % [id, grid.size(), height()])
	for y: int in grid.size():
		if grid[y].length() != width():
			errors.append("%s: row %d has %d columns, size says %d" % [id, y, grid[y].length(), width()])
		for x: int in grid[y].length():
			var c: String = grid[y][x]
			if RESERVED.contains(c) or markers.has(c):
				continue
			errors.append("%s: undeclared marker '%s' at %d,%d" % [id, c, x, y])
	for digit: String in doors:
		if positions_of(digit).is_empty():
			errors.append("%s: door %s declared but not in the grid" % [id, digit])
	for digit: String in "0123456789":
		if not positions_of(digit).is_empty() and not doors.has(digit):
			errors.append("%s: door %s in the grid but not declared" % [id, digit])
