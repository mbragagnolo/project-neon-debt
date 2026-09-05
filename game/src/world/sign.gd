class_name Sign
extends Node2D
## World text: signage, notices, the corp's fine print (docs/narrative/hook.md
## — story lives in environments and documents).
##
## Greybox: a placard with a label. M7 restyles it; the text is the content.

const COL_PLATE := Color(0.1, 0.12, 0.18, 0.9)
const COL_TEXT := Color(0.62, 0.72, 0.9)
const COL_WARN := Color(1.0, 0.45, 0.45)

@export_multiline var text: String = ""
@export var width: float = 300.0
## Red text for the corp's warnings and lockouts.
@export var warning: bool = false
@export var font_size: int = 20


func _ready() -> void:
	var lines: int = text.count("\n") + 1
	var height: float = float(lines) * (font_size + 6) + 16.0
	var plate := ColorRect.new()
	plate.color = COL_PLATE
	plate.position = Vector2(-width * 0.5, -height - 8.0)
	plate.size = Vector2(width, height)
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(plate)
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", COL_WARN if warning else COL_TEXT)
	label.position = Vector2(-width * 0.5 + 8.0, -height)
	label.size = Vector2(width - 16.0, height - 16.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
