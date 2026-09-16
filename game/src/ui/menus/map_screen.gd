class_name MapScreen
extends CanvasLayer
## The district map (DESIGN.md §3.4): explored rooms revealed, drawn from
## the `WorldGraph` the generator wrote. Reads `GameState.visited_rooms()`
## for what to show and the last `room_entered` for where you are.

const GRAPH_PATH := "res://src/world/world_graph.tres"

const CELL := 52.0
const COL_ROOM := UiPalette.ROOM
const COL_ROOM_EDGE := UiPalette.ROOM_EDGE
const COL_CURRENT := UiPalette.ACCENT
const COL_SAVE := UiPalette.SAVE
const COL_TEXT := UiPalette.TEXT
const COL_DIM := UiPalette.DIM
const COL_DOOR := UiPalette.DOOR

var graph: WorldGraph
var current_room: StringName = &""
var _canvas: Control
var _name: Label
var _phase: float = 0.0


func _ready() -> void:
	layer = 21
	process_mode = Node.PROCESS_MODE_ALWAYS
	graph = load(GRAPH_PATH) if ResourceLoader.exists(GRAPH_PATH) else WorldGraph.new()
	Events.room_entered.connect(_on_room_entered)
	_build()
	visible = false


func _process(delta: float) -> void:
	if not visible:
		return
	_phase += delta
	_canvas.queue_redraw()


func open() -> void:
	visible = true
	var entry: Dictionary = graph.room(current_room)
	_name.text = str(entry.get("name", "")).to_upper() if not entry.is_empty() else ""
	_canvas.queue_redraw()


func close() -> void:
	visible = false


## Nothing to navigate yet; the map is a picture.
func handle_input(_event: InputEvent) -> bool:
	return false


func _on_room_entered(room_id: StringName) -> void:
	current_room = room_id


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
	title.text = "THE STACKS"
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", COL_CURRENT)
	page.add_child(title)

	_canvas = Control.new()
	_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_map)
	page.add_child(_canvas)

	_name = Label.new()
	_name.add_theme_font_size_override("font_size", 24)
	_name.add_theme_color_override("font_color", COL_TEXT)
	page.add_child(_name)

	var legend := Label.new()
	legend.text = "◆ you     S  care terminal     explored rooms only"
	legend.add_theme_font_size_override("font_size", 19)
	legend.add_theme_color_override("font_color", COL_DIM)
	page.add_child(legend)


## Rooms as cells; the whole district centred in the canvas.
func _draw_map() -> void:
	if graph == null or graph.rooms.is_empty():
		return
	var bounds: Rect2i = graph.bounds()
	var district := Vector2(bounds.size) * CELL
	var origin: Vector2 = (_canvas.size - district) * 0.5 - Vector2(bounds.position) * CELL

	for entry: Dictionary in graph.rooms:
		var id: StringName = StringName(str(entry.get("id", "")))
		if not GameState.has_visited(id):
			continue
		var cell: Vector2i = entry.get("cell", Vector2i.ZERO)
		var size: Vector2i = entry.get("size", Vector2i.ONE)
		var rect := Rect2(origin + Vector2(cell) * CELL, Vector2(size) * CELL)
		rect = rect.grow(-3.0)
		var is_current: bool = id == current_room
		_canvas.draw_rect(rect, COL_ROOM)
		_canvas.draw_rect(rect, COL_CURRENT if is_current else COL_ROOM_EDGE, false, 2.0)

		for door: Dictionary in entry.get("doors", []):
			var at: Vector2i = door.get("at", Vector2i.ZERO)
			var side: int = int(door.get("side", 0))
			var notch: Rect2
			var base: Vector2 = origin + Vector2(cell + at) * CELL
			match side:
				Door.Side.LEFT:
					notch = Rect2(base + Vector2(0.0, CELL * 0.35), Vector2(6.0, CELL * 0.3))
				Door.Side.RIGHT:
					notch = Rect2(base + Vector2(CELL - 6.0, CELL * 0.35), Vector2(6.0, CELL * 0.3))
				Door.Side.UP:
					notch = Rect2(base + Vector2(CELL * 0.35, 0.0), Vector2(CELL * 0.3, 6.0))
				Door.Side.DOWN:
					notch = Rect2(base + Vector2(CELL * 0.35, CELL - 6.0), Vector2(CELL * 0.3, 6.0))
			_canvas.draw_rect(notch, COL_DOOR)

		if bool(entry.get("save", false)):
			_canvas.draw_string(
				ThemeDB.fallback_font, rect.position + Vector2(8.0, 22.0), "S",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 18, COL_SAVE
			)
		if is_current:
			var pulse: float = 0.6 + 0.4 * (0.5 + 0.5 * sin(_phase * 5.0))
			var centre: Vector2 = rect.get_center()
			var you := PackedVector2Array([
				centre + Vector2(0, -9), centre + Vector2(9, 0),
				centre + Vector2(0, 9), centre + Vector2(-9, 0),
			])
			_canvas.draw_colored_polygon(you, Color(COL_CURRENT.r, COL_CURRENT.g, COL_CURRENT.b, pulse))
