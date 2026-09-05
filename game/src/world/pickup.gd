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
## (M4) are hacks, owned as `GameState` flags; abilities (M5) are gadgets and
## implants, also flags; stat-ups bump the sheet; a quest item is a flag the
## tracker reads. One node for all of them, because what differs is the art.
enum Kind { ITEM, HACK, ABILITY, HP_UP, RAM_UP, QUEST_ITEM }

const COL_ITEM := Color(0.98, 0.78, 0.25)
const COL_ABILITY := Color(0.35, 0.85, 1.0)
const COL_HP := Color(1.0, 0.45, 0.45)
const COL_RAM := Color(0.75, 0.6, 1.0)
const COL_QUEST := Color(0.95, 0.95, 0.95)

@export var kind: Kind = Kind.ITEM
## What is inside, for `ITEM`. Ids are resolved through the catalog rather
## than the resource being referenced directly, so a room scene never pins a
## copy of an item's numbers.
@export var item_id: StringName = &""
## What is inside, for `HACK`.
@export var hack_id: StringName = &""
## The flag granted, for `ABILITY`: `ability.mag_hook`, `ability.cyberdeck`,
## or `item.sidewinder_carried` (implants are surgery; the ripperdoc
## installs it).
@export var ability_id: StringName = &""
## The flag set, for `QUEST_ITEM`: `quest_item.<id>`.
@export var quest_item_id: StringName = &""
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
		Kind.ABILITY:
			if ability_id == &"" or GameState.has_flag(ability_id):
				queue_free()
				return
			_visual.color = COL_ABILITY
		Kind.HP_UP:
			_visual.color = COL_HP
		Kind.RAM_UP:
			_visual.color = COL_RAM
		Kind.QUEST_ITEM:
			if quest_item_id == &"" or GameState.has_flag(quest_flag()):
				queue_free()
				return
			_visual.color = COL_QUEST

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


func quest_flag() -> StringName:
	return StringName("quest_item.%s" % quest_item_id)


func display_name() -> String:
	match kind:
		Kind.HACK:
			return "PROGRAM: %s" % (_hack.display_name.to_upper() if _hack != null else "?")
		Kind.ABILITY:
			return ability_name(ability_id)
		Kind.HP_UP:
			return "%s DERMAL WEAVE — MAX HP UP" % Lines.CORP
		Kind.RAM_UP:
			return "%s MEMORY MODULE — MAX RAM UP" % Lines.CORP
		Kind.QUEST_ITEM:
			return String(quest_item_id).replace("_", " ").to_upper()
	return _item.display_name if _item != null else "?"


static func ability_name(flag: StringName) -> String:
	match flag:
		GameState.ABILITY_MAG_HOOK: return "MAG-HOOK"
		GameState.ABILITY_CYBERDECK: return "CYBERDECK"
		GameState.SIDEWINDER_CARRIED: return "SIDEWINDER IMPLANT (SEALED)"
	return String(flag).to_upper()


## Grants the contents and closes the chest for good. Public so M5's quest
## reward can hand its item over without a player standing on anything.
func take() -> void:
	var curve: StatCurve = PlayerStats.stat_curve
	match kind:
		Kind.ITEM:
			if _item == null:
				return
			Inventory.grant(_item.id)
		Kind.HACK:
			if _hack == null:
				return
			HackKit.grant(_hack.id)
			match _hack.id:
				&"overload": Events.bark_requested.emit(Lines.BARK_OVERLOAD)
				&"breach": Events.bark_requested.emit(Lines.BARK_BREACH)
		Kind.ABILITY:
			_grant_ability()
		Kind.HP_UP:
			PlayerStats.add_max_hp(curve.hp_up_amount if curve != null else 5)
			Events.toast_requested.emit("MAX HP UP")
		Kind.RAM_UP:
			PlayerStats.add_max_ram(curve.ram_up_amount if curve != null else 3)
			Events.toast_requested.emit("MAX RAM UP")
		Kind.QUEST_ITEM:
			GameState.set_flag(quest_flag())
			Events.quest_item_acquired.emit(quest_item_id)
			Events.toast_requested.emit("Picked up %s" % display_name())
			if quest_item_id == &"memory_chip":
				Events.bark_requested.emit(Lines.BARK_CHIP)
	if pickup_id != &"":
		GameState.set_flag(flag())
	queue_free()


## Gadgets are carried and work at once; the implant is carried *sealed*
## and works after surgery (DESIGN.md §2).
func _grant_ability() -> void:
	match ability_id:
		GameState.ABILITY_MAG_HOOK:
			GameState.grant_ability(ability_id)
			Events.toast_requested.emit("MAG-HOOK — WALL JUMP")
			Events.bark_requested.emit(Lines.BARK_MAG_HOOK)
		GameState.ABILITY_CYBERDECK:
			GameState.grant_ability(ability_id)
			Events.toast_requested.emit("CYBERDECK — MORE RAM, QUICKSLOT UNLOCKED")
			Events.bark_requested.emit(Lines.BARK_CYBERDECK)
		GameState.SIDEWINDER_CARRIED:
			GameState.set_flag(ability_id)
			Events.toast_requested.emit("SIDEWINDER IMPLANT — TAKE IT TO %s" % Lines.VENDOR.to_upper())
			Events.bark_requested.emit(Lines.BARK_SIDEWINDER)
		_:
			GameState.grant_ability(ability_id)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		_player_in_range = true
		_prompt.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		_player_in_range = false
		_prompt.visible = false
