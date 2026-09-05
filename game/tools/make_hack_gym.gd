extends Node
## Generator for rooms/hack_gym.tscn — the M4 hacks lab.
## Run: godot --headless --path . tools/make_hack_gym.tscn
##
## M4's exit test is "all three combat verbs used naturally in one fight". The
## first four stations isolate one hack each against a still target — the
## same shape the combat gym gave the pipeline — and the last one is the fight
## itself: Scavs that ignore Breach next to a machine that cannot.
##
## Same reasoning as the other gyms (tools/README.md): the layout is
## arithmetic, so it lives here as code and comments rather than as several
## hundred lines of hand-edited scene text.

const SOLID := Color("3a4256")
const PLATFORM := Color("4b5570")
const LABEL := Color("6f7da3")
const ROOM := Vector2i(5120, 1440)
const FLOOR_TOP := 1380.0

var _root: Node2D
var _geometry: Node2D
var _labels: Node2D
var _dummies: Node2D
var _pickups: Node2D


func _ready() -> void:
	_root = Node2D.new()
	_root.name = "HackGym"
	_root.set_script(load("res://src/world/room.gd"))
	_root.set("room_id", &"hack_gym")
	_root.set("display_name", "Hack Gym")
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

	# --- Shell. Flat and enclosed: the thing under test is a cast landing,
	# --- and platforming would only put distance between the player and the
	# --- number they came to read.
	_solid("Floor", Vector2(2560, 1410), Vector2(5120, 60), SOLID)
	_solid("Ceiling", Vector2(2560, 30), Vector2(5120, 60), SOLID)
	_solid("WallLeft", Vector2(30, 720), Vector2(60, 1440), SOLID)
	_solid("WallRight", Vector2(5090, 720), Vector2(60, 1440), SOLID)
	# The fight is walled off, like the RPG gym's pen: a Scav that wanders into
	# the Overload station is a comparison ruined.
	_solid("PenWall", Vector2(4060, 1140), Vector2(60, 480), SOLID)

	# --- The gym grants the Cyberdeck so the quickslot cycles. In the district
	# --- the deck is a pickup that precedes Overload (DESIGN.md §2).
	var grants := Node.new()
	grants.name = "GymGrants"
	grants.set_script(load("res://src/world/gym_grants.gd"))
	_root.add_child(grants)

	# --- A. The programs. Firewall is factory-installed; the other two are
	# --- downloaded here so the pickup path — prompt, toast, flag — is what
	# --- gets exercised, not a debug grant.
	_label("A - DOWNLOAD YOUR PROGRAMS", Vector2(300, 900))
	_label(
		"%s DOWNLOAD     CAST %s     CYCLE %s %s" % [
			InputPrompt.label(&"interact"), InputPrompt.label(&"hack_cast"),
			InputPrompt.label(&"hack_prev"), InputPrompt.label(&"hack_next"),
		],
		Vector2(300, 960)
	)
	_program("overload", "OVERLOAD", 460.0)
	_program("breach", "BREACH", 680.0)

	# --- B. Firewall. The only station that hits back, at a power chosen so
	# --- the halving is legible: 12 → contact 6 → Firewall 3. Stand in it,
	# --- cast, watch the damage number change on the same hit.
	_label("B - FIREWALL: STAND IN IT, CAST, WATCH 6 BECOME 3", Vector2(1000, 620))
	_label("HALVES INCOMING DAMAGE FOR 2s. COSTS 4 OF YOUR 12 RAM.", Vector2(1000, 680))
	var contact := _dummy("Contact", Vector2(1300, FLOOR_TOP), 200, 0, 9999)
	contact.set("hurts_on_contact", true)
	contact.set("attack_power", 12.0)

	# --- C. Overload. A shielded, armoured, heavy target: shots ping off the
	# --- front (step 5), the wrench only flinches it (threshold 12), and
	# --- Overload's 15 does both jobs at once — it ignores the shield and
	# --- meets the threshold. The bystander proves auto-target picks the
	# --- nearest: stand closer to one, it takes the hit.
	_label("C - OVERLOAD: SHOTS PING OFF THE SHIELD. OVERLOAD DOES NOT CARE.", Vector2(1900, 620))
	_label("15 INT-SCALED, IGNORES SHIELDS, INTERRUPTS HEAVIES. NEAREST TARGET TAKES IT.", Vector2(1900, 680))
	var shielded := _dummy("Shielded", Vector2(2300, FLOOR_TOP), 200, 5, 12)
	shielded.set("tags", Array([&"immune_ranged_frontal"], TYPE_STRING_NAME, "", null))
	shielded.set("facing", -1)
	_label("SHIELD FRONT", Vector2(2210, 1190))
	_dummy("Bystander", Vector2(2750, FLOOR_TOP), 200, 0, 9999)
	_label("BYSTANDER", Vector2(2680, 1190))

	# --- D. Breach. A machine that hurts to touch until it is stunned, and the
	# --- district's locked door with the maul behind it (items.md placement).
	# --- The terminal is free on purpose: a player arriving empty must never
	# --- be stuck at a gate.
	_label("D - BREACH: STUNS MACHINES FOR 1.5s. THE DOOR IS FREE - USE THE TERMINAL.", Vector2(3000, 620))
	_label("HUMANS SHRUG. MACHINES DROP. TAGS MEAN SOMETHING.", Vector2(3000, 680))
	var sentry := _dummy("Sentry", Vector2(3250, FLOOR_TOP), 200, 0, 9999)
	sentry.set("tags", Array([&"mechanical"], TYPE_STRING_NAME, "", null))
	sentry.set("hurts_on_contact", true)
	sentry.set("attack_power", 8.0)
	_label("MECHANICAL", Vector2(3170, 1190))
	_door("MaulDoor", "hack_gym_maul", 3640.0)
	_chest("breaker_maul", "MAUL", 3880.0)

	# --- E. The fight — the exit test. Three Scavs and a turret. The Scavs
	# --- want melee and ranged and do not answer Breach; the turret hurts on
	# --- contact and does. Overload is the panic button for whichever is
	# --- closest. Nothing here is solvable with one verb held down.
	_label("E - THE FIGHT: SCAVS IGNORE BREACH. THE TURRET DOES NOT.", Vector2(4200, 300))
	_label("USE ALL THREE. CLEAR THEM AND THEY COME BACK.", Vector2(4200, 360))
	var turret := _dummy("Turret", Vector2(4560, FLOOR_TOP), 30, 0, 9999)
	turret.set("tags", Array([&"mechanical"], TYPE_STRING_NAME, "", null))
	turret.set("hurts_on_contact", true)
	turret.set("attack_power", 8.0)
	turret.set("respawn_delay", 6.0)
	_encounter("ScavArena", [
		Vector2(4300, FLOOR_TOP),
		Vector2(4750, FLOOR_TOP),
		Vector2(4950, FLOOR_TOP),
	])

	_label("MELEE  J     RANGED  K     DASH  SHIFT", Vector2(300, 240))
	_label(
		"CAST  %s     CYCLE  %s / %s     LOADOUT  %s" % [
			InputPrompt.key(&"hack_cast").to_upper(),
			InputPrompt.key(&"hack_prev").to_upper(),
			InputPrompt.key(&"hack_next").to_upper(),
			InputPrompt.key(&"toggle_inventory").to_upper(),
		],
		Vector2(300, 300)
	)
	_label("RAM IS THE LIMITER. ONE SECOND BETWEEN CASTS IS THE RATE CAP.", Vector2(300, 360))

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
	if ResourceSaver.save(packed, "res://rooms/hack_gym.tscn") != OK:
		printerr("save failed")
		get_tree().quit(1)
		return
	print("wrote res://rooms/hack_gym.tscn")
	get_tree().quit(0)


## A program waiting to be downloaded. Same node as a chest with a different
## payload — hacks are programs, not items, and own themselves as flags.
func _program(hack_id: String, label_text: String, at_x: float) -> void:
	var scene := load("res://src/world/pickup.tscn") as PackedScene
	var pickup: Node = scene.instantiate()
	pickup.name = label_text.to_pascal_case()
	pickup.set("position", Vector2(at_x, FLOOR_TOP))
	pickup.set("kind", 1)  # Pickup.Kind.HACK
	pickup.set("hack_id", StringName(hack_id))
	pickup.set("pickup_id", StringName("hack_gym_%s" % hack_id))
	_pickups.add_child(pickup)
	_label(label_text, Vector2(at_x - 60.0, 1120.0))


func _chest(item_id: String, label_text: String, at_x: float) -> void:
	var scene := load("res://src/world/pickup.tscn") as PackedScene
	var pickup: Node = scene.instantiate()
	pickup.name = label_text.to_pascal_case()
	pickup.set("position", Vector2(at_x, FLOOR_TOP))
	pickup.set("item_id", StringName(item_id))
	pickup.set("pickup_id", StringName("hack_gym_%s" % item_id))
	_pickups.add_child(pickup)
	_label(label_text, Vector2(at_x - 60.0, 1120.0))


func _door(door_name: String, door_id: String, at_x: float) -> void:
	var scene := load("res://src/world/breach_door.tscn") as PackedScene
	var door: Node = scene.instantiate()
	door.name = door_name
	door.set("position", Vector2(at_x, FLOOR_TOP))
	door.set("door_id", StringName(door_id))
	door.set("size", Vector2(60.0, 300.0))
	_geometry.add_child(door)


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
