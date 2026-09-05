class_name EndingScreen
extends CanvasLayer
## The slice's end (DESIGN.md §3.5): the override module comes out of his
## deck, the leg firmware accepts it, the ledge lights up, to be continued.
##
## Shown by the world over the reception room after the camera has found
## the tease. One button dismisses it; the run continues — the district is
## still there to finish. M7 routes the dismissal to the title.

signal dismissed()

const COL_PANEL := Color(0.03, 0.04, 0.07, 0.94)
const COL_ACCENT := Color(0.6, 0.95, 1.0)
const COL_TEXT := Color(0.85, 0.9, 0.97)
const COL_DIM := Color(0.45, 0.52, 0.64)
const COL_GOOD := Color(0.45, 0.95, 0.6)

var _panel: ColorRect
var _open: bool = false


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	visible = false


func is_open() -> bool:
	return _open


func show_ending() -> void:
	_open = true
	visible = true
	_panel.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_panel, "modulate:a", 1.0, 1.2)


func dismiss() -> void:
	if not _open:
		return
	_open = false
	visible = false
	dismissed.emit()


func _input(event: InputEvent) -> void:
	if not _open or not event.is_pressed() or event.is_echo():
		return
	if event.is_action(&"interact") or event.is_action(&"jump") or event.is_action(&"pause"):
		dismiss()
		get_viewport().set_input_as_handled()


func _build() -> void:
	_panel = ColorRect.new()
	_panel.color = COL_PANEL
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)

	var box := VBoxContainer.new()
	box.anchor_left = 0.18
	box.anchor_right = 0.82
	box.anchor_top = 0.18
	box.anchor_bottom = 0.85
	box.add_theme_constant_override("separation", 26)
	_panel.add_child(box)

	_line(box, "%s COLLECTIONS OVERRIDE MODULE — REMOVED FROM ENFORCER DECK" % Lines.CORP, 22, COL_DIM)
	_line(box, "LEG UNIT FIRMWARE · TIER 2", 26, COL_TEXT)
	_line(box, "UNAUTHORIZED OVERRIDE ACCEPTED", 34, COL_GOOD)
	_line(box, "", 20, COL_DIM)
	_line(box, "You are still behind on payments. Now you have the keys.", 28, COL_TEXT)
	_line(box, "", 20, COL_DIM)
	_line(box, "TO BE CONTINUED", 44, COL_ACCENT)
	_line(box, "THE STACKS is one district of nine.", 22, COL_DIM)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)
	_line(box, "%s keep exploring" % InputPrompt.label(&"interact"), 20, COL_DIM)


func _line(parent: Node, text: String, size: int, colour: Color) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", colour)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
