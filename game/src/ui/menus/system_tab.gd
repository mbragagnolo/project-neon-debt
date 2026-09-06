class_name SystemTab
extends CanvasLayer
## The pause shell's SYSTEM tab (M7): the settings rows, and the way out.
## QUIT TO TITLE asks twice; what happened since the last care terminal is
## not saved, and the row says so.

const TITLE_SCENE := "res://rooms/title.tscn"
const COL_DIM := Color(0.45, 0.52, 0.64)

var panel: SettingsPanel
var _note: Label


func _ready() -> void:
	layer = 21
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel = SettingsPanel.new()
	panel.top_offset = 130.0
	panel.extra_rows = [[&"quit_title", "QUIT TO TITLE"]]
	panel.action.connect(_on_action)
	add_child(panel)
	_note = Label.new()
	_note.text = "Progress since the last care terminal is not saved."
	_note.anchor_top = 1.0
	_note.anchor_bottom = 1.0
	_note.anchor_right = 1.0
	_note.offset_top = -110.0
	_note.offset_bottom = -80.0
	_note.add_theme_font_size_override("font_size", 20)
	_note.add_theme_color_override("font_color", COL_DIM)
	_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_note)
	visible = false


func open() -> void:
	visible = true
	panel.open()


func close() -> void:
	visible = false
	panel.close()


func handle_input(event: InputEvent) -> bool:
	return panel.handle_input(event)


func _on_action(id: StringName) -> void:
	if id != &"quit_title":
		return
	get_tree().paused = false
	Music.stop(0.6)
	if get_tree().current_scene != null and get_tree().current_scene.scene_file_path == "res://rooms/world.tscn":
		get_tree().change_scene_to_file(TITLE_SCENE)
