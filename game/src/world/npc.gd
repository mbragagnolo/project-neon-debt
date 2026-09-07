class_name Npc
extends Area2D
## Someone to talk to (DESIGN.md §3.6; docs/narrative/hook.md).
##
## Two in the slice: Stitch, the ripperdoc who is also the vendor, and
## Marisol, the neighbour with the fetch quest. Talking is one button and a
## few pages; what happens after the pages — the shop opening, a quest
## turning over, an implant going in — is decided here by who this is and
## what the player is carrying. No tree, no choice of words.

const COL_STITCH := Color(0.55, 0.85, 0.55)
const COL_MARISOL := Color(0.85, 0.6, 0.85)
const COL_PROMPT := Color(0.6, 0.95, 1.0)

## The sheets' clip tables, as `tools/art/rig.py bake` prints them (frame
## size in screen px; name -> [first, count, fps, loops]). An NPC without an
## entry falls back to a two-frame idle sheet, the M7 shape. `talk` plays
## while the dialogue box is open.
const SHEETS := {
	&"stitch": {"frame": Vector2i(112, 120), "clips": {
		"idle": [0, 4, 2.0, true],
		"talk": [4, 2, 4.0, true],
	}},
	&"marisol": {"frame": Vector2i(80, 120), "clips": {
		"idle": [0, 4, 2.0, true],
		"talk": [4, 2, 3.0, true],
	}},
}

@export var npc_id: StringName = &""
@export var reach: float = 130.0

var display_name: String = ""
var _anim: PixelAnim
var _prompt: Label
var _player_in_range: bool = false
var _talking: bool = false


func _ready() -> void:
	add_to_group(&"npcs")
	collision_layer = 128
	collision_mask = 2
	var circle := CircleShape2D.new()
	circle.radius = reach
	var collider := CollisionShape2D.new()
	collider.shape = circle
	collider.position = Vector2(0.0, -44.0)
	add_child(collider)

	var colour: Color = COL_STITCH
	match npc_id:
		&"stitch":
			display_name = Lines.VENDOR
		&"marisol":
			display_name = Lines.NEIGHBOUR
			colour = COL_MARISOL
		_:
			display_name = String(npc_id).capitalize()

	var sheet: String = "res://assets/sprites/%s.png" % npc_id
	if ResourceLoader.exists(sheet):
		var body := PixelAnim.new()
		body.texture = load(sheet)
		if SHEETS.has(npc_id) and _sheet_fits(SHEETS[npc_id], body.texture):
			var table: Dictionary = SHEETS[npc_id]
			body.frame_width = (table["frame"] as Vector2i).x
			body.frame_height = (table["frame"] as Vector2i).y
			body.clips = table["clips"]
		else:
			body.frame_width = body.texture.get_width() / 2
			body.frame_height = body.texture.get_height()
			body.clips = {"idle": [0, 2, 1.5, true]}
		body.position = Vector2(0.0, -body.frame_height * 0.5)
		add_child(body)
		_anim = body
	else:
		var body := ColorRect.new()
		body.color = colour
		body.position = Vector2(-22.0, -84.0)
		body.size = Vector2(44.0, 84.0)
		body.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(body)

	var tag := Label.new()
	tag.text = display_name.to_upper()
	tag.add_theme_font_size_override("font_size", 18)
	tag.add_theme_color_override("font_color", colour)
	tag.position = Vector2(-80.0, -140.0)
	tag.size = Vector2(160.0, 24.0)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tag)

	_prompt = Label.new()
	_prompt.text = "%s TALK" % InputPrompt.label(&"interact")
	_prompt.add_theme_font_size_override("font_size", 22)
	_prompt.add_theme_color_override("font_color", COL_PROMPT)
	_prompt.position = Vector2(-80.0, -172.0)
	_prompt.size = Vector2(160.0, 30.0)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.visible = false
	_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_prompt)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


## A table only applies to a sheet that has its frames: an older sheet on
## disk (the M7 two-frame idle) keeps the fallback instead of indexing past
## its end.
static func _sheet_fits(table: Dictionary, texture: Texture2D) -> bool:
	var frame: Vector2i = table["frame"]
	var needed: int = 0
	for row: Array in (table["clips"] as Dictionary).values():
		needed = maxi(needed, int(row[0]) + int(row[1]))
	return texture.get_height() >= frame.y and texture.get_width() >= frame.x * needed


func _process(_delta: float) -> void:
	if _player_in_range and not _talking and Input.is_action_just_pressed("interact"):
		talk()


func _box() -> DialogueBox:
	return get_tree().get_first_node_in_group(&"dialogue_box") as DialogueBox


func _shop() -> Node:
	return get_tree().get_first_node_in_group(&"shop")


## What this NPC says now, and what follows. Public so a test can talk
## without standing anywhere.
func talk() -> void:
	var box: DialogueBox = _box()
	match npc_id:
		&"stitch":
			await _talk_stitch(box)
		&"marisol":
			await _talk_marisol(box)
		_:
			await _say(box, [ "..." ])


func _say(box: DialogueBox, pages: Array[String]) -> void:
	if box == null:
		return
	_talking = true
	if _anim != null:
		_anim.play(&"talk")
	box.open(display_name, pages)
	await box.finished
	_talking = false
	if _anim != null:
		_anim.play(&"idle")


# --- Stitch: ripperdoc and vendor ------------------------------------------

func _talk_stitch(box: DialogueBox) -> void:
	var carried: bool = GameState.has_flag(GameState.SIDEWINDER_CARRIED)
	var installed: bool = GameState.has_ability(GameState.ABILITY_SIDEWINDER)
	if carried and not installed:
		await _say(box, Lines.STITCH_INSTALL)
		GameState.grant_ability(GameState.ABILITY_SIDEWINDER)
		Events.toast_requested.emit("SIDEWINDER INSTALLED — AIR DASH")
		Events.bark_requested.emit(Lines.BARK_SIDEWINDER_INSTALLED)
		return
	if installed and not GameState.has_flag(&"bark.stitch_after_install"):
		GameState.set_flag(&"bark.stitch_after_install")
		await _say(box, Lines.STITCH_AFTER_INSTALL)
	elif not GameState.has_flag(&"bark.stitch_met"):
		GameState.set_flag(&"bark.stitch_met")
		await _say(box, Lines.STITCH_GREET)
	var shop: Node = _shop()
	if shop != null and shop.has_method(&"open"):
		shop.call(&"open")


# --- Marisol: the neighbour, the quest ---------------------------------------

func _talk_marisol(box: DialogueBox) -> void:
	var quest_id: StringName = Quests.MEMORY_CHIP
	match Quests.state(quest_id):
		Quests.State.UNKNOWN:
			await _say(box, Lines.MARISOL_OFFER)
			Quests.start(quest_id)
		Quests.State.ACTIVE:
			if Quests.can_complete(quest_id):
				await _say(box, Lines.MARISOL_COMPLETE)
				Quests.complete(quest_id)
				Events.bark_requested.emit(Lines.BARK_QUEST_DONE)
			else:
				await _say(box, Lines.MARISOL_ACTIVE)
		Quests.State.COMPLETE:
			await _say(box, Lines.MARISOL_AFTER)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		_player_in_range = true
		_prompt.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		_player_in_range = false
		_prompt.visible = false
