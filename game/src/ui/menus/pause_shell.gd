class_name PauseShell
extends CanvasLayer
## The pause menu (docs/ui/screens.md): one shell, four tabs — map,
## loadout, quests, and system (settings, quit to title).
##
## The shell owns what every tab shares: pausing the tree, the tab bar, and
## the keys that open, close and cycle. A tab only handles navigation inside
## itself. `pause` opens on the map and closes from anywhere; `toggle_map`
## and `toggle_inventory` jump straight to their tab and close it again if it
## is already showing — one way in, two ways out, on pad and keyboard alike.

enum Tab { MAP, LOADOUT, QUESTS, SYSTEM }

const TAB_NAMES: Array[String] = ["MAP", "LOADOUT", "QUESTS", "SYSTEM"]
const COL_ACTIVE := Color(0.6, 0.95, 1.0)
const COL_DIM := Color(0.45, 0.52, 0.64)

var _open: bool = false
var _tab: Tab = Tab.MAP
var _tabs: Array[CanvasLayer] = []
var _bar: HBoxContainer
var _hint: Label


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	var map := MapScreen.new()
	map.name = "Map"
	add_child(map)
	var loadout := CanvasLayer.new()
	loadout.name = "Loadout"
	loadout.set_script(load("res://src/ui/menus/equip_screen.gd"))
	loadout.set("standalone", false)
	loadout.layer = 21
	add_child(loadout)
	var quests := QuestLog.new()
	quests.name = "Quests"
	add_child(quests)
	var system := SystemTab.new()
	system.name = "System"
	add_child(system)
	_tabs = [map, loadout, quests, system]
	visible = false


func is_open() -> bool:
	return _open


func current_tab() -> Tab:
	return _tab


func open(tab: Tab = Tab.MAP) -> void:
	_open = true
	visible = true
	get_tree().paused = true
	Sfx.play(&"ui_open")
	_show(tab)


func close() -> void:
	if not _open:
		return
	_tabs[_tab].close()
	_open = false
	visible = false
	get_tree().paused = false
	Sfx.play(&"ui_close")


func _show(tab: Tab) -> void:
	if _open and tab != _tab:
		Sfx.play(&"ui_move")
	if _open and _tabs[_tab].visible:
		_tabs[_tab].close()
	_tab = tab
	_tabs[_tab].open()
	_redraw_bar()


func _input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	# Another screen — a dialogue, the shop — has the tree; leave it alone.
	if not _open and get_tree().paused:
		return

	if not _open:
		if event.is_action(&"pause") or event.is_action(&"toggle_map"):
			open(Tab.MAP)
		elif event.is_action(&"toggle_inventory"):
			open(Tab.LOADOUT)
		else:
			return
		get_viewport().set_input_as_handled()
		return

	if event.is_action(&"pause"):
		close()
	elif event.is_action(&"toggle_map"):
		if _tab == Tab.MAP:
			close()
		else:
			_show(Tab.MAP)
	elif event.is_action(&"toggle_inventory"):
		if _tab == Tab.LOADOUT:
			close()
		else:
			_show(Tab.LOADOUT)
	elif event.is_action(&"hack_next"):
		_show((_tab + 1) % TAB_NAMES.size() as Tab)
	elif event.is_action(&"hack_prev"):
		_show((_tab + TAB_NAMES.size() - 1) % TAB_NAMES.size() as Tab)
	elif not _tabs[_tab].handle_input(event):
		return
	get_viewport().set_input_as_handled()


func _redraw_bar() -> void:
	for child: Node in _bar.get_children():
		_bar.remove_child(child)
		child.queue_free()
	var prev := Label.new()
	prev.text = InputPrompt.label(&"hack_prev")
	prev.add_theme_font_size_override("font_size", 20)
	prev.add_theme_color_override("font_color", COL_DIM)
	_bar.add_child(prev)
	for index: int in TAB_NAMES.size():
		var label := Label.new()
		label.text = TAB_NAMES[index]
		label.add_theme_font_size_override("font_size", 24)
		label.add_theme_color_override("font_color", COL_ACTIVE if index == _tab else COL_DIM)
		label.custom_minimum_size.x = 160.0
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_bar.add_child(label)
	var next := Label.new()
	next.text = InputPrompt.label(&"hack_next")
	next.add_theme_font_size_override("font_size", 20)
	next.add_theme_color_override("font_color", COL_DIM)
	_bar.add_child(next)
	_hint.text = "%s close" % InputPrompt.label(&"pause")


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.04, 0.05, 0.08, 0.92)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	_bar = HBoxContainer.new()
	_bar.anchor_left = 0.5
	_bar.anchor_right = 0.5
	_bar.anchor_top = 0.0
	_bar.offset_top = 26.0
	_bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	_bar.add_theme_constant_override("separation", 24)
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bar)

	_hint = Label.new()
	_hint.anchor_left = 1.0
	_hint.anchor_right = 1.0
	_hint.offset_left = -220.0
	_hint.offset_top = 30.0
	_hint.add_theme_font_size_override("font_size", 19)
	_hint.add_theme_color_override("font_color", COL_DIM)
	add_child(_hint)
