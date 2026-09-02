extends Node
## Generator for rooms/combat_gym.tscn — the M2 hit-feel lab.
## Run: godot --headless --path . tools/make_combat_gym.tscn
##
## Same reasoning as the movement gym (tools/README.md): the layout is
## arithmetic, so it lives here as code and comments rather than as 400 lines
## of hand-edited scene text.
##
## Every station isolates exactly one rule from
## docs/combat/damage-pipeline.md, so a tuning session can answer one question
## at a time instead of guessing which of five interacting numbers is wrong.

const SOLID := Color("3a4256")
const PLATFORM := Color("4b5570")
const LABEL := Color("6f7da3")
const ROOM := Vector2i(4096, 1440)
const FLOOR_TOP := 1380.0

var _root: Node2D
var _geometry: Node2D
var _labels: Node2D
var _dummies: Node2D


func _ready() -> void:
	_root = Node2D.new()
	_root.name = "CombatGym"
	_root.set_script(load("res://src/world/room.gd"))
	_root.set("room_id", &"combat_gym")
	_root.set("display_name", "Combat Gym")
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

	# --- Shell. Flat and enclosed: nothing here should be a platforming
	# --- challenge, because the thing under test is the swing.
	_solid("Floor", Vector2(2048, 1410), Vector2(4096, 60), SOLID)
	_solid("Ceiling", Vector2(2048, 30), Vector2(4096, 60), SOLID)
	_solid("WallLeft", Vector2(30, 720), Vector2(60, 1440), SOLID)
	_solid("WallRight", Vector2(4066, 720), Vector2(60, 1440), SOLID)
	# Divider between the two halves. The stations answer one question each and
	# want a still target; the arena is the opposite. Mixing them would mean
	# tuning hitstop while being chased.
	_solid("Divider", Vector2(2400, 1200), Vector2(60, 360), SOLID)

	# --- A. Baseline. DEF 0, stagger threshold 1: everything staggers, every
	# --- number is the weapon's own. This is the dummy the wrench and zipgun
	# --- get tuned against before anything else is turned on.
	_dummy("Baseline", Vector2(640, FLOOR_TOP), 40, 0, 1)
	_label("A · BASELINE\nDEF 0 · STAGGER 1", Vector2(520, 1180))

	# --- B. Armour. DEF 5 is the top of the slice's locked range, which at
	# --- this number scale is where the flat-DEF heavy-hit bias becomes
	# --- obvious: the wrench's 8 lands as 3, the zipgun's 6 as 1 — and a
	# --- floor-1 hit is silent by design, no hitstop at all.
	_dummy("Armoured", Vector2(1120, FLOOR_TOP), 40, 5, 1)
	_label("B · ARMOUR\nDEF 5 · FLOOR-1 IS SILENT", Vector2(980, 1180))

	# --- C. Stagger threshold 12. Sits above the wrench's 8 and below the
	# --- maul's 18, so this is where flinch-versus-stagger knockback reads:
	# --- the wrench nudges it a quarter as far as a heavy hit would.
	_dummy("Heavy", Vector2(1600, FLOOR_TOP), 60, 0, 12)
	_label("C · HEAVY\nSTAGGER 12 · WRENCH ONLY FLINCHES", Vector2(1420, 1180))

	# --- D. Contact damage, at half attack_power. The only station that hits
	# --- back, and the only way to feel the i-frame window and the flash that
	# --- has to communicate it.
	var contact := _dummy("Contact", Vector2(2080, FLOOR_TOP), 40, 0, 1)
	contact.set("hurts_on_contact", true)
	contact.set("attack_power", 6.0)
	_label("D · CONTACT\nHALF POWER · TESTS I-FRAMES", Vector2(1900, 1180))

	# --- E. Elevated, on a ledge a jump does not reach. The only way to hit
	# --- this one is to shoot upward, which is the feel constraint items.md
	# --- exported for M2: the drone is a vertical threat, so every ranged
	# --- weapon must aim up comfortably.
	_solid("HighLedge", Vector2(1360, 780), Vector2(360, 60), PLATFORM)
	_dummy("Elevated", Vector2(1360, 750), 40, 0, 1)
	_label("E · ELEVATED\nAIM UP (W) OR DIAGONAL (W + A/D)", Vector2(1120, 640))

	# --- A firing step, so the diagonal shot has somewhere to be taken from.
	_solid("FiringStep", Vector2(480, 1170), Vector2(300, 60), PLATFORM)

	# --- The arena. Three Scavs, which is the M2 exit test verbatim: "fighting
	# --- 3 Scavs is legible and satisfying". Flat and open on purpose — the
	# --- lesson is spacing, and terrain would let the player solve it with
	# --- geometry instead of with timing. One low platform to break up the
	# --- floor without offering anywhere to camp.
	_solid("ArenaStep", Vector2(3300, 1200), Vector2(420, 60), PLATFORM)
	_encounter("ScavArena", [
		Vector2(2900, FLOOR_TOP),
		Vector2(3450, FLOOR_TOP),
		Vector2(3900, FLOOR_TOP),
	])
	_label("SCAV ARENA — THE M2 EXIT TEST", Vector2(2900, 300))
	_label("YELLOW = WINDUP (BAIT IT)", Vector2(2900, 360))
	_label("GREY = RECOVERY (PUNISH IT)", Vector2(2900, 410))
	_label("CLEAR THEM AND THEY COME BACK", Vector2(2900, 460))

	_label("MELEE  J        RANGED  K        DASH  SHIFT", Vector2(760, 180))
	_label("MELEE HITS REFILL AMMO — WATCH THE COUNTER", Vector2(760, 240))

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

	_own_recursive(_root, _root)

	var packed := PackedScene.new()
	if packed.pack(_root) != OK:
		printerr("pack failed")
		get_tree().quit(1)
		return
	if ResourceSaver.save(packed, "res://rooms/combat_gym.tscn") != OK:
		printerr("save failed")
		get_tree().quit(1)
		return
	print("wrote res://rooms/combat_gym.tscn")
	get_tree().quit(0)


## One dummy. The stat block is the reduced enemy one from
## docs/rpg/stats-and-curves.md — hp, DEF, stagger threshold — because that is
## all an enemy is allowed to have. Set on the instance root, which is the
## shape `pack()` records reliably.
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


## An `Encounter` with one spawn marker per position. The enemies themselves
## are runtime instances, so the room file stores markers rather than a frozen
## snapshot of a fight.
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
