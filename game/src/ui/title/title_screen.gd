class_name TitleScreen
extends Control
## The title screen (M7; docs/ui/screens.md): the district's skyline in the
## rain, the name in neon, and four lines — CONTINUE, NEW RUN, SETTINGS,
## QUIT. Three save slots behind the first two.
##
## It is the main scene. Picking a slot sets `GameState.active_slot`, loads
## or resets the state, and hands over to the world, which reads
## `GameState.current_save_point` to know where to wake up.

enum Page { MAIN, SLOTS, SETTINGS }

const WORLD_SCENE := "res://rooms/world.tscn"
const GRAPH_PATH := "res://src/world/world_graph.tres"

const COL_NEON := Color(0.13, 0.9, 1.0)
const COL_NEON_GLOW := Color(1.0, 0.18, 0.58)
const COL_TEXT := Color(0.78, 0.86, 0.95)
const COL_DIM := Color(0.45, 0.52, 0.64)
const COL_ACTIVE := Color(0.6, 0.95, 1.0)
const COL_WARN := Color(1.0, 0.45, 0.45)
const COL_NOTICE := Color(1.0, 0.36, 0.36)

var page: Page = Page.MAIN
var menu_index: int = 0
var slot_index: int = 0
var fresh_run: bool = false

var _entries: Array = []
var _menu_labels: Array[Label] = []
var _slot_cards: Array[PanelContainer] = []
var _slot_titles: Array[Label] = []
var _slot_bodies: Array[Label] = []
var _confirm_slot: int = -1
var _busy: bool = false
var _graph: WorldGraph

var _menu: VBoxContainer
var _slots: VBoxContainer
var _slots_caption: Label
var _settings: SettingsPanel
var _title: Label
var _glows: Array[Label] = []
var _hint: Label
var _fade: ColorRect
var _near: TextureRect
var _flicker: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if ResourceLoader.exists(GRAPH_PATH):
		_graph = load(GRAPH_PATH)
	_build()
	_show_main()
	Music.play(&"title", 2.5)
	_fade.modulate.a = 1.0
	create_tween().tween_property(_fade, "modulate:a", 0.0, 1.0)


func _process(delta: float) -> void:
	# The near skyline drifts, the sign flickers.
	if _near != null:
		_near.position.x -= 6.0 * delta
		if _near.position.x <= -960.0:
			_near.position.x += 960.0
	_flicker -= delta
	if _flicker <= 0.0:
		_flicker = randf_range(1.5, 5.0)
		var tween := create_tween()
		tween.tween_property(_title, "modulate:a", 0.55, 0.05)
		tween.tween_property(_title, "modulate:a", 1.0, 0.08)
		tween.tween_property(_title, "modulate:a", 0.8, 0.04)
		tween.tween_property(_title, "modulate:a", 1.0, 0.1)
	for glow: Label in _glows:
		glow.modulate.a = 0.22 + 0.06 * sin(Time.get_ticks_msec() / 400.0)


# --- Input ----------------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if _busy or not event.is_pressed() or event.is_echo():
		return
	var used: bool = false
	match page:
		Page.MAIN: used = _main_input(event)
		Page.SLOTS: used = _slots_input(event)
		Page.SETTINGS: used = _settings.handle_input(event)
	if used:
		get_viewport().set_input_as_handled()


func _is(event: InputEvent, actions: Array) -> bool:
	for name: StringName in actions:
		if InputMap.has_action(name) and event.is_action(name):
			return true
	return false


func _main_input(event: InputEvent) -> bool:
	if _is(event, [&"move_down", &"ui_down"]):
		menu_index = wrapi(menu_index + 1, 0, _entries.size())
		Sfx.play(&"ui_move")
		_redraw_menu()
		return true
	if _is(event, [&"move_up", &"ui_up"]):
		menu_index = wrapi(menu_index - 1, 0, _entries.size())
		Sfx.play(&"ui_move")
		_redraw_menu()
		return true
	if _is(event, [&"interact", &"jump", &"ui_accept"]):
		activate(_entries[menu_index])
		return true
	return false


func _slots_input(event: InputEvent) -> bool:
	if _is(event, [&"move_down", &"ui_down"]):
		slot_index = wrapi(slot_index + 1, 0, SaveLoad.SLOT_COUNT)
		_confirm_slot = -1
		Sfx.play(&"ui_move")
		_redraw_slots()
		return true
	if _is(event, [&"move_up", &"ui_up"]):
		slot_index = wrapi(slot_index - 1, 0, SaveLoad.SLOT_COUNT)
		_confirm_slot = -1
		Sfx.play(&"ui_move")
		_redraw_slots()
		return true
	if _is(event, [&"interact", &"jump", &"ui_accept"]):
		pick_slot(slot_index)
		return true
	if _is(event, [&"pause", &"ui_cancel"]):
		Sfx.play(&"ui_back")
		_show_main()
		return true
	return false


# --- Choices ------------------------------------------------------------------------------

func activate(id: StringName) -> void:
	match id:
		&"continue":
			fresh_run = false
			slot_index = _first_saved_slot()
			Sfx.play(&"ui_confirm")
			_show_slots()
		&"new_run":
			fresh_run = true
			slot_index = _first_empty_slot()
			Sfx.play(&"ui_confirm")
			_show_slots()
		&"settings":
			Sfx.play(&"ui_confirm")
			page = Page.SETTINGS
			_menu.visible = false
			_slots.visible = false
			_settings.open()
			_hint.text = ""
		&"quit":
			Sfx.play(&"ui_back")
			get_tree().quit()


## A slot chosen. A new run over a save asks twice.
func pick_slot(slot: int) -> void:
	var occupied: bool = SaveLoad.has_save(slot)
	if not fresh_run:
		if not occupied:
			Sfx.play(&"deny")
			return
		start(slot, false)
		return
	if occupied and _confirm_slot != slot:
		_confirm_slot = slot
		Sfx.play(&"ui_move")
		_redraw_slots()
		return
	start(slot, true)


## Hand over to the world. `fresh` wipes the slot; otherwise it loads.
func start(slot: int, fresh: bool) -> void:
	if _busy:
		return
	_busy = true
	GameState.active_slot = slot
	if fresh:
		SaveLoad.delete_slot(slot)
		GameState.reset()
	else:
		GameState.restore(SaveLoad.load_from_slot(slot))
	Sfx.play(&"title_start")
	Music.stop(0.9)
	var tween := create_tween()
	tween.tween_property(_fade, "modulate:a", 1.0, 0.8)
	await tween.finished
	if get_tree().current_scene == self:
		get_tree().change_scene_to_file(WORLD_SCENE)
	else:
		# Under a test the scene stays; the state is what matters.
		_busy = false


func _first_saved_slot() -> int:
	for slot: int in SaveLoad.SLOT_COUNT:
		if SaveLoad.has_save(slot):
			return slot
	return 0


func _first_empty_slot() -> int:
	for slot: int in SaveLoad.SLOT_COUNT:
		if not SaveLoad.has_save(slot):
			return slot
	return 0


# --- Pages ----------------------------------------------------------------------------------

func _show_main() -> void:
	page = Page.MAIN
	_settings.close()
	_slots.visible = false
	_menu.visible = true
	_entries = []
	var any_save: bool = _first_saved_slot() >= 0 and SaveLoad.has_save(_first_saved_slot())
	if any_save:
		_entries.append(&"continue")
	_entries.append(&"new_run")
	_entries.append(&"settings")
	_entries.append(&"quit")
	menu_index = clampi(menu_index, 0, _entries.size() - 1)
	_redraw_menu()
	_hint.text = "%s/%s select   %s confirm" % [InputPrompt.label(&"move_up"), InputPrompt.label(&"move_down"), InputPrompt.label(&"interact")]


func _show_slots() -> void:
	page = Page.SLOTS
	_confirm_slot = -1
	_menu.visible = false
	_slots.visible = true
	_slots_caption.text = "NEW RUN — PICK A SLOT" if fresh_run else "CONTINUE — PICK A SLOT"
	_redraw_slots()
	_hint.text = "%s confirm   %s back" % [InputPrompt.label(&"interact"), InputPrompt.label(&"pause")]


func _redraw_menu() -> void:
	for child: Node in _menu.get_children():
		_menu.remove_child(child)
		child.queue_free()
	_menu_labels.clear()
	var names: Dictionary = {&"continue": "CONTINUE", &"new_run": "NEW RUN", &"settings": "SETTINGS", &"quit": "QUIT"}
	for index: int in _entries.size():
		var label := Label.new()
		var selected: bool = index == menu_index
		label.text = ("> " if selected else "  ") + String(names[_entries[index]])
		label.add_theme_font_size_override("font_size", 40)
		label.add_theme_color_override("font_color", COL_ACTIVE if selected else COL_TEXT)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_menu.add_child(label)
		_menu_labels.append(label)


func _redraw_slots() -> void:
	for slot: int in SaveLoad.SLOT_COUNT:
		var selected: bool = slot == slot_index
		var data: Dictionary = SaveLoad.load_from_slot(slot) if SaveLoad.has_save(slot) else {}
		_slot_titles[slot].text = "%sSLOT %d" % ["> " if selected else "  ", slot + 1]
		_slot_titles[slot].add_theme_color_override("font_color", COL_ACTIVE if selected else COL_DIM)
		var body: String = summary(data)
		var colour: Color = COL_TEXT if not data.is_empty() else COL_DIM
		if _confirm_slot == slot:
			body = "OVERWRITE THIS SAVE?  %s again to confirm" % InputPrompt.label(&"interact")
			colour = COL_WARN
		elif not fresh_run and data.is_empty():
			colour = COL_DIM
		_slot_bodies[slot].text = body
		_slot_bodies[slot].add_theme_color_override("font_color", colour)
		_slot_cards[slot].add_theme_stylebox_override("panel", _card_style(selected))


## One line for a slot card: level, where, how long, how much.
func summary(data: Dictionary) -> String:
	if data.is_empty():
		return "— EMPTY —"
	var level: int = 1
	var credits: int = 0
	for value: Variant in data.values():
		if value is Dictionary and (value as Dictionary).has("level"):
			level = int((value as Dictionary).get("level", 1))
			credits = int((value as Dictionary).get("credits", 0))
	var where: String = "UNIT 14-C"
	var point: String = str(data.get("current_save_point", ""))
	if point != "" and _graph != null:
		var entry: Dictionary = _graph.room(StringName(point))
		where = str(entry.get("name", point)).to_upper()
	var seconds: int = int(float(data.get("play_time", 0.0)))
	var clock: String = "%d:%02d:%02d" % [seconds / 3600, (seconds / 60) % 60, seconds % 60] if seconds >= 3600 else "%d:%02d" % [seconds / 60, seconds % 60]
	var cleared: bool = "boss.landlord_defeated" in data.get("flags", [])
	return "LVL %d  ·  %s  ·  %s  ·  %d cr%s" % [level, where, clock, credits, "  ·  CLEARED" if cleared else ""]


func _card_style(selected: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.04, 0.07, 0.85)
	style.border_color = COL_ACTIVE if selected else Color(0.27, 0.31, 0.41)
	style.set_border_width_all(2)
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	return style


# --- Construction -----------------------------------------------------------------------------

func _build() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_backdrop()

	_title = _neon("NEON DEBT")
	var sub := Label.new()
	sub.text = "%s  ·  %s  ·  NOTICE OF DELINQUENCY" % [Lines.CORP_LONG.to_upper(), Lines.ACCOUNT]
	sub.add_theme_font_size_override("font_size", 24)
	sub.add_theme_color_override("font_color", COL_NOTICE)
	sub.set_anchors_preset(Control.PRESET_CENTER_TOP)
	sub.anchor_left = 0.0
	sub.anchor_right = 1.0
	sub.offset_top = 372.0
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(sub)

	_menu = VBoxContainer.new()
	_menu.anchor_left = 0.5
	_menu.anchor_right = 0.5
	_menu.offset_left = -130.0
	_menu.offset_right = 200.0
	_menu.offset_top = 520.0
	_menu.add_theme_constant_override("separation", 10)
	add_child(_menu)

	_slots = VBoxContainer.new()
	_slots.anchor_left = 0.5
	_slots.anchor_right = 0.5
	_slots.offset_left = -420.0
	_slots.offset_right = 420.0
	_slots.offset_top = 470.0
	_slots.add_theme_constant_override("separation", 12)
	_slots.visible = false
	add_child(_slots)
	_slots_caption = Label.new()
	_slots_caption.add_theme_font_size_override("font_size", 26)
	_slots_caption.add_theme_color_override("font_color", COL_DIM)
	_slots_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_slots.add_child(_slots_caption)
	for slot: int in SaveLoad.SLOT_COUNT:
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", _card_style(false))
		_slots.add_child(card)
		var column := VBoxContainer.new()
		card.add_child(column)
		var title := Label.new()
		title.add_theme_font_size_override("font_size", 26)
		column.add_child(title)
		var body := Label.new()
		body.add_theme_font_size_override("font_size", 24)
		column.add_child(body)
		_slot_cards.append(card)
		_slot_titles.append(title)
		_slot_bodies.append(body)

	_settings = SettingsPanel.new()
	_settings.visible = false
	_settings.closed.connect(func() -> void: _show_main())
	add_child(_settings)

	_hint = Label.new()
	_hint.anchor_top = 1.0
	_hint.anchor_bottom = 1.0
	_hint.anchor_right = 1.0
	_hint.offset_top = -60.0
	_hint.offset_bottom = -30.0
	_hint.add_theme_font_size_override("font_size", 22)
	_hint.add_theme_color_override("font_color", COL_DIM)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_hint)

	var footer := Label.new()
	footer.text = "v1 vertical slice"
	footer.anchor_top = 1.0
	footer.anchor_bottom = 1.0
	footer.anchor_left = 1.0
	footer.anchor_right = 1.0
	footer.offset_left = -240.0
	footer.offset_top = -40.0
	footer.offset_right = -24.0
	footer.add_theme_font_size_override("font_size", 20)
	footer.add_theme_color_override("font_color", COL_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(footer)

	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.modulate.a = 0.0
	add_child(_fade)


func _neon(text: String) -> Label:
	var holder := Control.new()
	holder.set_anchors_preset(Control.PRESET_CENTER_TOP)
	holder.anchor_left = 0.0
	holder.anchor_right = 1.0
	holder.offset_top = 200.0
	holder.offset_bottom = 360.0
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(holder)
	var font: Font = load("res://assets/theme/orbitron_bold.tres")
	for offset: Vector2 in [Vector2(-5, 0), Vector2(5, 0), Vector2(0, -5), Vector2(0, 5), Vector2(-3, -3), Vector2(3, 3)]:
		var glow := Label.new()
		glow.text = text
		glow.add_theme_font_override("font", font)
		glow.add_theme_font_size_override("font_size", 132)
		glow.add_theme_color_override("font_color", COL_NEON_GLOW)
		glow.set_anchors_preset(Control.PRESET_FULL_RECT)
		glow.position += offset
		glow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		glow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		glow.modulate.a = 0.25
		holder.add_child(glow)
		_glows.append(glow)
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", 132)
	label.add_theme_color_override("font_color", COL_NEON)
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.05, 0.1))
	label.add_theme_constant_override("outline_size", 6)
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	holder.add_child(label)
	return label


func _build_backdrop() -> void:
	var sky := TextureRect.new()
	sky.texture = load("res://assets/tiles/sky_gradient.png")
	sky.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sky)
	var far := _skyline("res://assets/tiles/skyline_far.png", 3.0, 1080.0 - 540.0 - 120.0, Color(0.55, 0.6, 0.75))
	add_child(far)
	_near = _skyline("res://assets/tiles/skyline_near.png", 3.0, 1080.0 - 540.0, Color(0.8, 0.85, 1.0))
	add_child(_near)

	var rain := CPUParticles2D.new()
	rain.amount = 260
	rain.lifetime = 1.4
	rain.preprocess = 1.4
	rain.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	rain.emission_rect_extents = Vector2(1100.0, 10.0)
	rain.position = Vector2(960.0, -20.0)
	rain.direction = Vector2(-0.15, 1.0)
	rain.spread = 2.0
	rain.gravity = Vector2.ZERO
	rain.initial_velocity_min = 900.0
	rain.initial_velocity_max = 1100.0
	rain.texture = load("res://assets/fx/drop.png")
	rain.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rain.color = Color(0.6, 0.8, 1.0, 0.35)
	add_child(rain)

	var ground := ColorRect.new()
	ground.color = Color(0.03, 0.035, 0.06)
	ground.anchor_top = 1.0
	ground.anchor_bottom = 1.0
	ground.anchor_right = 1.0
	ground.offset_top = -90.0
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ground)
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.05, 0.35)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)


func _skyline(path: String, scale_by: float, top: float, tint: Color) -> TextureRect:
	var strip := TextureRect.new()
	strip.texture = load(path)
	strip.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	strip.stretch_mode = TextureRect.STRETCH_TILE
	strip.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	strip.scale = Vector2(scale_by, scale_by)
	strip.position = Vector2(0.0, top)
	strip.size = Vector2(1920.0 * 2.0 / scale_by, strip.texture.get_height())
	strip.modulate = tint
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return strip
