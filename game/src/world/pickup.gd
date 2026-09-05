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

## What kind of thing is waiting here. Items go to the inventory; programs
## (M4) are hacks, which live outside the ten-item budget and are owned as
## `GameState` flags. One node for both, because what differs is the art.
enum Kind { ITEM, HACK }

@export var kind: Kind = Kind.ITEM
## What is inside, for `ITEM`. Ids are resolved through the catalog rather
## than the resource being referenced directly, so a room scene never pins a
## copy of an item's numbers.
@export var item_id: StringName = &""
## What is inside, for `HACK`.
@export var hack_id: StringName = &""
## Unique across the district — it becomes a save flag. Room ids are permanent
## for the same reason (README conventions).
@export var pickup_id: StringName = &""
## px. Generous: a pickup you have to stand exactly on is a pickup players walk
## past.
@export var reach: float = 110.0

@onready var _visual: ColorRect = $Visual
@onready var _prompt: Label = $Prompt

var _item: Item
var _hack: Hack
var _player_in_range: bool = false


func flag() -> StringName:
	return StringName("pickup.%s" % pickup_id)


func _ready() -> void:
	if pickup_id == &"":
		push_warning("Pickup '%s' has no pickup_id — looting it will not persist." % name)
	match kind:
		Kind.ITEM:
			_item = Inventory.catalog.by_id(item_id) if Inventory.catalog != null else null
			if _item == null:
				push_error("Pickup '%s' holds no item ('%s')." % [name, item_id])
				queue_free()
				return
		Kind.HACK:
			_hack = HackKit.hack_by_id(hack_id)
			if _hack == null:
				push_error("Pickup '%s' holds no program ('%s')." % [name, hack_id])
				queue_free()
				return
			# A program already owned has nothing left to hand over.
			if HackKit.is_owned(_hack):
				queue_free()
				return
			_visual.color = _hack.color

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

	_prompt.text = "%s\n%s %s" % [
		display_name(), InputPrompt.label(&"interact"), "download" if kind == Kind.HACK else "take"
	]
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


func display_name() -> String:
	if kind == Kind.HACK:
		return "PROGRAM: %s" % (_hack.display_name.to_upper() if _hack != null else "?")
	return _item.display_name if _item != null else "?"


## Grants the contents and closes the chest for good. Public so M5's quest
## reward can hand its item over without a player standing on anything.
func take() -> void:
	match kind:
		Kind.ITEM:
			if _item == null:
				return
			Inventory.grant(_item.id)
		Kind.HACK:
			if _hack == null:
				return
			HackKit.grant(_hack.id)
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
