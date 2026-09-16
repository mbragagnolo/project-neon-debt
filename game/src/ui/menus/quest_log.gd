class_name QuestLog
extends CanvasLayer
## The quest log tab (DESIGN.md §3.7). One quest in the slice; the log still
## reads the tracker rather than the quest, so a second one costs no UI.

const COL_TEXT := UiPalette.TEXT
const COL_DIM := UiPalette.DIM
const COL_ACCENT := UiPalette.ACCENT
const COL_GOOD := UiPalette.GOOD

var _rows: VBoxContainer


func _ready() -> void:
	layer = 21
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	visible = false


func open() -> void:
	visible = true
	_redraw()


func close() -> void:
	visible = false


func handle_input(_event: InputEvent) -> bool:
	return false


func _redraw() -> void:
	for child: Node in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	var any: bool = false
	for quest: Quest in Quests.quests:
		var state: Quests.State = Quests.state(quest.id)
		if state == Quests.State.UNKNOWN:
			continue
		any = true
		var done: bool = state == Quests.State.COMPLETE
		_line(quest.title.to_upper(), 26, COL_GOOD if done else COL_ACCENT)
		_line(quest.giver, 20, COL_DIM)
		_line(quest.epilogue if done else quest.objective, 22, COL_TEXT)
		if not done and Quests.can_complete(quest.id):
			_line("You have what they asked for. Go back.", 20, COL_GOOD)
		_line("", 12, COL_DIM)
	if not any:
		_line("Nobody has asked you for anything yet.", 22, COL_DIM)


func _line(text: String, size: int, colour: Color) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", colour)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 900.0
	_rows.add_child(label)


func _build() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 90)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)

	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 18)
	margin.add_child(page)

	var title := Label.new()
	title.text = "QUESTS"
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", COL_ACCENT)
	page.add_child(title)

	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 6)
	page.add_child(_rows)
