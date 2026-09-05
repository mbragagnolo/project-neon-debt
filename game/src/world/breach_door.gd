class_name BreachDoor
extends StaticBody2D
## A sealed door with a terminal — the Breach gate (docs/combat/hacks.md,
## rule 2; DESIGN.md §3.4 gating grammar).
##
## Two ways through, one rule: **the door checks that you own the program,
## never the meter.** The terminal interaction opens it for 0 RAM, so a player
## arriving on an empty pool is never softlocked at a gate. A Breach *cast*
## in reach opens it too — that costs the cast like any combat use, and exists
## so that pulsing next to a door does the obvious thing.
##
## Opening is permanent and lives in `GameState` (`door.<id>`), so a door
## re-entered after a save stays open. Room ids and pickup ids are permanent
## for the same reason.

const GROUP := &"breach_doors"
const COL_SEALED := Color(0.62, 0.2, 0.3)
const COL_TERMINAL := Color(0.55, 1.0, 0.5)
const COL_LOCKED := Color(1.0, 0.45, 0.45)

## Unique across the district — it becomes a save flag.
@export var door_id: StringName = &""
## The slab, px. Built from a number rather than authored twice in the scene.
@export var size: Vector2 = Vector2(60.0, 240.0)
## px the terminal can be used from.
@export var reach: float = 140.0

@onready var _slab: ColorRect = $Slab
@onready var _collider: CollisionShape2D = $CollisionShape2D
@onready var _terminal: Area2D = $Terminal
@onready var _prompt: Label = $Prompt

var _open: bool = false
var _player_in_range: bool = false


func flag() -> StringName:
	return StringName("door.%s" % door_id)


func is_open() -> bool:
	return _open


func _ready() -> void:
	if door_id == &"":
		push_warning("BreachDoor '%s' has no door_id — opening it will not persist." % name)
	add_to_group(GROUP)
	collision_layer = 1
	collision_mask = 0

	var rect := RectangleShape2D.new()
	rect.size = size
	_collider.shape = rect
	_collider.position = Vector2(0.0, -size.y * 0.5)
	_slab.color = COL_SEALED
	_slab.position = Vector2(-size.x * 0.5, -size.y)
	_slab.size = size

	var circle := CircleShape2D.new()
	circle.radius = reach
	var zone := CollisionShape2D.new()
	zone.shape = circle
	zone.position = Vector2(0.0, -size.y * 0.5)
	_terminal.add_child(zone)
	_terminal.body_entered.connect(_on_body_entered)
	_terminal.body_exited.connect(_on_body_exited)

	_prompt.visible = false
	_prompt.add_theme_font_size_override("font_size", 24)

	if door_id != &"" and GameState.has_flag(flag()):
		_set_open(false)


func _process(_delta: float) -> void:
	if _player_in_range and not _open and Input.is_action_just_pressed("interact"):
		interact()


## The terminal. Free if the program is owned; a locked message if not.
func interact() -> void:
	if _open:
		return
	if HackKit.is_owned_id(&"breach"):
		breach()
	else:
		_prompt.text = "SEALED\nBREACH REQUIRED"
		_prompt.add_theme_color_override("font_color", COL_LOCKED)


## Opens the door. Called by the terminal and by a Breach pulse in reach.
## Returns false if it was already open.
func breach() -> bool:
	if _open:
		return false
	if door_id != &"":
		GameState.set_flag(flag())
	Events.door_opened.emit(door_id)
	_set_open(true)
	return true


func _set_open(animated: bool) -> void:
	_open = true
	_prompt.visible = false
	_collider.set_deferred("disabled", true)
	if animated:
		var tween := create_tween()
		tween.tween_property(_slab, "position:y", _slab.position.y - size.y, 0.35) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(_slab, "modulate:a", 0.15, 0.35)
	else:
		_slab.position.y -= size.y
		_slab.modulate.a = 0.15


func _refresh_prompt() -> void:
	if HackKit.is_owned_id(&"breach"):
		_prompt.text = "%s BREACH" % InputPrompt.label(&"interact")
		_prompt.add_theme_color_override("font_color", COL_TERMINAL)
	else:
		_prompt.text = "SEALED TERMINAL"
		_prompt.add_theme_color_override("font_color", COL_LOCKED)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player") and not _open:
		_player_in_range = true
		_refresh_prompt()
		_prompt.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		_player_in_range = false
		_prompt.visible = false
