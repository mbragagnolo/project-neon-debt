class_name ShopScreen
extends CanvasLayer
## Stitch's stall (DESIGN.md §3.3; docs/rpg/economy.md).
##
## A short list, one button to buy, one to leave. Pauses the tree like every
## other screen. The purchase rules live in `buy()` so a test can shop
## without a pad in hand.

const STOCK_PATH := "res://src/rpg/shop_stock.tres"

const COL_TEXT := Color(0.78, 0.86, 0.95)
const COL_DIM := Color(0.45, 0.52, 0.64)
const COL_SELECTED := Color(1.0, 0.18, 0.58)
const COL_ACCENT := Color(0.6, 0.95, 1.0)
const COL_GOOD := Color(0.45, 0.95, 0.6)
const COL_BAD := Color(1.0, 0.45, 0.45)

var stock: ShopStock
var _index: int = 0
var _rows: VBoxContainer
var _detail: Label
var _credits: Label
var _feedback: Label
var _hint: Label
var _open: bool = false


func _ready() -> void:
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group(&"shop")
	stock = load(STOCK_PATH)
	_build()
	visible = false


func is_open() -> bool:
	return _open


func open() -> void:
	_open = true
	_index = 0
	visible = true
	get_tree().paused = true
	_feedback.text = ""
	_redraw()


func close() -> void:
	_open = false
	visible = false
	get_tree().paused = false


func _input(event: InputEvent) -> void:
	if not _open or not event.is_pressed() or event.is_echo():
		return
	if event.is_action(&"pause") or event.is_action(&"toggle_inventory"):
		close()
	elif event.is_action(&"move_down"):
		_index = wrapi(_index + 1, 0, stock.entries.size())
		_redraw()
	elif event.is_action(&"move_up"):
		_index = wrapi(_index - 1, 0, stock.entries.size())
		_redraw()
	elif event.is_action(&"interact"):
		_feedback_for(buy(stock.entries[_index]))
		_redraw()
	else:
		return
	get_viewport().set_input_as_handled()


# --- The rules ----------------------------------------------------------------

func sold_flag(entry: ShopEntry) -> StringName:
	return StringName("shop.%s" % entry.id)


func is_sold_out(entry: ShopEntry) -> bool:
	if entry.kind == ShopEntry.Kind.ITEM:
		return Inventory.owns(entry.item_id)
	return entry.once and GameState.has_flag(sold_flag(entry))


## Tries to buy. Returns why it could not, or `&"bought"`.
func buy(entry: ShopEntry) -> StringName:
	if entry == null:
		return &"nothing"
	if is_sold_out(entry):
		return &"sold_out"
	var player: Node = get_tree().get_first_node_in_group(&"player")
	if entry.kind == ShopEntry.Kind.AMMO_REFILL:
		if player == null or player.get(&"ammo") >= player.get(&"max_ammo"):
			return &"full"
	if not PlayerStats.spend_credits(entry.price):
		return &"credits"

	match entry.kind:
		ShopEntry.Kind.ITEM:
			Inventory.grant(entry.item_id)
		ShopEntry.Kind.HP_UP:
			PlayerStats.add_max_hp(entry.amount)
		ShopEntry.Kind.AMMO_CAP:
			PlayerStats.add_max_ammo(entry.amount)
		ShopEntry.Kind.AMMO_REFILL:
			if player != null:
				player.call(&"add_ammo", 999)
	if entry.once:
		GameState.set_flag(sold_flag(entry))
	Events.shop_purchased.emit(entry.id)
	return &"bought"


func _feedback_for(result: StringName) -> void:
	match result:
		&"bought":
			_feedback.text = "SOLD. NO REFUNDS."
			_feedback.add_theme_color_override("font_color", COL_GOOD)
		&"credits":
			_feedback.text = "NOT ENOUGH CREDITS."
			_feedback.add_theme_color_override("font_color", COL_BAD)
		&"sold_out":
			_feedback.text = "ALREADY YOURS."
			_feedback.add_theme_color_override("font_color", COL_DIM)
		&"full":
			_feedback.text = "YOU'RE FULL."
			_feedback.add_theme_color_override("font_color", COL_DIM)
		_:
			_feedback.text = ""


# --- Drawing ------------------------------------------------------------------

func _redraw() -> void:
	for child: Node in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	_credits.text = "CREDITS  %d" % PlayerStats.credits
	for index: int in stock.entries.size():
		var entry: ShopEntry = stock.entries[index]
		var selected: bool = index == _index
		var row := HBoxContainer.new()
		_rows.add_child(row)
		_cell(row, "▸" if selected else " ", 30.0, COL_SELECTED)
		_cell(row, entry.label, 520.0, COL_ACCENT if selected else COL_TEXT)
		var status: String = "%d cr" % entry.price
		var colour: Color = COL_TEXT
		if is_sold_out(entry):
			status = "sold"
			colour = COL_DIM
		elif PlayerStats.credits < entry.price:
			colour = COL_BAD
		_cell(row, status, 120.0, colour)
	var current: ShopEntry = stock.entries[_index]
	_detail.text = current.description
	_hint.text = "[W/S] browse   %s buy   %s leave" % [
		InputPrompt.label(&"interact"), InputPrompt.label(&"pause")
	]


func _cell(parent: Node, text: String, width: float, colour: Color) -> void:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size.x = width
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", colour)
	parent.add_child(label)


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.04, 0.05, 0.08, 0.92)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 140)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)

	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 22)
	margin.add_child(page)

	var title := Label.new()
	title.text = "%s — PAWN & SURGERY" % Lines.VENDOR.to_upper()
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", COL_ACCENT)
	page.add_child(title)

	_credits = Label.new()
	_credits.add_theme_font_size_override("font_size", 24)
	_credits.add_theme_color_override("font_color", COL_DIM)
	page.add_child(_credits)

	_rows = VBoxContainer.new()
	page.add_child(_rows)

	_detail = Label.new()
	_detail.add_theme_font_size_override("font_size", 20)
	_detail.add_theme_color_override("font_color", COL_DIM)
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.custom_minimum_size.x = 700.0
	page.add_child(_detail)

	_feedback = Label.new()
	_feedback.add_theme_font_size_override("font_size", 24)
	page.add_child(_feedback)

	_hint = Label.new()
	_hint.add_theme_font_size_override("font_size", 19)
	_hint.add_theme_color_override("font_color", COL_DIM)
	_hint.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_hint.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	page.add_child(_hint)
