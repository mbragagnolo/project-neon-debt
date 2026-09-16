extends Node
## Generator for the district: rooms/stacks/*.tscn and the world graph.
## Run: godot --headless --path . tools/make_stacks.tscn
##
## Reads every `tools/stacks/*.room` spec (see `RoomSpec`) and writes one
## scene per room plus `src/world/world_graph.tres` for the map screen. The
## specs are the level design; the scenes are output. Same reasoning as the
## gyms (tools/README.md): what a room *is* lives in a file a person can read
## and diff, and the four hundred lines of node text are generated.

const SPEC_DIR := "res://tools/stacks"
const OUT_DIR := "res://rooms/stacks"
const GRAPH_PATH := "res://src/world/world_graph.tres"

const COL_BACK := Color("0d1018")
const COL_SOLID := Color("3a4256")
const COL_PLATFORM := Color("5a6684")
## The palette's `void`: what a solid is past its ring, and what the camera
## sees past a room smaller than its view (the apron in `_void_apron`).
const COL_VOID := Color("07080f")

## The dark each style sits under; lights punch through it (M7).
const AMBIENT: Dictionary = {
	"residential": Color(0.62, 0.66, 0.8),
	"shaft": Color(0.5, 0.55, 0.7),
	"roof": Color(0.48, 0.54, 0.72),
	"mezz": Color(0.62, 0.64, 0.82),
	"gut": Color(0.46, 0.53, 0.56),
	"collections": Color(0.54, 0.54, 0.68),
}
const LIGHT_TEXTURE := "res://assets/fx/light_soft.png"

const ENEMY_SCENES: Dictionary = {
	"e": "res://src/enemies/scav/scav.tscn",
	"d": "res://src/enemies/drone/drone.tscn",
	"r": "res://src/enemies/riot/riot.tscn",
	"E": "res://src/enemies/scav/elite_scav.tscn",
	"B": "res://src/enemies/boss_landlord/landlord.tscn",
}
const ENEMY_NAMES: Dictionary = {
	"e": "Scavs", "d": "Drones", "r": "Riots", "E": "Elite", "B": "Boss",
}

var _spec: RoomSpec
var _dress_json: Dictionary = {}
var _root: Node2D
var _geometry: Node2D
var _hazards: Node2D
var _doors: Node2D
var _props: Node2D
var _pickups: Node2D


func _ready() -> void:
	var specs: Array[RoomSpec] = RoomSpec.load_all(SPEC_DIR)
	if specs.is_empty():
		printerr("no specs in %s" % SPEC_DIR)
		get_tree().quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var graph := WorldGraph.new()
	var failed := false
	for spec: RoomSpec in specs:
		if not spec.errors.is_empty():
			for error: String in spec.errors:
				printerr(error)
			failed = true
			continue
		_build(spec)
		graph.rooms.append(_graph_entry(spec))
	if failed:
		get_tree().quit(1)
		return
	if ResourceSaver.save(graph, GRAPH_PATH) != OK:
		printerr("graph save failed")
		get_tree().quit(1)
		return
	print("wrote %d rooms and %s" % [specs.size(), GRAPH_PATH])
	get_tree().quit(0)


func _graph_entry(spec: RoomSpec) -> Dictionary:
	var doors: Array = []
	var regions: Dictionary = spec.door_regions()
	for digit: String in regions:
		var rect: Rect2i = regions[digit]
		doors.append({
			"id": digit,
			"side": spec.door_side(rect),
			"at": spec.door_cell(rect),
			"target_room": spec.doors[digit]["target_room"],
			"target_door": spec.doors[digit]["target_door"],
		})
	return {
		"id": String(spec.id),
		"name": spec.display_name,
		"style": spec.style,
		"cell": spec.cell,
		"size": spec.size,
		"save": spec.has_marker_type("save"),
		"doors": doors,
	}


func _build(spec: RoomSpec) -> void:
	_spec = spec
	_root = Node2D.new()
	_root.name = String(spec.id).to_pascal_case()
	_root.set_script(load("res://src/world/room.gd"))
	_root.set("room_id", spec.id)
	_root.set("display_name", spec.display_name)
	var limits: Rect2i = camera_limits(spec)
	_root.set("camera_limits", limits)
	_root.set("announces_on_ready", false)

	_geometry = _group("Geometry")
	_hazards = _group("Hazards")
	_doors = _group("Doors")
	_props = _group("Props")
	_pickups = _group("Pickups")

	var dress_data: Dictionary = _dress_data(spec)
	_dress_json = dress_data
	_void_apron(spec, limits)
	_backdrop(spec, dress_data, limits)

	var index: int = 0
	for rect: Rect2i in spec.solid_rects():
		_solid("Solid%d" % index, rect)
		index += 1
	index = 0
	for rect: Rect2i in spec.rects_of("="):
		_platform("Platform%d" % index, rect)
		index += 1
	index = 0
	for rect: Rect2i in spec.rects_of("~"):
		_hazard("Hazard%d" % index, rect, false)
		index += 1
	index = 0
	for rect: Rect2i in spec.rects_of("v"):
		_hazard("Void%d" % index, rect, true)
		index += 1

	var regions: Dictionary = spec.door_regions()
	for digit: String in regions:
		_door(digit, regions[digit])

	for at: Vector2i in spec.positions_of("P"):
		var spawn := Marker2D.new()
		spawn.name = "PlayerSpawn"
		spawn.position = spec.tile_bottom_center(at.x, at.y)
		_root.add_child(spawn)

	for kind: String in ENEMY_SCENES:
		var spots: Array[Vector2i] = spec.positions_of(kind)
		if spots.is_empty():
			continue
		if not ResourceLoader.exists(ENEMY_SCENES[kind]):
			print("  %s: %d x '%s' skipped, no scene yet at %s" % [spec.id, spots.size(), kind, ENEMY_SCENES[kind]])
			continue
		_encounter(kind, spots)

	for c: String in spec.markers:
		var marker: Dictionary = spec.markers[c]
		var regions_of: Array[Rect2i] = spec.regions_of(c)
		for rect: Rect2i in regions_of:
			_marker(c, marker["type"], marker["args"], rect)

	if dress_data.is_empty():
		_dress(spec)
	else:
		# `decor: seeded` keeps the seeded clutter and adds the file's own
		# light on top, so a room can be lit without re-authoring every
		# crate in it. A fully authored room (14-C) leaves the key out.
		if String(dress_data.get("decor", "")) == "seeded":
			_dress(spec, "Clutter")
		_dress_from(spec, dress_data)
	_atmosphere(spec, dress_data)

	_own_recursive(_root, _root)
	var packed := PackedScene.new()
	if packed.pack(_root) != OK:
		printerr("%s: pack failed" % spec.id)
		get_tree().quit(1)
		return
	var path: String = "%s/%s.tscn" % [OUT_DIR, spec.id]
	if ResourceSaver.save(packed, path) != OK:
		printerr("%s: save failed" % spec.id)
		get_tree().quit(1)
		return
	_root.free()


## Where the camera may look: the room's air plus one tile of ring, clamped
## to the cell, and never less than one view. The whole cell was the old
## rule; under the Metroid rule the slab past the ring is black, and a
## camera that pans over it shows nothing. A room shorter or narrower than
## the view is centred in it (docs/art/environment.md, 6).
static func camera_limits(spec: RoomSpec) -> Rect2i:
	var air := Rect2i()
	var found := false
	for y: int in spec.height():
		for x: int in spec.width():
			if not spec.is_air(x, y):
				continue
			var tile := Rect2i(x, y, 1, 1)
			air = tile if not found else air.merge(tile)
			found = true
	if not found:
		air = Rect2i(Vector2i.ZERO, Vector2i(spec.width(), spec.height()))
	var cell := Rect2i(Vector2i.ZERO, Vector2i(spec.width(), spec.height()))
	var ring: Rect2i = air.grow(1).intersection(cell)
	var tile_px: int = int(RoomSpec.TILE)
	var limits := Rect2i(ring.position * tile_px, ring.size * tile_px)
	var view: Vector2i = Vector2i(PixelCamera.view_size())
	if limits.size.x < view.x:
		limits.position.x -= (view.x - limits.size.x) / 2
		limits.size.x = view.x
	if limits.size.y < view.y:
		limits.position.y -= (view.y - limits.size.y) / 2
		limits.size.y = view.y
	return limits


## The void past the cell, for a room the camera centres: four strips
## between the cell and the limits, in the room's canvas so the ambient
## darkens them like the slab's own void. Inside the cell nothing is
## painted, so a window's cut-out still sees the outside layer.
func _void_apron(spec: RoomSpec, limits: Rect2i) -> void:
	var cell := Rect2i(Vector2i.ZERO, Vector2i(spec.pixel_size()))
	var outer: Rect2i = limits.grow(int(RoomSpec.TILE) * 2)
	if cell.encloses(outer):
		return
	var strips: Array[Rect2i] = [
		Rect2i(outer.position.x, outer.position.y, outer.size.x, cell.position.y - outer.position.y),
		Rect2i(outer.position.x, cell.end.y, outer.size.x, outer.end.y - cell.end.y),
		Rect2i(outer.position.x, cell.position.y, cell.position.x - outer.position.x, cell.size.y),
		Rect2i(cell.end.x, cell.position.y, outer.end.x - cell.end.x, cell.size.y),
	]
	var index: int = 0
	for strip: Rect2i in strips:
		if strip.size.x <= 0 or strip.size.y <= 0:
			continue
		var rect := ColorRect.new()
		rect.name = "Void%d" % index
		rect.color = COL_VOID
		rect.position = Vector2(strip.position)
		rect.size = Vector2(strip.size)
		rect.z_index = -50
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_geometry.add_child(rect)
		index += 1


func _group(group_name: String) -> Node2D:
	var node := Node2D.new()
	node.name = group_name
	_root.add_child(node)
	return node


func _px(rect: Rect2i) -> Rect2:
	return Rect2(Vector2(rect.position) * RoomSpec.TILE, Vector2(rect.size) * RoomSpec.TILE)


func _solid(solid_name: String, rect: Rect2i) -> void:
	var px: Rect2 = _px(rect)
	var body := StaticBody2D.new()
	body.name = solid_name
	body.position = px.get_center()
	body.collision_layer = 1
	body.collision_mask = 0
	_geometry.add_child(body)
	var shape := RectangleShape2D.new()
	shape.size = px.size
	var collider := CollisionShape2D.new()
	collider.name = "CollisionShape2D"
	collider.shape = shape
	body.add_child(collider)
	var fill := NinePatchRect.new()
	fill.name = "Wall"
	fill.texture = load("res://assets/tiles/wall_%s.png" % _spec.style)
	# The ring rule (docs/art/environment.md, section 3): a side wears the
	# ring only where it faces air; the strips of the other sides are cut
	# out of the region so the centre tiling never reads them. A block thinner
	# than two rings splits itself between them.
	var ring: float = _wall_margin(_spec.style)
	var air: Dictionary = _air_sides(rect)
	var tex_size: Vector2 = fill.texture.get_size()
	var region := Rect2(Vector2.ZERO, tex_size)
	if not air["l"]:
		region.position.x += ring
		region.size.x -= ring
	if not air["r"]:
		region.size.x -= ring
	if not air["t"]:
		region.position.y += ring
		region.size.y -= ring
	if not air["b"]:
		region.size.y -= ring
	fill.region_rect = region
	var ml: float = ring if air["l"] else 0.0
	var mr: float = ring if air["r"] else 0.0
	var mt: float = ring if air["t"] else 0.0
	var mb: float = ring if air["b"] else 0.0
	if ml > 0.0 and mr > 0.0 and ml + mr > px.size.x:
		ml = floorf(px.size.x * 0.5)
		mr = px.size.x - ml
	if mt > 0.0 and mb > 0.0 and mt + mb > px.size.y:
		mt = floorf(px.size.y * 0.5)
		mb = px.size.y - mt
	fill.patch_margin_left = int(ml)
	fill.patch_margin_top = int(mt)
	fill.patch_margin_right = int(mr)
	fill.patch_margin_bottom = int(mb)
	fill.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_TILE
	fill.axis_stretch_vertical = NinePatchRect.AXIS_STRETCH_MODE_TILE
	fill.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fill.position = -px.size * 0.5
	fill.size = px.size
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(fill)


## Which sides of a solid rectangle face air in the spec (off-grid is solid).
func _air_sides(rect: Rect2i) -> Dictionary:
	var out: Dictionary = {"l": false, "r": false, "t": false, "b": false}
	for y: int in range(rect.position.y, rect.end.y):
		if _spec.is_air(rect.position.x - 1, y):
			out["l"] = true
		if _spec.is_air(rect.end.x, y):
			out["r"] = true
	for x: int in range(rect.position.x, rect.end.x):
		if _spec.is_air(x, rect.position.y - 1):
			out["t"] = true
		if _spec.is_air(x, rect.end.y):
			out["b"] = true
	return out


## The ring depth of a wall sheet, in screen px: `margin` in the json the
## ring tool writes beside it (tools/art/ring.py), one tile otherwise.
func _wall_margin(style: String) -> float:
	var path: String = "res://assets/tiles/wall_%s.json" % style
	if FileAccess.file_exists(path):
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if data is Dictionary and data.has("margin"):
			return float(data["margin"])
	return RoomSpec.TILE


## A one-way ledge: thin, on top of its tile row, passable from below.
func _platform(platform_name: String, rect: Rect2i) -> void:
	var px: Rect2 = _px(rect)
	var thickness: float = 12.0
	var body := StaticBody2D.new()
	body.name = platform_name
	body.position = Vector2(px.get_center().x, px.position.y + thickness * 0.5)
	body.collision_layer = 1 | 1024
	body.collision_mask = 0
	_geometry.add_child(body)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(px.size.x, thickness)
	var collider := CollisionShape2D.new()
	collider.name = "CollisionShape2D"
	collider.shape = shape
	collider.one_way_collision = true
	body.add_child(collider)
	var fill := TextureRect.new()
	fill.name = "Ledge"
	fill.texture = load("res://assets/tiles/platform.png")
	fill.stretch_mode = TextureRect.STRETCH_TILE
	fill.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fill.position = Vector2(-px.size.x * 0.5, -thickness * 0.5)
	fill.size = Vector2(px.size.x, thickness)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(fill)


func _hazard(hazard_name: String, rect: Rect2i, returns_player: bool) -> void:
	var px: Rect2 = _px(rect)
	var hazard := Area2D.new()
	hazard.name = hazard_name
	hazard.set_script(load("res://src/world/hazard.gd"))
	hazard.position = px.get_center()
	hazard.set("size", px.size)
	hazard.set("returns_player", returns_player)
	_hazards.add_child(hazard)


func _door(digit: String, rect: Rect2i) -> void:
	var px: Rect2 = _px(rect)
	var door := Area2D.new()
	door.name = digit
	door.set_script(load("res://src/world/door.gd"))
	door.position = px.get_center()
	door.set("door_id", StringName(digit))
	door.set("target_room", StringName(_spec.doors[digit]["target_room"]))
	door.set("target_door", StringName(_spec.doors[digit]["target_door"]))
	door.set("side", _spec.door_side(rect))
	door.set("size", px.size)
	door.set("spawn_point", _spec.door_spawn(rect))
	door.set("room_size", _spec.pixel_size())
	_doors.add_child(door)
	# The opening, drawn: a lit frame in the wall so a door reads as a door.
	var side: int = _spec.door_side(rect)
	if side == Door.Side.LEFT or side == Door.Side.RIGHT:
		var frame := Sprite2D.new()
		frame.name = "Frame"
		frame.texture = load("res://assets/props/door_frame.png")
		frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		frame.z_index = -2
		door.add_child(frame)
		var lamp := PointLight2D.new()
		lamp.name = "Lamp"
		lamp.texture = load(LIGHT_TEXTURE)
		lamp.color = Color(0.5, 0.9, 1.0)
		lamp.energy = 0.7
		lamp.texture_scale = 2.4
		if _dress_json.has("door_lamp"):
			var dl: Dictionary = _dress_json["door_lamp"]
			var c: Array = dl.get("color", [0.5, 0.9, 1.0])
			lamp.color = Color(float(c[0]), float(c[1]), float(c[2]))
			lamp.energy = float(dl.get("energy", 0.7))
			lamp.texture_scale = float(dl.get("scale", 2.4))
		lamp.position = Vector2(0.0, -px.size.y * 0.5 + 10.0)
		door.add_child(lamp)
	else:
		var hatch := ColorRect.new()
		hatch.name = "Frame"
		hatch.color = Color(0.03, 0.04, 0.07)
		hatch.position = -px.size * 0.5
		hatch.size = px.size
		hatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hatch.z_index = -2
		door.add_child(hatch)


func _encounter(kind: String, spots: Array[Vector2i]) -> void:
	var group := Node2D.new()
	group.name = ENEMY_NAMES[kind]
	group.set_script(load("res://src/world/encounter.gd"))
	group.set("enemy_scene", load(ENEMY_SCENES[kind]))
	group.set("respawn_delay", 0.0)
	if kind == "E" or kind == "B":
		group.set("persist_flag", StringName("encounter.%s.%s" % [_spec.id, String(ENEMY_NAMES[kind]).to_lower()]))
	_root.add_child(group)
	for i: int in spots.size():
		var marker := Marker2D.new()
		marker.name = "Spawn%d" % (i + 1)
		marker.position = _spec.tile_bottom_center(spots[i].x, spots[i].y)
		group.add_child(marker)


func _marker(c: String, type: String, args: String, rect: Rect2i) -> void:
	var at: Vector2 = _spec.tile_bottom_center(rect.position.x, rect.end.y - 1)
	var node_name: String = "%s_%s" % [type.to_pascal_case(), c]
	var parts: PackedStringArray = args.split(" ", false)
	match type:
		"save":
			var terminal := Area2D.new()
			terminal.name = "SavePoint"
			terminal.set_script(load("res://src/world/save_point.gd"))
			terminal.position = at
			terminal.set("save_point_id", _spec.id)
			_props.add_child(terminal)
		"npc":
			var npc := Area2D.new()
			npc.name = "Npc_%s" % parts[0]
			npc.set_script(load("res://src/world/npc.gd"))
			npc.position = at
			npc.set("npc_id", StringName(parts[0]))
			_props.add_child(npc)
		"sign", "notice":
			var sign := Node2D.new()
			sign.name = node_name
			sign.set_script(load("res://src/world/sign.gd"))
			sign.position = at
			# Sized for the 1.5x camera: a panel reads on screen at 1.5x these.
			if type == "notice":
				sign.set("text", Lines.NOTICE_REPOSSESSION)
				sign.set("warning", true)
				sign.set("width", 240.0)
				sign.set("font_size", 12)
			else:
				var warning: bool = args.begins_with("! ")
				sign.set("text", args.trim_prefix("! ").replace("\\n", "\n"))
				sign.set("warning", warning)
				sign.set("width", 200.0)
				sign.set("font_size", 14)
			_props.add_child(sign)
		"tease":
			var tease := Node2D.new()
			tease.name = node_name
			tease.set_script(load("res://src/world/tease.gd"))
			tease.position = at
			_props.add_child(tease)
		"grate":
			var grate := StaticBody2D.new()
			grate.name = "Grate_%s" % parts[0]
			grate.set_script(load("res://src/world/grate.gd"))
			grate.position = Vector2(at.x, at.y)
			grate.set("grate_id", StringName(parts[0]))
			grate.set("open_side", int(parts[1]) if parts.size() > 1 else 1)
			grate.set("size", Vector2(rect.size) * RoomSpec.TILE)
			_props.add_child(grate)
		"breach_door":
			var door: Node = (load("res://src/world/breach_door.tscn") as PackedScene).instantiate()
			door.name = "BreachDoor_%s" % parts[0]
			door.set("position", at)
			door.set("door_id", StringName(parts[0]))
			door.set("size", Vector2(rect.size) * RoomSpec.TILE)
			_props.add_child(door)
		"item", "hack", "ability", "hp_up", "ram_up", "quest_item":
			_pickup(c, type, parts, at)
		"lift":
			var width_tiles: int = int(parts[0]) if parts.size() > 0 else 6
			var top_row: int = int(parts[1]) if parts.size() > 1 else 1
			var lift := AnimatableBody2D.new()
			lift.name = "Lift_%s" % c
			lift.set_script(load("res://src/world/lift.gd"))
			# The marker is the deck's left tile; the deck rests on top of it.
			lift.position = Vector2(
				(float(rect.position.x) + float(width_tiles) * 0.5) * RoomSpec.TILE,
				float(rect.position.y) * RoomSpec.TILE
			)
			lift.set("width", float(width_tiles) * RoomSpec.TILE)
			lift.set("travel", float(rect.position.y - top_row) * RoomSpec.TILE)
			_props.add_child(lift)
		_:
			printerr("%s: unknown marker type '%s'" % [_spec.id, type])


func _pickup(c: String, type: String, parts: PackedStringArray, at: Vector2) -> void:
	var pickup: Node = (load("res://src/world/pickup.tscn") as PackedScene).instantiate()
	var payload: String = parts[0] if parts.size() > 0 else ""
	pickup.name = "%s_%s" % [type.to_pascal_case(), payload if not payload.is_empty() else c]
	pickup.set("position", at)
	pickup.set("pickup_id", StringName("%s_%s" % [_spec.id, c]))
	match type:
		"item":
			pickup.set("kind", Pickup.Kind.ITEM)
			pickup.set("item_id", StringName(payload))
		"hack":
			pickup.set("kind", Pickup.Kind.HACK)
			pickup.set("hack_id", StringName(payload))
		"ability":
			pickup.set("kind", Pickup.Kind.ABILITY)
			pickup.set("ability_id", StringName(payload))
		"hp_up":
			pickup.set("kind", Pickup.Kind.HP_UP)
		"ram_up":
			pickup.set("kind", Pickup.Kind.RAM_UP)
		"quest_item":
			pickup.set("kind", Pickup.Kind.QUEST_ITEM)
			pickup.set("quest_item_id", StringName(payload))
	_pickups.add_child(pickup)


# --- The art pass (M7) ----------------------------------------------------------------

## The backdrop: a tiled interior for the style, and for the rooms that
## open onto the night, the skyline scrolling behind it. A room dressed from
## data draws its planes instead: the outside on a ParallaxBackground, which
## the ambient CanvasModulate does not touch, so a window can be the bright
## area of a dark room; the back wall in the canvas, under the props.
func _backdrop(spec: RoomSpec, dress_data: Dictionary = {}, limits: Rect2i = Rect2i()) -> void:
	if dress_data.has("planes"):
		_planes(spec, dress_data["planes"], limits)
		return
	if spec.style == "roof":
		var parallax := ParallaxBackground.new()
		parallax.name = "Sky"
		parallax.layer = -20
		_root.add_child(parallax)
		var sky := ColorRect.new()
		sky.name = "Night"
		sky.color = Color("07080f")
		sky.position = Vector2(-2000.0, -2000.0)
		sky.size = Vector2(spec.pixel_size().x + 4000.0, spec.pixel_size().y + 4000.0)
		sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sky_layer := ParallaxLayer.new()
		sky_layer.name = "SkyLayer"
		sky_layer.motion_scale = Vector2(0.0, 0.0)
		sky_layer.add_child(sky)
		parallax.add_child(sky_layer)
		for entry: Array in [["skyline_far", 0.12, 0.04, 1], ["skyline_near", 0.3, 0.08, 2]]:
			var layer := ParallaxLayer.new()
			layer.name = String(entry[0]).to_pascal_case()
			layer.motion_scale = Vector2(float(entry[1]), float(entry[2]))
			layer.motion_mirroring = Vector2(960.0, 0.0)
			var strip := TextureRect.new()
			strip.name = "Strip"
			strip.texture = load("res://assets/tiles/%s.png" % entry[0])
			strip.stretch_mode = TextureRect.STRETCH_TILE
			strip.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			strip.size = Vector2(960.0 * 3.0, 540.0)
			strip.position = Vector2(-960.0, spec.pixel_size().y - 540.0 - 60.0 * float(entry[3]))
			strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
			layer.add_child(strip)
			parallax.add_child(layer)
		return
	var back := TextureRect.new()
	back.name = "Backdrop"
	back.texture = load("res://assets/tiles/back_%s.png" % spec.style)
	back.stretch_mode = TextureRect.STRETCH_TILE
	back.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	back.size = spec.pixel_size()
	back.z_index = -10
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_geometry.add_child(back)


## The room's planes from its dress json. A plane marked `unlit` (the
## outside, seen through a window) goes on its own CanvasLayer so the
## room's CanvasModulate cannot darken it, following the viewport so it
## sits in world space, under a Parallax2D for its depth. The Parallax2D is
## registered with the camera centred in the room's limits: there the plane
## is exactly at `at`; as the camera pans the plane lags by
## (1 - parallax) x the pan, so it must be bigger than the glass by that.
## Measured on 4.7: a Parallax2D sits at screen_offset x (1 - scroll_scale)
## + scroll_offset, where screen_offset is the camera's centre minus half
## the unzoomed viewport.
func _planes(spec: RoomSpec, planes: Array, limits: Rect2i = Rect2i()) -> void:
	var outside: CanvasLayer = null
	var centre: Vector2 = Vector2(limits.position) + Vector2(limits.size) * 0.5
	var home: Vector2 = centre - PixelCamera.view_size() * PixelCamera.ZOOM * 0.5
	for i: int in planes.size():
		var plane: Dictionary = planes[i]
		var tex_path: String = plane["texture"]
		if not ResourceLoader.exists(tex_path):
			print("  %s: plane %s skipped, no texture yet at %s" % [spec.id, plane.get("name", i), tex_path])
			continue
		var sprite := Sprite2D.new()
		sprite.name = String(plane.get("name", "Plane%d" % i)).to_pascal_case()
		sprite.texture = load(tex_path)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.centered = false
		sprite.position = _vec(plane["at"])
		if plane.get("unlit", false):
			if outside == null:
				outside = CanvasLayer.new()
				outside.name = "Outside"
				outside.layer = -20
				outside.follow_viewport_enabled = true
				_root.add_child(outside)
			var motion: float = float(plane.get("parallax", 1.0))
			var scroller := Parallax2D.new()
			scroller.name = sprite.name + "Scroll"
			scroller.scroll_scale = Vector2(motion, motion)
			scroller.scroll_offset = -home * (1.0 - motion)
			scroller.add_child(sprite)
			outside.add_child(scroller)
		else:
			sprite.z_index = int(plane.get("z", -10))
			_geometry.add_child(sprite)


## The dark, and the weather. A dressed room can set its own ambient.
func _atmosphere(spec: RoomSpec, dress_data: Dictionary = {}) -> void:
	var dark := CanvasModulate.new()
	dark.name = "Ambient"
	dark.color = AMBIENT.get(spec.style, Color(0.6, 0.6, 0.7))
	if dress_data.has("ambient"):
		var a: Array = dress_data["ambient"]
		dark.color = Color(float(a[0]), float(a[1]), float(a[2]))
	_root.add_child(dark)
	var size: Vector2 = spec.pixel_size()
	match spec.style:
		"roof":
			_particles("Rain", Vector2(size.x * 0.5, -40.0), Vector2(size.x * 0.5, 4.0), Vector2(60.0, 1300.0), 1.2, int(size.x / 12.0), "drop", Color(0.7, 0.8, 1.0, 0.5), 2.0)
		"gut":
			for i: int in maxi(1, int(size.x / 900.0)):
				_particles("Steam%d" % i, Vector2(size.x * (float(i) + 0.5) / maxf(1.0, float(int(size.x / 900.0))), size.y - 80.0), Vector2(60.0, 10.0), Vector2(0.0, -40.0), 3.0, 14, "puff", Color(0.7, 0.85, 0.85, 0.18), 9.0)
		_:
			_particles("Dust", size * 0.5, size * 0.5, Vector2(8.0, -6.0), 8.0, int(size.x * size.y / 120000.0), "dot", Color(1.0, 0.95, 0.85, 0.22), 1.6)


func _particles(node_name: String, at: Vector2, extents: Vector2, velocity: Vector2, life: float, amount: int, texture: String, colour: Color, scale: float) -> void:
	var particles := GPUParticles2D.new()
	particles.name = node_name
	particles.position = at
	particles.amount = maxi(amount, 1)
	particles.lifetime = life
	particles.preprocess = life
	particles.texture = load("res://assets/fx/%s.png" % texture)
	particles.z_index = -3
	particles.modulate = colour
	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(extents.x, extents.y, 1.0)
	material.direction = Vector3(velocity.x, velocity.y, 0.0)
	material.spread = 8.0
	material.initial_velocity_min = velocity.length() * 0.8
	material.initial_velocity_max = velocity.length() * 1.2
	material.gravity = Vector3.ZERO
	material.scale_min = scale
	material.scale_max = scale * 1.4
	particles.process_material = material
	_root.add_child(particles)


## A room designed from a concept (docs/art/environment.md, section 4) is
## dressed from `tools/stacks/<id>.dress.json` instead of the random pass:
## its planes, its props at fixed positions, its lights. Missing textures
## are skipped with a note, so the file can name assets before they exist.
func _dress_data(spec: RoomSpec) -> Dictionary:
	var path: String = "%s/%s.dress.json" % [SPEC_DIR, spec.id]
	if not FileAccess.file_exists(path):
		return {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if data is Dictionary:
		return data
	printerr("%s: cannot parse %s" % [spec.id, path])
	return {}


func _dress_from(spec: RoomSpec, data: Dictionary) -> void:
	var decor := Node2D.new()
	decor.name = "Decor"
	decor.z_index = -5
	_root.add_child(decor)
	var props: Array = data.get("props", [])
	for i: int in props.size():
		var prop: Dictionary = props[i]
		var tex_path: String = prop["texture"]
		if not ResourceLoader.exists(tex_path):
			print("  %s: prop %s skipped, no texture yet at %s" % [spec.id, prop.get("name", i), tex_path])
			continue
		var texture: Texture2D = load(tex_path)
		var sprite := Sprite2D.new()
		sprite.name = String(prop.get("name", tex_path.get_file().get_basename())).to_pascal_case()
		sprite.texture = texture
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.centered = false
		# `at` is where the prop stands: its bottom centre, in room px.
		var at: Vector2 = _vec(prop["at"])
		sprite.position = Vector2(at.x - texture.get_width() * 0.5, at.y - texture.get_height())
		if prop.get("flip", false):
			sprite.flip_h = true
		sprite.z_index = int(prop.get("z", 0))
		decor.add_child(sprite)
	var emitters: Array = data.get("particles", [])
	for i: int in emitters.size():
		var e: Dictionary = emitters[i]
		var c: Array = e.get("color", [1.0, 1.0, 1.0, 0.5])
		_particles(String(e.get("name", "Particles%d" % i)).to_pascal_case(), _vec(e["at"]), _vec(e["extents"]), _vec(e["velocity"]),
			float(e.get("life", 1.0)), int(e.get("amount", 40)), String(e.get("texture", "dot")),
			Color(float(c[0]), float(c[1]), float(c[2]), float(c[3]) if c.size() > 3 else 0.5), float(e.get("scale", 1.5)))
	var lights: Array = data.get("lights", [])
	for i: int in lights.size():
		var entry: Dictionary = lights[i]
		var light := PointLight2D.new()
		light.name = String(entry.get("name", "Light%d" % i)).to_pascal_case()
		light.texture = load(entry.get("texture", LIGHT_TEXTURE))
		var c: Array = entry.get("color", [1.0, 1.0, 1.0])
		light.color = Color(float(c[0]), float(c[1]), float(c[2]))
		light.energy = float(entry.get("energy", 0.8))
		light.texture_scale = float(entry.get("scale", 2.0))
		light.position = _vec(entry["at"])
		if entry.has("scale_xy"):
			light.scale = _vec(entry["scale_xy"])
		decor.add_child(light)


func _vec(pair: Array) -> Vector2:
	return Vector2(float(pair[0]), float(pair[1]))


## Dressing: posters, vents, pipes, lamps, crates — placed where the grid
## has room, seeded by the room id so a regeneration is the same room.
func _dress(spec: RoomSpec, node_name: String = "Decor") -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(String(spec.id))
	var decor := Node2D.new()
	decor.name = node_name
	decor.z_index = -5
	_root.add_child(decor)
	var taken: Dictionary = {}
	for c: String in spec.markers:
		for at: Vector2i in spec.positions_of(c):
			for dx: int in range(-2, 3):
				for dy: int in range(-4, 2):
					taken[at + Vector2i(dx, dy)] = true
	for kind: String in ["P", "e", "d", "r", "E", "B"]:
		for at: Vector2i in spec.positions_of(kind):
			for dx: int in range(-2, 3):
				taken[at + Vector2i(dx, 0)] = true
	var regions: Dictionary = spec.door_regions()
	for digit: String in regions:
		var rect: Rect2i = regions[digit]
		for x: int in range(rect.position.x - 3, rect.end.x + 4):
			for y: int in range(rect.position.y - 3, rect.end.y + 4):
				taken[Vector2i(x, y)] = true

	var floors: Array[Vector2i] = []
	var walls: Array[Vector2i] = []
	var ceilings: Array[Vector2i] = []
	for y: int in range(1, spec.height() - 1):
		for x: int in range(1, spec.width() - 1):
			if not spec.is_air(x, y) or taken.has(Vector2i(x, y)):
				continue
			if spec.is_solid(x, y + 1):
				floors.append(Vector2i(x, y))
			if spec.is_solid(x, y - 1):
				ceilings.append(Vector2i(x, y))
			if spec.is_air(x, y + 1) and spec.is_air(x, y + 2) and spec.is_air(x, y - 1):
				walls.append(Vector2i(x, y))
	var cells: int = spec.size.x * spec.size.y
	var sets: Dictionary = _decor_sets(spec.style)
	_place(decor, rng, floors, sets["floor"], cells * 2, spec, taken, 3)
	_place(decor, rng, walls, sets["wall"], cells * 3, spec, taken, 4)
	_place(decor, rng, ceilings, sets["ceiling"], cells * 2, spec, taken, 5, true)


func _decor_sets(style: String) -> Dictionary:
	match style:
		"residential":
			return {"floor": ["crates", "barrel", "monitor"], "wall": ["poster_a", "poster_b", "window", "vent"], "ceiling": ["lamp", "pipe_h"]}
		"roof":
			return {"floor": ["crates", "barrel", "fan"], "wall": ["vent", "window"], "ceiling": ["pipe_h"]}
		"mezz":
			return {"floor": ["crates", "barrel", "monitor"], "wall": ["poster_a", "poster_b", "vent", "window"], "ceiling": ["neon_tube_c", "neon_tube_m", "lamp", "cable"]}
		"gut":
			return {"floor": ["barrel", "crates", "fan"], "wall": ["vent", "pipe_v", "fan"], "ceiling": ["pipe_h", "cable", "lamp"]}
		"collections":
			return {"floor": ["monitor"], "wall": ["window", "poster_b"], "ceiling": ["neon_tube_c", "lamp"]}
	return {"floor": ["barrel"], "wall": ["vent", "pipe_v"], "ceiling": ["pipe_h", "lamp", "cable"]}


func _place(parent: Node, rng: RandomNumberGenerator, spots: Array[Vector2i], names: Array, count: int, spec: RoomSpec, taken: Dictionary, spacing: int, hangs: bool = false) -> void:
	if spots.is_empty() or names.is_empty():
		return
	var placed: int = 0
	var tries: int = 0
	while placed < count and tries < count * 12:
		tries += 1
		var at: Vector2i = spots[rng.randi() % spots.size()]
		if taken.has(at):
			continue
		var name: String = names[rng.randi() % names.size()]
		var texture: Texture2D = load("res://assets/props/%s.png" % name)
		if texture == null:
			continue
		var w_tiles: int = ceili(texture.get_width() / RoomSpec.TILE)
		var fits := true
		for dx: int in range(0, w_tiles):
			if not spec.is_air(at.x + dx, at.y) or taken.has(Vector2i(at.x + dx, at.y)):
				fits = false
		if not fits:
			continue
		var sprite := Sprite2D.new()
		sprite.name = "%s_%d" % [name.to_pascal_case(), placed]
		sprite.texture = texture
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.centered = false
		var px: Vector2 = Vector2(at) * RoomSpec.TILE
		if hangs:
			sprite.position = Vector2(px.x, px.y)
		else:
			sprite.position = Vector2(px.x, px.y + RoomSpec.TILE - texture.get_height())
		parent.add_child(sprite)
		if name == "lamp" or name.begins_with("neon_tube") or name == "window" or name == "monitor":
			var light := PointLight2D.new()
			light.name = "Light"
			light.texture = load(LIGHT_TEXTURE)
			light.position = Vector2(texture.get_width() * 0.5, texture.get_height() * 0.6)
			light.texture_scale = 2.2 if name == "lamp" else 1.6
			light.energy = 0.9 if name == "lamp" else 0.5
			if name == "lamp":
				light.color = Color(1.0, 0.75, 0.45)
			elif name == "neon_tube_m":
				light.color = Color(1.0, 0.4, 0.75)
			elif name == "monitor":
				light.color = Color(0.5, 1.0, 0.6)
			else:
				light.color = Color(0.45, 0.9, 1.0)
			sprite.add_child(light)
		for dx: int in range(-spacing, w_tiles + spacing):
			for dy: int in range(-2, 3):
				taken[at + Vector2i(dx, dy)] = true
		placed += 1


## `pack()` only saves nodes it owns. Instanced sub-scenes keep their own
## internals: set the instance root's owner and stop there.
func _own_recursive(node: Node, owner_node: Node) -> void:
	for child: Node in node.get_children():
		child.owner = owner_node
		if child.scene_file_path.is_empty():
			_own_recursive(child, owner_node)
