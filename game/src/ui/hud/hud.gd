class_name Hud
extends CanvasLayer
## The HUD (DESIGN.md §3.7; docs/ui/screens.md): HP, RAM, ammo pips, the
## quickslot, level and XP, credits, the boss bar, toasts.
##
## Reads the signal bus only, like the gym readout it replaces: it holds no
## reference to the player, so it draws whatever the last signal said and
## asks the sheet once at ready. Every signal it hangs off was declared on
## the bus in M0.

const COL_HP := UiPalette.HP
const COL_HP_LOW := UiPalette.HP_LOW
const COL_RAM := UiPalette.RAM
const COL_XP := UiPalette.XP
const COL_TEXT := UiPalette.TEXT
const COL_DIM := UiPalette.DIM
const COL_GOOD := UiPalette.GOOD
const COL_BAD := UiPalette.BAD
const COL_HACK := UiPalette.HACK

var _hp_fill: ColorRect
var _hp_text: Label
var _ram_fill: ColorRect
var _ram_text: Label
var _pips: HBoxContainer
var _slot_name: Label
var _slot_cost: Label
var _slot_hint: Label
var _slot_frame: NinePatchRect
var _level: Label
var _xp_fill: ColorRect
var _credits: Label
var _boss_box: Control
var _boss_name: Label
var _boss_fill: ColorRect
var _toast: Label
var _vignette: ColorRect

var _catalog: HackCatalog
var _selected_hack: StringName = &""
var _hp: int = 0
var _max_hp: int = 1
var _toast_timer: float = 0.0
var _flash_timer: float = 0.0
var _guard_timer: float = 0.0
var _pulse: float = 0.0


func _ready() -> void:
	layer = 10
	_catalog = load(HackKit.CATALOG_PATH)
	_build()
	Events.hp_changed.connect(_on_hp)
	Events.ram_changed.connect(_on_ram)
	Events.ammo_changed.connect(_on_ammo)
	Events.stats_changed.connect(_on_stats)
	Events.credits_changed.connect(_on_credits)
	Events.hack_selected.connect(_on_hack_selected)
	Events.hack_cast.connect(_on_hack_cast)
	Events.hack_failed.connect(_on_hack_failed)
	Events.hack_acquired.connect(func(id: StringName) -> void: _toast_show("PROGRAM ACQUIRED — %s" % _hack_name(id)))
	Events.guard_changed.connect(_on_guard)
	Events.level_gained.connect(func(level: int) -> void: _toast_show("LEVEL %d — FULL RESTORE" % level, COL_GOOD))
	Events.toast_requested.connect(_toast_show)
	Events.boss_hp_changed.connect(_on_boss)
	Events.boss_defeated.connect(func(_b: Node) -> void: _boss_box.visible = false)
	Events.room_exited.connect(func(_r: StringName) -> void: _boss_box.visible = false)
	_on_stats(PlayerStats.as_dictionary())
	# The bus carries no history: ask the player, if one is already there.
	var player: Node = get_tree().get_first_node_in_group(&"player")
	if player != null and player.has_method(&"publish_vitals"):
		player.call(&"publish_vitals")


func _process(delta: float) -> void:
	_pulse += delta
	if _toast_timer > 0.0:
		_toast_timer -= delta
		_toast.modulate.a = clampf(_toast_timer / 0.5, 0.0, 1.0)
	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			_draw_slot()
	if _guard_timer > 0.0:
		_guard_timer -= delta
		_slot_hint.text = "FIREWALL %.1fs" % maxf(_guard_timer, 0.0)
		if _guard_timer <= 0.0:
			_draw_slot()
	# Low health breathes red at the edges. Not before the first HP arrives.
	var low: bool = _max_hp > 1 and _hp <= _max_hp / 4
	_vignette.modulate.a = (0.25 + 0.15 * sin(_pulse * 5.0)) if low else 0.0


# --- Signals --------------------------------------------------------------------------

func _on_hp(current: int, maximum: int) -> void:
	_hp = current
	_max_hp = maxi(maximum, 1)
	_hp_fill.size.x = 216.0 * float(current) / float(_max_hp)
	_hp_fill.color = COL_HP_LOW if current <= _max_hp / 4 else COL_HP
	_hp_text.text = "%d/%d" % [current, maximum]


func _on_ram(current: int, maximum: int) -> void:
	_ram_fill.size.x = 216.0 * float(current) / float(maxi(maximum, 1))
	_ram_text.text = "%d/%d" % [current, maximum]


func _on_ammo(current: int, maximum: int) -> void:
	for child: Node in _pips.get_children():
		_pips.remove_child(child)
		child.queue_free()
	for i: int in mini(maximum, 20):
		var pip := TextureRect.new()
		pip.texture = load("res://assets/ui/pip_on.png" if i < current else "res://assets/ui/pip_off.png")
		pip.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		pip.stretch_mode = TextureRect.STRETCH_KEEP
		_pips.add_child(pip)


func _on_stats(sheet: Dictionary) -> void:
	_level.text = "LVL %d" % int(sheet.get("level", 1))
	var into: float = float(sheet.get("xp_into_level", 0))
	var need: float = maxf(float(sheet.get("xp_for_level", 1)), 1.0)
	_xp_fill.size.x = 120.0 * clampf(into / need, 0.0, 1.0)
	_credits.text = "%d cr" % int(sheet.get("credits", 0))


func _on_credits(amount: int) -> void:
	_credits.text = "%d cr" % amount


func _on_hack_selected(id: StringName) -> void:
	_selected_hack = id
	_draw_slot()


func _on_hack_cast(id: StringName, _cost: int) -> void:
	_slot_hint.text = "%s CAST" % _hack_name(id)
	_slot_hint.add_theme_color_override("font_color", COL_GOOD)
	_flash_timer = 0.5


func _on_hack_failed(_id: StringName, reason: StringName) -> void:
	var why: String
	match reason:
		&"ram": why = "NO RAM"
		&"cooldown": why = "COOLING"
		&"no_target": why = "NO TARGET"
		&"no_deck": why = "NO DECK"
		_: why = "NO PROGRAM"
	_slot_hint.text = why
	_slot_hint.add_theme_color_override("font_color", COL_BAD)
	_flash_timer = 0.8


func _on_guard(active: bool, seconds: float) -> void:
	_guard_timer = seconds if active else 0.0
	_draw_slot()


func _on_boss(display_name: String, hp: int, max_hp: int) -> void:
	_boss_box.visible = hp > 0
	_boss_name.text = display_name.to_upper()
	_boss_fill.size.x = 596.0 * float(hp) / float(maxi(max_hp, 1))


func _toast_show(text: String, colour: Color = COL_TEXT) -> void:
	_toast.text = text
	_toast.add_theme_color_override("font_color", colour)
	_toast.modulate.a = 1.0
	_toast_timer = 2.8


func _hack_name(id: StringName) -> String:
	var hack: Hack = _catalog.by_id(id) if _catalog != null else null
	return hack.display_name.to_upper() if hack != null else "—"


func _draw_slot() -> void:
	var hack: Hack = _catalog.by_id(_selected_hack) if _catalog != null else null
	_slot_name.text = hack.display_name.to_upper() if hack != null else "—"
	_slot_cost.text = "%d RAM" % hack.ram_cost if hack != null else ""
	_slot_frame.modulate = hack.color if hack != null else Color.WHITE
	if _guard_timer > 0.0:
		_slot_hint.text = "FIREWALL %.1fs" % _guard_timer
		_slot_hint.add_theme_color_override("font_color", COL_GOOD)
	else:
		_slot_hint.text = "%s  %s  %s" % [InputPrompt.label(&"hack_prev"), InputPrompt.label(&"hack_cast"), InputPrompt.label(&"hack_next")]
		_slot_hint.add_theme_color_override("font_color", COL_DIM)


# --- Construction -----------------------------------------------------------------------------

func _frame(size: Vector2) -> NinePatchRect:
	var frame := NinePatchRect.new()
	frame.texture = load("res://assets/ui/hud_frame.png")
	frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for side: String in ["left", "top", "right", "bottom"]:
		frame.set("patch_margin_%s" % side, 6)
	frame.custom_minimum_size = size
	frame.size = size
	return frame


func _bar(parent: Node, label_text: String, colour: Color, width: float = 228.0) -> Array:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)
	var label := _label(label_text, 24, COL_DIM)
	label.custom_minimum_size.x = 58.0
	row.add_child(label)
	var frame := _frame(Vector2(width, 22.0))
	row.add_child(frame)
	var fill := ColorRect.new()
	fill.color = colour
	fill.position = Vector2(6.0, 6.0)
	fill.size = Vector2(width - 12.0, 10.0)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(fill)
	var text := _label("", 22, COL_TEXT)
	row.add_child(text)
	return [fill, text]


func _label(text: String, size: int, colour: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", colour)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _build() -> void:
	_vignette = ColorRect.new()
	_vignette.color = UiPalette.VIGNETTE
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette.modulate.a = 0.0
	# A frame, not a flood: only the edges tint.
	var shader := Shader.new()
	shader.code = "shader_type canvas_item;\nvoid fragment() {\n\tfloat d = distance(UV, vec2(0.5));\n\tCOLOR.a *= smoothstep(0.32, 0.72, d);\n}\n"
	var material := ShaderMaterial.new()
	material.shader = shader
	_vignette.material = material
	add_child(_vignette)

	var box := VBoxContainer.new()
	box.position = Vector2(28.0, 22.0)
	box.add_theme_constant_override("separation", 6)
	add_child(box)

	var hp: Array = _bar(box, "HP", COL_HP)
	_hp_fill = hp[0]
	_hp_text = hp[1]
	var ram: Array = _bar(box, "RAM", COL_RAM)
	_ram_fill = ram[0]
	_ram_text = ram[1]

	var ammo_row := HBoxContainer.new()
	ammo_row.add_theme_constant_override("separation", 10)
	box.add_child(ammo_row)
	var ammo_label := _label("AMMO", 24, COL_DIM)
	ammo_label.custom_minimum_size.x = 58.0
	ammo_row.add_child(ammo_label)
	_pips = HBoxContainer.new()
	_pips.add_theme_constant_override("separation", 4)
	ammo_row.add_child(_pips)

	var slot_row := HBoxContainer.new()
	slot_row.add_theme_constant_override("separation", 12)
	box.add_child(slot_row)
	_slot_frame = NinePatchRect.new()
	_slot_frame.texture = load("res://assets/ui/slot.png")
	_slot_frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for side: String in ["left", "top", "right", "bottom"]:
		_slot_frame.set("patch_margin_%s" % side, 6)
	_slot_frame.custom_minimum_size = Vector2(56.0, 56.0)
	slot_row.add_child(_slot_frame)
	var initial := _label("H", 40, COL_HACK)
	initial.set_anchors_preset(Control.PRESET_FULL_RECT)
	initial.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	initial.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_slot_frame.add_child(initial)
	initial.text = "◆"
	var slot_text := VBoxContainer.new()
	slot_text.add_theme_constant_override("separation", -4)
	slot_row.add_child(slot_text)
	_slot_name = _label("—", 28, COL_HACK)
	slot_text.add_child(_slot_name)
	_slot_cost = _label("", 20, COL_DIM)
	slot_text.add_child(_slot_cost)
	_slot_hint = _label("", 20, COL_DIM)
	slot_text.add_child(_slot_hint)

	var level_row := HBoxContainer.new()
	level_row.add_theme_constant_override("separation", 10)
	box.add_child(level_row)
	_level = _label("LVL 1", 24, COL_TEXT)
	_level.custom_minimum_size.x = 58.0
	level_row.add_child(_level)
	var xp_frame := _frame(Vector2(132.0, 16.0))
	level_row.add_child(xp_frame)
	_xp_fill = ColorRect.new()
	_xp_fill.color = COL_XP
	_xp_fill.position = Vector2(6.0, 5.0)
	_xp_fill.size = Vector2(0.0, 6.0)
	_xp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	xp_frame.add_child(_xp_fill)
	_credits = _label("0 cr", 24, UiPalette.CREDITS)
	level_row.add_child(_credits)

	# The boss bar, centred at the top.
	_boss_box = VBoxContainer.new()
	_boss_box.anchor_left = 0.5
	_boss_box.anchor_right = 0.5
	_boss_box.offset_left = -304.0
	_boss_box.offset_top = 26.0
	_boss_box.add_theme_constant_override("separation", 2)
	_boss_box.visible = false
	add_child(_boss_box)
	_boss_name = _label("", 26, COL_BAD)
	_boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_name.custom_minimum_size.x = 608.0
	_boss_box.add_child(_boss_name)
	var boss_frame := _frame(Vector2(608.0, 22.0))
	_boss_box.add_child(boss_frame)
	_boss_fill = ColorRect.new()
	_boss_fill.color = COL_BAD
	_boss_fill.position = Vector2(6.0, 6.0)
	_boss_fill.size = Vector2(596.0, 10.0)
	_boss_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_frame.add_child(_boss_fill)

	_toast = _label("", 30, COL_TEXT)
	_toast.anchor_left = 0.5
	_toast.anchor_right = 0.5
	_toast.offset_left = -500.0
	_toast.offset_top = 96.0
	_toast.custom_minimum_size.x = 1000.0
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.modulate.a = 0.0
	add_child(_toast)
