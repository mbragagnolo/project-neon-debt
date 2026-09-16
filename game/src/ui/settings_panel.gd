class_name SettingsPanel
extends Control
## The settings rows (M7; docs/ui/screens.md), shared by the title screen
## and the pause shell's SYSTEM tab: fullscreen, three volumes, screen shake,
## and a controls page that reads the input map rather than repeating it.
##
## Navigation is the game's own actions (up, down, left, right, interact,
## pause) plus the ui_* defaults, so it works on the pad and the keyboard
## without a mouse. `handle_input` returns true when the event was used.
## A host can append rows of its own (the shell adds QUIT TO TITLE) and hear
## them through `action`.

signal closed
signal action(id: StringName)

const COL_TEXT := UiPalette.TEXT
const COL_DIM := UiPalette.DIM
const COL_ACTIVE := UiPalette.ACCENT
const COL_WARN := UiPalette.WARN

const VOLUME_STEP := 0.1

## Rows in order: [id, label]. Extra rows are appended by the host.
const BASE_ROWS: Array = [
	[&"fullscreen", "FULLSCREEN"],
	[&"master", "MASTER VOLUME"],
	[&"music", "MUSIC VOLUME"],
	[&"sfx", "SFX VOLUME"],
	[&"shake", "SCREEN SHAKE"],
	[&"controls", "CONTROLS"],
]

## What the controls page lists: [caption, action or actions].
const CONTROL_ROWS: Array = [
	["MOVE", [&"move_left", &"move_right"]],
	["CLIMB / DROP", [&"move_up", &"move_down"]],
	["JUMP", [&"jump"]],
	["DASH", [&"dash"]],
	["MELEE", [&"attack_melee"]],
	["RANGED", [&"attack_ranged"]],
	["CAST HACK", [&"hack_cast"]],
	["CYCLE HACK", [&"hack_prev", &"hack_next"]],
	["INTERACT", [&"interact"]],
	["MAP", [&"toggle_map"]],
	["LOADOUT", [&"toggle_inventory"]],
	["PAUSE", [&"pause"]],
]

var extra_rows: Array = []
var rows: Array = []
## Where the first row sits, from the top of the screen.
var top_offset: float = 440.0

var _index: int = 0
var _controls_open: bool = false
var _pending: StringName = &""
var _list: VBoxContainer
var _controls: VBoxContainer
var _hint: Label
var _labels: Array[Label] = []
var _values: Array[Label] = []


func _ready() -> void:
	rows = BASE_ROWS.duplicate()
	for row: Variant in extra_rows:
		rows.append(row)
	_build()
	redraw()


func open() -> void:
	_index = 0
	_controls_open = false
	_pending = &""
	visible = true
	redraw()


func close() -> void:
	visible = false
	_controls_open = false


func selected_id() -> StringName:
	return rows[_index][0]


## True when the event was consumed.
func handle_input(event: InputEvent) -> bool:
	if not event.is_pressed() or event.is_echo():
		return false
	if _controls_open:
		if _is(event, [&"pause", &"ui_cancel", &"interact", &"jump", &"ui_accept"]):
			_controls_open = false
			Sfx.play(&"ui_back")
			redraw()
			return true
		return false
	if _is(event, [&"move_down", &"ui_down"]):
		_index = wrapi(_index + 1, 0, rows.size())
		_pending = &""
		Sfx.play(&"ui_move")
		redraw()
		return true
	if _is(event, [&"move_up", &"ui_up"]):
		_index = wrapi(_index - 1, 0, rows.size())
		_pending = &""
		Sfx.play(&"ui_move")
		redraw()
		return true
	if _is(event, [&"move_left", &"ui_left"]):
		return _adjust(-1)
	if _is(event, [&"move_right", &"ui_right"]):
		return _adjust(1)
	if _is(event, [&"interact", &"jump", &"ui_accept"]):
		return _activate()
	if _is(event, [&"pause", &"ui_cancel"]):
		Sfx.play(&"ui_back")
		closed.emit()
		return true
	return false


func _is(event: InputEvent, actions: Array) -> bool:
	for name: StringName in actions:
		if InputMap.has_action(name) and event.is_action(name):
			return true
	return false


func _adjust(step: int) -> bool:
	var id: StringName = selected_id()
	match id:
		&"master", &"music", &"sfx":
			var bus: StringName = {&"master": &"Master", &"music": &"Music", &"sfx": &"SFX"}[id]
			Settings.set_volume(bus, Settings.volume(bus) + step * VOLUME_STEP)
			Sfx.play(&"ui_move")
		&"fullscreen":
			Settings.set_fullscreen(not Settings.fullscreen)
			Sfx.play(&"ui_confirm")
		&"shake":
			Settings.set_screen_shake(not Settings.screen_shake)
			Sfx.play(&"ui_confirm")
		_:
			return false
	redraw()
	return true


func _activate() -> bool:
	var id: StringName = selected_id()
	match id:
		&"fullscreen", &"shake":
			return _adjust(1)
		&"master", &"music", &"sfx":
			return _adjust(1)
		&"controls":
			_controls_open = true
			Sfx.play(&"ui_confirm")
			redraw()
			return true
		_:
			# A host row. Dangerous ones ask twice.
			if _pending != id:
				_pending = id
				Sfx.play(&"ui_move")
				redraw()
				return true
			_pending = &""
			Sfx.play(&"ui_confirm")
			action.emit(id)
			return true


# --- Drawing ----------------------------------------------------------------------------------

func redraw() -> void:
	_list.visible = not _controls_open
	_controls.visible = _controls_open
	if _controls_open:
		_draw_controls()
		_hint.text = "%s back" % InputPrompt.label(&"pause")
		return
	for index: int in rows.size():
		var id: StringName = rows[index][0]
		var selected: bool = index == _index
		_labels[index].add_theme_color_override("font_color", COL_ACTIVE if selected else COL_TEXT)
		_labels[index].text = ("> " if selected else "  ") + String(rows[index][1])
		var value: String = _value_text(id)
		if _pending == id:
			value = "PRESS AGAIN"
		_values[index].text = value
		_values[index].add_theme_color_override("font_color", COL_WARN if _pending == id else (COL_ACTIVE if selected else COL_DIM))
	_hint.text = "%s/%s change   %s select   %s back" % [
		InputPrompt.label(&"move_left"), InputPrompt.label(&"move_right"),
		InputPrompt.label(&"interact"), InputPrompt.label(&"pause"),
	]


func _value_text(id: StringName) -> String:
	match id:
		&"fullscreen": return "ON" if Settings.fullscreen else "OFF"
		&"shake": return "ON" if Settings.screen_shake else "OFF"
		&"master": return _bar(Settings.master_volume)
		&"music": return _bar(Settings.music_volume)
		&"sfx": return _bar(Settings.sfx_volume)
		&"controls": return ">"
	return ""


func _bar(value: float) -> String:
	var filled: int = roundi(clampf(value, 0.0, 1.0) * 10.0)
	return "%s%s %3d%%" % ["█".repeat(filled), "░".repeat(10 - filled), roundi(value * 100.0)]


func _draw_controls() -> void:
	for child: Node in _controls.get_children():
		_controls.remove_child(child)
		child.queue_free()
	var header := _row(_controls, "ACTION", "KEYBOARD", "PAD", COL_DIM, 20)
	header.add_theme_constant_override("separation", 20)
	for entry: Array in CONTROL_ROWS:
		var keys: Array[String] = []
		var pads: Array[String] = []
		for name: StringName in entry[1]:
			keys.append(InputPrompt.key(name).to_upper())
			pads.append(InputPrompt.pad(name))
		_row(_controls, String(entry[0]), " / ".join(keys), " / ".join(pads), COL_TEXT, 24)


func _row(parent: Node, a: String, b: String, c: String, colour: Color, size: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(row)
	for pair: Array in [[a, 260.0], [b, 300.0], [c, 300.0]]:
		var label := Label.new()
		label.text = pair[0]
		label.custom_minimum_size.x = pair[1]
		label.add_theme_font_size_override("font_size", size)
		label.add_theme_color_override("font_color", colour)
		row.add_child(label)
	return row


func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# A column hung from the top centre, `top_offset` down, so the host
	# decides what it sits under: the title, or the shell's tab bar.
	var column := VBoxContainer.new()
	column.anchor_left = 0.5
	column.anchor_right = 0.5
	column.anchor_top = 0.0
	column.anchor_bottom = 0.0
	column.offset_left = -480.0
	column.offset_right = 480.0
	column.offset_top = top_offset
	column.grow_horizontal = Control.GROW_DIRECTION_BOTH
	column.grow_vertical = Control.GROW_DIRECTION_END
	column.add_theme_constant_override("separation", 10)
	column.alignment = BoxContainer.ALIGNMENT_BEGIN
	add_child(column)

	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 8)
	column.add_child(_list)
	for row: Array in rows:
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 30)
		line.alignment = BoxContainer.ALIGNMENT_CENTER
		_list.add_child(line)
		var label := Label.new()
		label.custom_minimum_size.x = 360.0
		label.add_theme_font_size_override("font_size", 28)
		line.add_child(label)
		var value := Label.new()
		value.custom_minimum_size.x = 300.0
		value.add_theme_font_size_override("font_size", 28)
		line.add_child(value)
		_labels.append(label)
		_values.append(value)

	_controls = VBoxContainer.new()
	_controls.add_theme_constant_override("separation", 4)
	_controls.visible = false
	column.add_child(_controls)

	_hint = Label.new()
	_hint.add_theme_font_size_override("font_size", 20)
	_hint.add_theme_color_override("font_color", COL_DIM)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_hint)
