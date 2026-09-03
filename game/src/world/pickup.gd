class_name Pickup
extends Area2D
## An item waiting in the world — a chest, a crate, a dead worker's kit
## (docs/rpg/items.md, placement).
##
## Deliberately one node rather than a chest/floor-item pair: the ten items are
## placed by hand and what differs between a chest and a body is the art, which
## does not exist yet. When it does, this grows a sprite, not a subclass.
##
## Looting is permanent and lives in `GameState`, so a room re-entered after a
## save is a room whose chests stay open. That flag is the whole persistence
## story — the inventory already knows what it owns, and an item that somehow
## got granted twice is refused there anyway.

## What is inside. Ids are resolved through the catalog rather than the
## resource being referenced directly, so a room scene never pins a copy of an
## item's numbers.
@export var item_id: StringName = &""
## Unique across the district — it becomes a save flag. Room ids are permanent
## for the same reason (README conventions).
@export var pickup_id: StringName = &""
## px. Generous: a pickup you have to stand exactly on is a pickup players walk
## past.
@export var reach: float = 110.0

@onready var _visual: ColorRect = $Visual
@onready var _prompt: Label = $Prompt

var _item: Item
var _player_in_range: bool = false


func flag() -> StringName:
	return StringName("pickup.%s" % pickup_id)


func _ready() -> void:
	if pickup_id == &"":
		push_warning("Pickup '%s' has no pickup_id — looting it will not persist." % name)
	_item = Inventory.catalog.by_id(item_id) if Inventory.catalog != null else null
	if _item == null:
		push_error("Pickup '%s' holds no item ('%s')." % [name, item_id])
		queue_free()
		return

	# Already looted: never existed, as far as this visit is concerned.
	if pickup_id != &"" and GameState.has_flag(flag()):
		queue_free()
		return

	# The reach is a number, so the shape is built from it rather than authored
	# a second time in the scene and left free to disagree with it.
	var circle := CircleShape2D.new()
	circle.radius = reach
	var collider := CollisionShape2D.new()
	collider.shape = circle
	add_child(collider)

	_prompt.text = "%s\n[E] take" % _item.display_name
	_prompt.add_theme_font_size_override("font_size", 24)
	_prompt.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	# Polled rather than handled in `_input` so that a pickup and a door
	# overlapping the same button press cannot race: whoever the player is
	# standing in reads it, and there is never more than one.
	if _player_in_range and Input.is_action_just_pressed("interact"):
		take()


## Grants the item and closes the chest for good. Public so M5's quest reward
## can hand its item over without a player standing on anything.
func take() -> void:
	if _item == null:
		return
	Inventory.grant(_item.id)
	if pickup_id != &"":
		GameState.set_flag(flag())
	queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		_player_in_range = true
		_prompt.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		_player_in_range = false
		_prompt.visible = false
