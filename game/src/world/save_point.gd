class_name SavePoint
extends Area2D
## A VESTA care terminal (DESIGN.md §3.4; docs/narrative/hook.md).
##
## Save, full heal, full RAM, and the respawn point — on the creditor's own
## infrastructure, which is the fiction: you heal on their hardware and every
## save is a receipt. One terminal per room, so the terminal's id *is* the
## room's id and respawn is "travel to that room, stand at its terminal".

const COL_PANEL := Color(0.12, 0.16, 0.24)
const COL_BRAND := Color(0.35, 0.85, 1.0)

## The room this terminal stands in. Becomes `GameState.current_save_point`.
@export var save_point_id: StringName = &""
@export var reach: float = 120.0

var _prompt: Label
var _player_in_range: bool = false


func _ready() -> void:
	add_to_group(&"save_points")
	collision_layer = 128  # interactable
	collision_mask = 2  # player
	var circle := CircleShape2D.new()
	circle.radius = reach
	var collider := CollisionShape2D.new()
	collider.shape = circle
	collider.position = Vector2(0.0, -60.0)
	add_child(collider)

	var panel := ColorRect.new()
	panel.color = COL_PANEL
	panel.position = Vector2(-36.0, -132.0)
	panel.size = Vector2(72.0, 132.0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	var screen := ColorRect.new()
	screen.color = COL_BRAND
	screen.position = Vector2(-26.0, -118.0)
	screen.size = Vector2(52.0, 40.0)
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(screen)
	var brand := Label.new()
	brand.text = Lines.CORP
	brand.add_theme_font_size_override("font_size", 16)
	brand.add_theme_color_override("font_color", COL_PANEL)
	brand.position = Vector2(-26.0, -110.0)
	brand.size = Vector2(52.0, 24.0)
	brand.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	brand.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(brand)

	_prompt = Label.new()
	_prompt.text = "%s CARE TERMINAL\n%s SAVE" % [Lines.CORP, InputPrompt.label(&"interact")]
	_prompt.add_theme_font_size_override("font_size", 22)
	_prompt.add_theme_color_override("font_color", COL_BRAND)
	_prompt.position = Vector2(-160.0, -210.0)
	_prompt.size = Vector2(320.0, 60.0)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.visible = false
	_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_prompt)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if _player_in_range and Input.is_action_just_pressed("interact"):
		activate()


## Heal, refill, mark the respawn point, write the file.
func activate() -> void:
	var player: Node = get_tree().get_first_node_in_group(&"player")
	if player != null and player.has_method(&"restore_all"):
		player.call(&"restore_all")
	GameState.current_save_point = save_point_id
	var slot: int = GameState.active_slot
	if SaveLoad.save_to_slot(slot, GameState.snapshot()):
		Events.game_saved.emit(slot)
	Events.save_point_activated.emit(save_point_id)
	Events.toast_requested.emit("SAVED · %s CARE TERMINAL" % Lines.CORP)
	if not GameState.has_flag(&"bark.first_save"):
		GameState.set_flag(&"bark.first_save")
		Events.bark_requested.emit(Lines.BARK_FIRST_SAVE)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		_player_in_range = true
		_prompt.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		_player_in_range = false
		_prompt.visible = false
