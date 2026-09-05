class_name Grate
extends StaticBody2D
## A one-way shortcut: a maintenance grate that only opens from the inside
## (DESIGN.md §3.4 — "one stat-check-free environmental shortcut loop").
##
## Solid from both sides until the player reaches it from `open_side` and
## pulls the release. Opening is permanent (`door.<id>`), and from then on it
## is a hole in the wall in both directions — the loop back to the hub.

const COL_GRATE := Color(0.32, 0.38, 0.48)
const COL_PROMPT := Color(0.55, 1.0, 0.5)

## Unique across the district — it becomes a save flag.
@export var grate_id: StringName = &""
@export var size: Vector2 = Vector2(60.0, 180.0)
## +1: the release is on the right of the slab, -1: on the left.
@export var open_side: int = 1
@export var reach: float = 110.0

var _slab: ColorRect
var _collider: CollisionShape2D
var _prompt: Label
var _open: bool = false
var _player_in_range: bool = false


func flag() -> StringName:
	return StringName("door.%s" % grate_id)


func is_open() -> bool:
	return _open


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var rect := RectangleShape2D.new()
	rect.size = size
	_collider = CollisionShape2D.new()
	_collider.shape = rect
	_collider.position = Vector2(0.0, -size.y * 0.5)
	add_child(_collider)

	_slab = ColorRect.new()
	_slab.color = COL_GRATE
	_slab.position = Vector2(-size.x * 0.5, -size.y)
	_slab.size = size
	_slab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_slab)

	var zone := Area2D.new()
	zone.collision_layer = 128
	zone.collision_mask = 2
	var circle := CircleShape2D.new()
	circle.radius = reach
	var zone_shape := CollisionShape2D.new()
	zone_shape.shape = circle
	zone_shape.position = Vector2(float(open_side) * (size.x * 0.5 + reach * 0.6), -size.y * 0.5)
	zone.add_child(zone_shape)
	zone.body_entered.connect(_on_body_entered)
	zone.body_exited.connect(_on_body_exited)
	add_child(zone)

	_prompt = Label.new()
	_prompt.text = "%s RELEASE GRATE" % InputPrompt.label(&"interact")
	_prompt.add_theme_font_size_override("font_size", 22)
	_prompt.add_theme_color_override("font_color", COL_PROMPT)
	_prompt.position = Vector2(-150.0, -size.y - 50.0)
	_prompt.size = Vector2(300.0, 30.0)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.visible = false
	_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_prompt)

	if grate_id != &"" and GameState.has_flag(flag()):
		_set_open(false)


func _process(_delta: float) -> void:
	if _player_in_range and not _open and Input.is_action_just_pressed("interact"):
		open()


func open() -> bool:
	if _open:
		return false
	if grate_id != &"":
		GameState.set_flag(flag())
	Events.door_opened.emit(grate_id)
	Events.toast_requested.emit("SHORTCUT OPENED")
	_set_open(true)
	return true


func _set_open(animated: bool) -> void:
	_open = true
	_prompt.visible = false
	_collider.set_deferred("disabled", true)
	if animated:
		var tween := create_tween()
		tween.tween_property(_slab, "position:y", _slab.position.y - size.y, 0.3) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(_slab, "modulate:a", 0.2, 0.3)
	else:
		_slab.position.y -= size.y
		_slab.modulate.a = 0.2


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player") and not _open:
		_player_in_range = true
		_prompt.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		_player_in_range = false
		_prompt.visible = false
