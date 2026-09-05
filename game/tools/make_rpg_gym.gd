extends Node
## Generator for rooms/rpg_gym.tscn — the M3 gear-and-levels lab.
## Run: godot --headless --path . tools/make_rpg_gym.tscn
##
## M3's exit test is "equipping better gear visibly changes combat math; HUD
## shows it", and the word doing the work is *visibly*. So the room is built
## around one loop the player can run in twenty seconds: open a chest, open the
## loadout screen, swap, hit the same dummy, watch LAST HIT change. Everything
## else here exists to make that comparison honest — three identical dummies
## that differ only in DEF, and a pen of Scavs to pay for the levels that move
## the multiplier.
##
## Same reasoning as the other two gyms (tools/README.md): the layout is
## arithmetic, so it lives here as code and comments rather than as several
## hundred lines of hand-edited scene text.

const SOLID := Color("3a4256")
const PLATFORM := Color("4b5570")
const LABEL := Color("6f7da3")
const ROOM := Vector2i(5120, 1440)
const FLOOR_TOP := 1380.0

## The eight found items, in acquisition order from items.md's placement table
## — so walking the armoury left to right is the district's pacing, compressed.
const CHESTS: Array = [
	["utility_blade", "BLADE", 420.0],
	["work_boots", "BOOTS", 620.0],
	["nailgun", "NAILGUN", 820.0],
	["linesman_gloves", "GLOVES", 1020.0],
	["padded_jacket", "JACKET", 1220.0],
	["breaker_maul", "MAUL", 1420.0],
	["rivet_gun", "RIVET GUN", 1620.0],
	["scavved_hardhat", "HARDHAT", 1820.0],
]

var _root: Node2D
var _geometry: Node2D
var _labels: Node2D
var _dummies: Node2D
var _pickups: Node2D


func _ready() -> void:
	_root = Node2D.new()
	_root.name = "RpgGym"
	_root.set_script(load("res://src/world/room.gd"))
	_root.set("room_id", &"rpg_gym")
	_root.set("display_name", "RPG Gym")
	_root.set("camera_limits", Rect2i(Vector2i.ZERO, ROOM))

	_geometry = Node2D.new()
	_geometry.name = "Geometry"
	_root.add_child(_geometry)

	_labels = Node2D.new()
	_labels.name = "Labels"
	_root.add_child(_labels)

	_dummies = Node2D.new()
	_dummies.name = "Dummies"
	_root.add_child(_dummies)

	_pickups = Node2D.new()
	_pickups.name = "Pickups"
	_root.add_child(_pickups)

	# --- Shell. Flat and enclosed: nothing here is a platforming challenge,
	# --- because the thing under test is a number changing.
	_solid("Floor", Vector2(2560, 1410), Vector2(5120, 60), SOLID)
	_solid("Ceiling", Vector2(2560, 30), Vector2(5120, 60), SOLID)
	_solid("WallLeft", Vector2(30, 720), Vector2(60, 1440), SOLID)
	_solid("WallRight", Vector2(5090, 720), Vector2(60, 1440), SOLID)
	# The pen is walled off. Comparing damage numbers wants a still target, and
	# a Scav is the opposite of one.
	_solid("PenWall", Vector2(4060, 1140), Vector2(60, 480), SOLID)

	# --- A. The armoury. Every found item in the slice, in one row, in the
	# --- order the district hands them out. Chests rather than a debug key so
	# --- the pickup path — prompt, toast, auto-equip for clothing, never for
	# --- weapons — is what gets exercised.
	_label("A - ARMOURY: TAKE WHAT YOU WANT TO FEEL", Vector2(300, 900))
	# Built from the bindings rather than typed, so a rebind cannot leave the
	# wall telling players to press a key that does nothing (#4).
	_label(
		"%s TAKE     %s LOADOUT" % [
			InputPrompt.label(&"interact"), InputPrompt.label(&"toggle_inventory"),
		],
		Vector2(300, 960)
	)
	for entry: Array in CHESTS:
		_chest(String(entry[0]), String(entry[1]), float(entry[2]))

	# --- B. The wall. Three dummies with 200 HP that differ in exactly one
	# --- number, so the only variable left is what is in your hands. DEF 0 is
	# --- the weapon's own number, DEF 2 is the district's middle, DEF 5 is the
	# --- top of the locked range and where the flat-DEF heavy-hit bias stops
	# --- being an argument and becomes obvious.
	_label("B - THE WALL: SAME DUMMY, DIFFERENT ARMOUR", Vector2(2180, 620))
	_label("SWAP A WEAPON AND WATCH ~LAST HIT~", Vector2(2180, 680))
	_dummy("ArmourNone", Vector2(2300, FLOOR_TOP), 200, 0, 9999)
	_label("DEF 0", Vector2(2250, 1190))
	_dummy("ArmourLight", Vector2(2600, FLOOR_TOP), 200, 2, 9999)
	_label("DEF 2", Vector2(2550, 1190))
	_dummy("ArmourHeavy", Vector2(2900, FLOOR_TOP), 200, 5, 9999)
	_label("DEF 5", Vector2(2850, 1190))

	# --- C. The range. The rivet gun is the one V1 projectile that drops, and
	# --- an arc is unreadable against a target you are standing next to. The
	# --- far dummy is far enough that the drop is visible; the high one keeps
	# --- M2's aim-up constraint honest now that a weapon exists which can
	# --- quietly fail it.
	_label("C - THE RANGE: THE RIVET DROPS - LEAD IT", Vector2(3300, 620))
	_dummy("FarTarget", Vector2(3900, FLOOR_TOP), 200, 0, 9999)
	_solid("HighLedge", Vector2(3500, 800), Vector2(360, 60), PLATFORM)
	_dummy("HighTarget", Vector2(3500, 770), 200, 0, 9999)
	_label("AIM UP: W  /  DIAGONAL: W + A/D", Vector2(3300, 680))

	# --- D. The pen. Six Scavs is level 2 at the locked curve (60 XP, 10 a
	# --- Scav), which is two clears of this fight — close enough to feel the
	# --- level-up as an event rather than as a number that drifted.
	_label("D - THE PEN: 6 SCAVS = LEVEL 2", Vector2(4200, 300))
	_label("LEVEL UP IS A FULL HEAL", Vector2(4200, 360))
	_label("CLEAR THEM AND THEY COME BACK", Vector2(4200, 420))
	_encounter("ScavPen", [
		Vector2(4400, FLOOR_TOP),
		Vector2(4700, FLOOR_TOP),
		Vector2(4950, FLOOR_TOP),
	])

	_label("MELEE  J     RANGED  K     DASH  SHIFT", Vector2(300, 240))
	_label(
		"LOADOUT  %s     TAKE  %s" % [
			InputPrompt.key(&"toggle_inventory").to_upper(),
			InputPrompt.key(&"interact").to_upper(),
		],
		Vector2(300, 300)
	)
	_label("LEVELS MOVE THE MULTIPLIER. GEAR MOVES THE WEAPON.", Vector2(300, 360))

	var spawn := Marker2D.new()
	spawn.name = "PlayerSpawn"
	spawn.position = Vector2(240, FLOOR_TOP)
	_root.add_child(spawn)

	var player: Node = (load("res://src/player/player.tscn") as PackedScene).instantiate()
	player.name = "Player"
	player.position = Vector2(240, FLOOR_TOP)
	_root.add_child(player)

	var hud := CanvasLayer.new()
	hud.name = "DebugHud"
	hud.set_script(load("res://src/ui/debug_combat_hud.gd"))
	_root.add_child(hud)

	var screen := CanvasLayer.new()
	screen.name = "EquipScreen"
	screen.set_script(load("res://src/ui/menus/equip_screen.gd"))
	_root.add_child(screen)

	_own_recursive(_root, _root)

	var packed := PackedScene.new()
	if packed.pack(_root) != OK:
		printerr("pack failed")
		get_tree().quit(1)
		return
	if ResourceSaver.save(packed, "res://rooms/rpg_gym.tscn") != OK:
		printerr("save failed")
		get_tree().quit(1)
		return
	print("wrote res://rooms/rpg_gym.tscn")
	get_tree().quit(0)


## One chest. `pickup_id` is what makes looting persist, and it has to be
## unique across the district — here the item id doubles as one, since the gym
## holds each item exactly once.
func _chest(item_id: String, label_text: String, at_x: float) -> void:
	var scene := load("res://src/world/pickup.tscn") as PackedScene
	var pickup: Node = scene.instantiate()
	pickup.name = label_text.to_pascal_case()
	pickup.set("position", Vector2(at_x, FLOOR_TOP))
	pickup.set("item_id", StringName(item_id))
	pickup.set("pickup_id", StringName("rpg_gym_%s" % item_id))
	_pickups.add_child(pickup)
	_label(label_text, Vector2(at_x - 60.0, 1120.0))


## One dummy. Stagger threshold 9999 on purpose: these are for reading damage
## numbers off, and a target that flinches across the room is a target you have
## to walk to before every comparison.
func _dummy(
	dummy_name: String, at: Vector2, hp: int, defense: int, stagger_threshold: int
) -> Node:
	var scene := load("res://src/enemies/training_dummy/training_dummy.tscn") as PackedScene
	var dummy: Node = scene.instantiate()
	dummy.name = dummy_name
	dummy.set("position", at)
	dummy.set("max_hp", hp)
	dummy.set("defense", defense)
	dummy.set("stagger_threshold", stagger_threshold)
	_dummies.add_child(dummy)
	return dummy


func _encounter(encounter_name: String, positions: Array) -> void:
	var group := Node2D.new()
	group.name = encounter_name
	group.set_script(load("res://src/world/encounter.gd"))
	group.set("enemy_scene", load("res://src/enemies/scav/scav.tscn"))
	group.set("respawn_delay", 2.5)
	_root.add_child(group)

	for i: int in positions.size():
		var marker := Marker2D.new()
		marker.name = "Spawn%d" % (i + 1)
		marker.position = positions[i]
		group.add_child(marker)


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
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", LABEL)
	_labels.add_child(label)


## `pack()` only saves nodes it owns, so everything built here needs an owner.
## Instanced sub-scenes are the exception: re-owning *their* internals makes
## pack() write them out as fresh nodes layered on top of the instance, which
## duplicates the whole subtree and leaks it at runtime. Set the instance
## root's owner and stop there — its contents belong to its own scene file.
func _own_recursive(node: Node, owner_node: Node) -> void:
	for child: Node in node.get_children():
		child.owner = owner_node
		if child.scene_file_path.is_empty():
			_own_recursive(child, owner_node)
