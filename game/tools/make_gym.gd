extends Node
## Generator for rooms/gym.tscn — the M1 platforming gym.
## Run: godot --headless --path . -s tools/make_gym.gd

const SOLID := Color("3a4256")
const PLATFORM := Color("4b5570")
const LABEL := Color("6f7da3")
const ROOM := Vector2i(3840, 2160)

var _root: Node2D
var _geometry: Node2D
var _labels: Node2D


func _ready() -> void:
	_root = Node2D.new()
	_root.name = "Gym"
	_root.set_script(load("res://src/world/room.gd"))
	_root.set("room_id", &"gym")
	_root.set("display_name", "Movement Gym")
	_root.set("camera_limits", Rect2i(Vector2i.ZERO, ROOM))

	_geometry = Node2D.new()
	_geometry.name = "Geometry"
	_root.add_child(_geometry)

	_labels = Node2D.new()
	_labels.name = "Labels"
	_root.add_child(_labels)

	# --- Shell. Enclosed on purpose: a gym you can fall out of wastes the
	# --- tester's time walking back.
	_solid("Floor", Vector2(1920, 2130), Vector2(3840, 60), SOLID)
	_solid("Ceiling", Vector2(1920, 30), Vector2(3840, 60), SOLID)
	_solid("WallLeft", Vector2(30, 1080), Vector2(60, 2160), SOLID)
	_solid("WallRight", Vector2(3810, 1080), Vector2(60, 2160), SOLID)

	# --- A. Run lane. Long flat ground for acceleration, deceleration and the
	# --- turnaround, under a ceiling with 102px of clearance for an 88px body.
	_solid("LowCeiling", Vector2(360, 1968), Vector2(600, 60), SOLID)

	# --- B. Jump gaps. Two steps up to the tier, then a gap that teaches the
	# --- running jump and a gap that refuses one.
	_solid("StepUp", Vector2(900, 1980), Vector2(240, 60), PLATFORM)
	_solid("JumpA", Vector2(1140, 1830), Vector2(300, 60), PLATFORM)
	_solid("JumpB", Vector2(1650, 1830), Vector2(300, 60), PLATFORM)  # 240px gap
	_solid("JumpC", Vector2(2310, 1830), Vector2(300, 60), PLATFORM)  # 360px gap

	# --- C. Staircase. Each step is a 150px rise against a 168px jump, so it
	# --- should never feel like a coin flip.
	_solid("StairA", Vector2(2700, 1680), Vector2(240, 60), PLATFORM)
	_solid("StairB", Vector2(3060, 1530), Vector2(240, 60), PLATFORM)
	_solid("StairC", Vector2(3420, 1380), Vector2(240, 60), PLATFORM)

	# --- D. Wall shaft. 300px apart: wide enough that you must actually jump
	# --- across, narrow enough that a 420px kick crosses it.
	_solid("ShaftInnerWall", Vector2(3270, 900), Vector2(60, 900), PLATFORM)
	_solid("ShaftOuterWall", Vector2(3630, 900), Vector2(60, 900), PLATFORM)
	_solid("ShaftExit", Vector2(3060, 420), Vector2(360, 60), PLATFORM)

	# --- E. High tier back to the left, ending in a drop long enough to reach
	# --- terminal velocity (~174px of fall is all it takes).
	_solid("HighA", Vector2(2400, 420), Vector2(480, 60), PLATFORM)
	_solid("HighB", Vector2(1680, 420), Vector2(480, 60), PLATFORM)

	_label("RUN · TURN · LOW CEILING", Vector2(120, 2020))
	_label("240 GAP → RUNNING JUMP", Vector2(1000, 1730))
	_label("360 GAP → NEEDS DASH", Vector2(1800, 1730))
	_label("STAIRS ↗", Vector2(2600, 1580))
	_label("WALL SHAFT ↑", Vector2(3130, 1270))
	_label("HIGH LEDGE — LONG DROP ↓", Vector2(1400, 320))

	var spawn := Marker2D.new()
	spawn.name = "PlayerSpawn"
	spawn.position = Vector2(180, 2100)
	_root.add_child(spawn)

	var player: Node = (load("res://src/player/player.tscn") as PackedScene).instantiate()
	player.name = "Player"
	player.position = Vector2(180, 2100)
	_root.add_child(player)

	_own_recursive(_root, _root)

	var packed := PackedScene.new()
	if packed.pack(_root) != OK:
		printerr("pack failed")
		get_tree().quit(1)
		return
	if ResourceSaver.save(packed, "res://rooms/gym.tscn") != OK:
		printerr("save failed")
		get_tree().quit(1)
		return
	print("wrote res://rooms/gym.tscn")
	get_tree().quit(0)


func _solid(solid_name: String, center: Vector2, size: Vector2, color: Color) -> void:
	var body := StaticBody2D.new()
	body.name = solid_name
	body.position = center
	body.collision_layer = 1
	body.collision_mask = 0
	_geometry.add_child(body)

	var shape := RectangleShape2D.new()
	shape.size = size
	var collider := CollisionShape2D.new()
	collider.name = "CollisionShape2D"
	collider.shape = shape
	body.add_child(collider)

	var rect := ColorRect.new()
	rect.name = "ColorRect"
	rect.color = color
	rect.position = -size / 2.0
	rect.size = size
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(rect)


func _label(text: String, at: Vector2) -> void:
	var label := Label.new()
	label.name = text.substr(0, 12).to_pascal_case()
	label.text = text
	label.position = at
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 30)
	label.add_theme_color_override("font_color", LABEL)
	_labels.add_child(label)


## `pack()` only saves nodes it owns, so everything built here needs an owner.
## Instanced sub-scenes are the exception: re-owning *their* internals makes
## pack() write them out as fresh nodes layered on top of the instance, which
## duplicates the whole subtree and leaks it at runtime. Set the instance root's
## owner and stop there — its contents belong to its own scene file.
func _own_recursive(node: Node, owner_node: Node) -> void:
	for child: Node in node.get_children():
		child.owner = owner_node
		if child.scene_file_path.is_empty():
			_own_recursive(child, owner_node)
