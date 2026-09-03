extends CanvasLayer
## The inventory/equip screen (docs/ui/screens.md).
##
## Not a container UI. The slice has ten items and no bag pressure, so this
## screen exists to **show the consequence of a choice** — which is why the
## right-hand panel is a delta readout rather than an item grid, and why the
## sheet stays on screen while browsing (a delta is unreadable without the
## total it applies to).
##
## The load-bearing rule is spec rule 4: every number here comes from the same
## effective-stats layer the pipeline uses, never off a resource field.
## Showing a weapon's authored `power` where the fight uses
## `power × stat_multiplier` would make the screen agree with the item file
## and disagree with the game — and M3's exit test could then pass on a lie.
##
## Built in code rather than as a `.tscn` for the same reason the debug HUD is:
## it is greybox, it is one milestone's worth of layout, and a scene file would
## be four hundred lines of node text nobody can diff. M7 restyles it; the spec
## says it must not have to restructure it.

const COMBAT_CONFIG_PATH := "res://src/combat/combat_config.tres"

const COL_TEXT := Color(0.78, 0.86, 0.95)
const COL_DIM := Color(0.45, 0.52, 0.64)
const COL_SELECTED := Color(1.0, 0.18, 0.58)
const COL_ACCENT := Color(0.6, 0.95, 1.0)
const COL_BETTER := Color(0.45, 0.95, 0.6)
const COL_WORSE := Color(1.0, 0.45, 0.45)

const SLOT_ORDER: Array[Item.Slot] = [
	Item.Slot.MELEE,
	Item.Slot.RANGED,
	Item.Slot.HEAD,
	Item.Slot.BODY,
	Item.Slot.LEGS,
	Item.Slot.HANDS,
]

enum Column { SLOTS, ITEMS }

var _config: CombatConfig
var _slot_index: int = 0
var _item_index: int = 0
var _column: Column = Column.SLOTS

var _slot_rows: VBoxContainer
var _sheet_rows: VBoxContainer
var _item_rows: VBoxContainer
var _detail: VBoxContainer
var _detail_title: Label
var _detail_body: Label
var _hint: Label


func _ready() -> void:
	layer = 20
	# The screen has to keep running while the tree it paused does not.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_config = load(COMBAT_CONFIG_PATH)
	_build()
	visible = false


func _input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return

	if event.is_action(&"toggle_inventory"):
		toggle()
		get_viewport().set_input_as_handled()
		return
	if not visible:
		return

	# One way in, two ways out: a menu you can only leave through the button
	# that opened it is the classic controller trap.
	if event.is_action(&"pause"):
		close()
	elif event.is_action(&"move_down"):
		_move(1)
	elif event.is_action(&"move_up"):
		_move(-1)
	elif event.is_action(&"move_right"):
		_focus_items()
	elif event.is_action(&"move_left"):
		_column = Column.SLOTS
		_redraw()
	elif event.is_action(&"interact"):
		_confirm()
	else:
		return
	get_viewport().set_input_as_handled()


# --- Open / close -----------------------------------------------------------

func toggle() -> void:
	if visible:
		close()
	else:
		open()


func open() -> void:
	visible = true
	_column = Column.SLOTS
	_item_index = 0
	# Nothing is fought behind an open menu, and no comparison is made against
	# a health bar that is still moving.
	get_tree().paused = true
	_redraw()


func close() -> void:
	visible = false
	get_tree().paused = false


# --- Navigation -------------------------------------------------------------

func _slot() -> Item.Slot:
	return SLOT_ORDER[_slot_index]


func _candidates() -> Array[Item]:
	return Inventory.owned_in_slot(_slot())


## The item the cursor is on: the highlighted candidate, or — while the cursor
## is in the slot column — whatever is equipped there.
func _highlighted() -> Item:
	var items: Array[Item] = _candidates()
	if _column == Column.ITEMS and _item_index < items.size():
		return items[_item_index]
	return Inventory.equipped(_slot())


func _move(step: int) -> void:
	if _column == Column.SLOTS:
		_slot_index = wrapi(_slot_index + step, 0, SLOT_ORDER.size())
		_item_index = 0
	else:
		var count: int = _candidates().size()
		if count > 0:
			_item_index = wrapi(_item_index + step, 0, count)
	_redraw()


func _focus_items() -> void:
	if _candidates().is_empty():
		return
	_column = Column.ITEMS
	_item_index = clampi(_item_index, 0, _candidates().size() - 1)
	_redraw()


## `interact` means "equip this" in the item column and "take this off" in the
## slot column. Unequipping a weapon slot is refused by `Inventory` rather than
## by the screen, so the rule has one home.
func _confirm() -> void:
	if _column == Column.ITEMS:
		var item: Item = _highlighted()
		if item != null:
			Inventory.equip(item.id)
	else:
		Inventory.unequip(_slot())
	_redraw()


# --- Drawing ----------------------------------------------------------------

func _redraw() -> void:
	if not visible:
		return
	_draw_slots()
	_draw_sheet()
	_draw_items()
	_draw_detail()
	_hint.text = (
		"[W/S] choose   [D] items   [A] slots   [E] equip / take off   [I] close"
	)


func _draw_slots() -> void:
	_clear(_slot_rows)
	for index: int in SLOT_ORDER.size():
		var slot: Item.Slot = SLOT_ORDER[index]
		var equipped: Item = Inventory.equipped(slot)
		var selected: bool = index == _slot_index
		var row := _row(_slot_rows)
		_cell(row, Item.slot_name(slot), 170.0, COL_SELECTED if selected else COL_DIM)
		_cell(
			row,
			equipped.display_name if equipped != null else "—",
			420.0,
			COL_ACCENT if selected else COL_TEXT
		)


func _draw_sheet() -> void:
	# The whole sheet, from the same dictionary the HUD reads.
	var sheet: Dictionary = PlayerStats.as_dictionary()
	_clear(_sheet_rows)
	_pair("LVL", "%d" % int(sheet["level"]))
	_pair("XP", "%d / %d" % [int(sheet["xp_into_level"]), int(sheet["xp_for_level"])])
	_pair("HP", "%d" % int(sheet["max_hp"]))
	_pair("RAM", "%d" % int(sheet["max_ram"]))
	_pair("STR", "%d" % int(sheet["str"]))
	_pair("DEX", "%d" % int(sheet["dex"]))
	_pair("INT", "%d" % int(sheet["int"]))
	_pair("DEF", "%d" % int(sheet["def"]))
	_pair("CREDITS", "%d" % int(sheet["credits"]))


func _draw_items() -> void:
	_clear(_item_rows)
	var items: Array[Item] = _candidates()
	if items.is_empty():
		_cell(_row(_item_rows), "nothing yet", 520.0, COL_DIM)
		return
	var equipped: Item = Inventory.equipped(_slot())
	for index: int in items.size():
		var item: Item = items[index]
		var selected: bool = _column == Column.ITEMS and index == _item_index
		var row := _row(_item_rows)
		_cell(row, "▸" if selected else " ", 30.0, COL_SELECTED)
		_cell(row, item.display_name, 420.0, COL_ACCENT if selected else COL_TEXT)
		_cell(row, "equipped" if item == equipped else "", 140.0, COL_DIM)


func _draw_detail() -> void:
	var item: Item = _highlighted()
	_clear(_detail)
	if item == null:
		_detail_title.text = "EMPTY SLOT"
		_detail_body.text = ""
		return
	_detail_title.text = item.display_name.to_upper()
	_detail_body.text = item.description
	for line: Array in _delta_lines(item):
		_delta_row(line[0], line[1], line[2], bool(line[3]))


## What equipping `candidate` would do, against what is equipped now, on only
## the axes that item touches. Unchanged axes are omitted: a wall of arrows
## pointing at nothing buries the one line that moved.
##
## Every value is computed the way the pipeline computes it — `damage_at()` is
## step 4, `total_defense()` is what step 6 subtracts.
func _delta_lines(candidate: Item) -> Array:
	var current: Item = Inventory.equipped(candidate.slot)
	var lines: Array = []

	if candidate is Weapon:
		var stat: int = (
			PlayerStats.dexterity() if candidate.slot == Item.Slot.RANGED
			else PlayerStats.strength()
		)
		var new_weapon: Weapon = candidate
		var old_weapon: Weapon = current as Weapon
		lines.append([
			"DMG/HIT",
			"%d" % (old_weapon.damage_at(stat, _config) if old_weapon != null else 0),
			"%d" % new_weapon.damage_at(stat, _config),
			new_weapon.damage_at(stat, _config)
				>= (old_weapon.damage_at(stat, _config) if old_weapon != null else 0),
		])
		lines.append([
			"DPS",
			"%.1f" % (old_weapon.dps_at(stat, _config) if old_weapon != null else 0.0),
			"%.1f" % new_weapon.dps_at(stat, _config),
			new_weapon.dps_at(stat, _config)
				>= (old_weapon.dps_at(stat, _config) if old_weapon != null else 0.0),
		])
		lines.append([
			"ATK SPEED",
			"%.1f/s" % (old_weapon.attack_speed if old_weapon != null else 0.0),
			"%.1f/s" % new_weapon.attack_speed,
			new_weapon.attack_speed >= (old_weapon.attack_speed if old_weapon != null else 0.0),
		])
		if candidate is RangedWeapon:
			var new_ranged: RangedWeapon = candidate
			var old_ranged: RangedWeapon = current as RangedWeapon
			lines.append([
				"ENERGY/SHOT",
				"%d" % (old_ranged.energy_per_shot if old_ranged != null else 0),
				"%d" % new_ranged.energy_per_shot,
				new_ranged.energy_per_shot
					<= (old_ranged.energy_per_shot if old_ranged != null else 99),
			])
		return lines

	var piece: Clothing = candidate
	var worn: Clothing = current as Clothing
	var current_def: int = worn.defense if worn != null else 0
	lines.append([
		"DEF",
		"%d" % Inventory.total_defense(),
		"%d" % (Inventory.total_defense() - current_def + piece.defense),
		piece.defense >= current_def,
	])
	if piece.max_hp_bonus != 0:
		lines.append([
			"MAX HP",
			"%d" % PlayerStats.effective_max_hp(),
			"%d" % (PlayerStats.effective_max_hp()
				- (worn.max_hp_bonus if worn != null else 0) + piece.max_hp_bonus),
			true,
		])
	if not is_equal_approx(piece.dash_cooldown_mult, 1.0):
		var movement: MovementConfig = load("res://src/player/movement_config.tres")
		lines.append([
			"DASH CD",
			"%.2fs" % PlayerStats.effective_dash_cooldown(movement.dash_cooldown),
			"%.2fs" % (movement.dash_cooldown * piece.dash_cooldown_mult),
			piece.dash_cooldown_mult <= 1.0,
		])
	if not is_equal_approx(piece.ram_regen_mult, 1.0):
		lines.append([
			"RAM REGEN",
			"%d%%" % roundi(Inventory.ram_regen_mult() * 100.0),
			"%d%%" % roundi(piece.ram_regen_mult * 100.0),
			piece.ram_regen_mult >= 1.0,
		])
	if piece.melee_energy_bonus != 0:
		var melee: MeleeWeapon = Inventory.equipped_melee()
		lines.append([
			"ENERGY/MELEE HIT",
			"%d" % PlayerStats.effective_ammo_on_hit(melee),
			"%d" % ((melee.ammo_on_hit if melee != null else 0) + piece.melee_energy_bonus),
			true,
		])
	return lines


# --- Construction -----------------------------------------------------------

func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.04, 0.05, 0.08, 0.92)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 90)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)

	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 18)
	margin.add_child(page)

	page.add_child(_title("LOADOUT"))

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 60)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(columns)

	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 26)
	left.custom_minimum_size.x = 620.0
	columns.add_child(left)
	_slot_rows = VBoxContainer.new()
	left.add_child(_slot_rows)
	left.add_child(_title("SHEET", 22))
	_sheet_rows = VBoxContainer.new()
	left.add_child(_sheet_rows)

	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 26)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(right)
	right.add_child(_title("FITS THIS SLOT", 22))
	_item_rows = VBoxContainer.new()
	right.add_child(_item_rows)

	_detail_title = _title("", 26)
	right.add_child(_detail_title)
	_detail_body = Label.new()
	_detail_body.add_theme_font_size_override("font_size", 20)
	_detail_body.add_theme_color_override("font_color", COL_DIM)
	_detail_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_body.custom_minimum_size.x = 700.0
	right.add_child(_detail_body)
	_detail = VBoxContainer.new()
	right.add_child(_detail)

	_hint = Label.new()
	_hint.add_theme_font_size_override("font_size", 19)
	_hint.add_theme_color_override("font_color", COL_DIM)
	page.add_child(_hint)


func _title(text: String, size: int = 34) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", COL_ACCENT)
	return label


func _row(parent: Node) -> HBoxContainer:
	var row := HBoxContainer.new()
	parent.add_child(row)
	return row


## Fixed-width cells rather than padded strings: the default font is
## proportional, so `%-14s` would line nothing up.
func _cell(parent: Node, text: String, width: float, colour: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size.x = width
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", colour)
	parent.add_child(label)
	return label


func _pair(key: String, value: String) -> void:
	var row := _row(_sheet_rows)
	_cell(row, key, 170.0, COL_DIM)
	_cell(row, value, 200.0, COL_TEXT)


func _delta_row(axis: String, from: String, to: String, better: bool) -> void:
	var row := _row(_detail)
	_cell(row, axis, 260.0, COL_DIM)
	_cell(row, from, 110.0, COL_TEXT)
	_cell(row, "→", 40.0, COL_DIM)
	_cell(row, to, 110.0, COL_BETTER if better else COL_WORSE)


func _clear(container: Node) -> void:
	for child: Node in container.get_children():
		container.remove_child(child)
		child.queue_free()
