class_name DialogueBox
extends CanvasLayer
## Written lines at story beats (docs/narrative/hook.md): a speaker, a few
## pages, one button to advance. Never a tree, never a choice.
##
## Pauses the tree while open — a line nobody can read because a Scav is
## lunging is a line that was not worth writing — and keeps running itself.
## Controller and keyboard: `interact` or `jump` advances, `pause` skips out.

signal finished()

const COL_PANEL := Color(0.05, 0.06, 0.1, 0.94)
const COL_SPEAKER := Color(0.6, 0.95, 1.0)
const COL_TEXT := Color(0.85, 0.9, 0.97)
const COL_HINT := Color(0.45, 0.52, 0.64)

var _panel: ColorRect
var _speaker: Label
var _body: Label
var _hint: Label
var _pages: Array[String] = []
var _page: int = 0
var _open: bool = false


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group(&"dialogue_box")
	_build()
	visible = false


func is_open() -> bool:
	return _open


## Shows `pages` one at a time. Await `finished` for what happens after.
func open(speaker: String, pages: Array[String]) -> void:
	if pages.is_empty():
		finished.emit()
		return
	_pages = pages
	_page = 0
	_speaker.text = speaker.to_upper()
	_open = true
	visible = true
	get_tree().paused = true
	_show_page()


func close() -> void:
	if not _open:
		return
	_open = false
	visible = false
	get_tree().paused = false
	finished.emit()


func _input(event: InputEvent) -> void:
	if not _open or not event.is_pressed() or event.is_echo():
		return
	if event.is_action(&"interact") or event.is_action(&"jump"):
		_advance()
	elif event.is_action(&"pause"):
		close()
	else:
		return
	get_viewport().set_input_as_handled()


func _advance() -> void:
	_page += 1
	if _page >= _pages.size():
		close()
	else:
		_show_page()


func _show_page() -> void:
	_body.text = _pages[_page]
	var last: bool = _page == _pages.size() - 1
	_hint.text = "%s %s" % [InputPrompt.label(&"interact"), "close" if last else "next"]


func _build() -> void:
	_panel = ColorRect.new()
	_panel.color = COL_PANEL
	_panel.anchor_left = 0.15
	_panel.anchor_right = 0.85
	_panel.anchor_top = 0.72
	_panel.anchor_bottom = 0.94
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 24)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)

	_speaker = Label.new()
	_speaker.add_theme_font_size_override("font_size", 24)
	_speaker.add_theme_color_override("font_color", COL_SPEAKER)
	box.add_child(_speaker)

	_body = Label.new()
	_body.add_theme_font_size_override("font_size", 28)
	_body.add_theme_color_override("font_color", COL_TEXT)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(_body)

	_hint = Label.new()
	_hint.add_theme_font_size_override("font_size", 18)
	_hint.add_theme_color_override("font_color", COL_HINT)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	box.add_child(_hint)
