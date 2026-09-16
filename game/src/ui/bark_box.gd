class_name BarkBox
extends CanvasLayer
## The protagonist's one-liners (docs/narrative/hook.md — terse, tired,
## working-class wry). Bottom of the screen, a few seconds, gone.
##
## Not a dialogue: the game does not stop for a bark. It reads the bus, so
## anything anywhere can hand the protagonist a line without knowing what a
## HUD is.

const COL_NAME := UiPalette.ACCENT
const COL_TEXT := UiPalette.TEXT
const HOLD_SECONDS := 4.5

var _label: Label
var _timer: float = 0.0


func _ready() -> void:
	layer = 12
	var box := HBoxContainer.new()
	box.anchor_left = 0.1
	box.anchor_right = 0.9
	box.anchor_top = 0.86
	box.anchor_bottom = 0.92
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(box)

	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 26)
	_label.add_theme_color_override("font_color", COL_TEXT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label.modulate.a = 0.0
	box.add_child(_label)

	Events.bark_requested.connect(_on_bark)


func _process(delta: float) -> void:
	if _timer <= 0.0:
		return
	_timer -= delta
	if _timer <= 0.8:
		_label.modulate.a = maxf(_timer / 0.8, 0.0)


func _on_bark(text: String) -> void:
	_label.text = "%s — %s" % [Lines.PROTAGONIST_SHORT.to_upper(), text]
	_label.modulate.a = 1.0
	_timer = HOLD_SECONDS
