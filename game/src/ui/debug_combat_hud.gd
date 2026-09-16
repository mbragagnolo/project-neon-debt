extends CanvasLayer
## Gym-only readout, grown one milestone at a time (src/ui/README.md).
##
## M2 put HP, ammo and the last damage number on screen, because the
## melee→ammo interlock is the spine of the intertwined kit and you cannot
## tune "one wrench hit buys one zipgun shot" by feel if the pool is
## imaginary.
##
## M3 adds the four lines its exit test needs to be observable without opening
## a menu — level, XP, credits, and DEF folded into the HP line — plus the
## level-up moment and pickup toasts. No new signal was invented for any of
## it: every one was declared on the bus in M0 (docs/ui/screens.md).
##
## Reads the signal bus only. It holds no references to the player, so dropping
## it into any room is safe and deleting it breaks nothing.

const OK_COLOUR := Color(0.6, 0.95, 1.0)
const LOW_COLOUR := Color(1.0, 0.45, 0.45)
const DIM_COLOUR := Color(0.45, 0.52, 0.64)
const GOOD_COLOUR := Color(0.45, 0.95, 0.6)

const HACK_COLOUR := Color(0.75, 0.6, 1.0)

var _boss_label: Label
var _level_label: Label
var _hp_label: Label
var _ammo_label: Label
var _ram_label: Label
var _hack_label: Label
var _credits_label: Label
var _last_hit_label: Label
var _toast_label: Label

var _hit_clear_timer: float = 0.0
var _toast_timer: float = 0.0
var _hack_flash_timer: float = 0.0
var _guard_timer: float = 0.0
var _selected_hack: StringName = &""
var _catalog: HackCatalog
## Last published sheet, kept because the HP line draws DEF beside the bar and
## the two arrive on different signals.
var _sheet: Dictionary = {}


func _ready() -> void:
	layer = 10
	var box := VBoxContainer.new()
	box.position = Vector2(32.0, 24.0)
	add_child(box)

	_boss_label = _make_label(box, "", LOW_COLOUR)
	_level_label = _make_label(box, "LVL —")
	_hp_label = _make_label(box, "HP —")
	_ammo_label = _make_label(box, "AMMO —")
	_ram_label = _make_label(box, "RAM —", HACK_COLOUR)
	_hack_label = _make_label(box, "HACK —", HACK_COLOUR)
	_credits_label = _make_label(box, "CR 0", DIM_COLOUR)
	_last_hit_label = _make_label(box, "")
	_toast_label = _make_label(box, "", GOOD_COLOUR)

	Events.hp_changed.connect(_on_hp_changed)
	Events.ammo_changed.connect(_on_ammo_changed)
	Events.damage_dealt.connect(_on_damage_dealt)
	Events.stats_changed.connect(_on_stats_changed)
	Events.credits_changed.connect(_on_credits_changed)
	Events.level_gained.connect(_on_level_gained)
	Events.toast_requested.connect(_on_toast)
	Events.ram_changed.connect(_on_ram_changed)
	Events.hack_selected.connect(_on_hack_selected)
	Events.hack_cast.connect(_on_hack_cast)
	Events.hack_failed.connect(_on_hack_failed)
	Events.hack_acquired.connect(_on_hack_acquired)
	Events.guard_changed.connect(_on_guard_changed)
	Events.boss_hp_changed.connect(_on_boss_hp_changed)
	Events.boss_defeated.connect(_on_boss_defeated)
	Events.room_exited.connect(_on_room_exited)
	_catalog = load(HackKit.CATALOG_PATH)

	# The bus carries no history, so a HUD built after the sheet was published
	# would start blank until something happened. Ask once.
	_on_stats_changed(PlayerStats.as_dictionary())
	var player: Node = get_tree().get_first_node_in_group(&"player")
	if player != null and player.has_method(&"publish_vitals"):
		player.call(&"publish_vitals")


func _process(delta: float) -> void:
	if _hit_clear_timer > 0.0:
		_hit_clear_timer -= delta
		if _hit_clear_timer <= 0.0:
			_last_hit_label.text = ""
	if _toast_timer > 0.0:
		_toast_timer -= delta
		if _toast_timer <= 0.0:
			_toast_label.text = ""
	if _hack_flash_timer > 0.0:
		_hack_flash_timer -= delta
		if _hack_flash_timer <= 0.0:
			_draw_hack_line()
	if _guard_timer > 0.0:
		_guard_timer -= delta
		_draw_hack_line()


func _make_label(parent: Node, text: String, colour: Color = OK_COLOUR) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 30)
	label.add_theme_color_override("font_color", colour)
	parent.add_child(label)
	return label


func _on_hp_changed(current: int, maximum: int) -> void:
	var defense: int = int(_sheet.get("def", 0))
	_hp_label.text = "HP  %d / %d    DEF %d" % [current, maximum, defense]
	var colour: Color = LOW_COLOUR if current <= maximum / 4 else OK_COLOUR
	_hp_label.add_theme_color_override("font_color", colour)


func _on_ammo_changed(current: int, maximum: int) -> void:
	_ammo_label.text = "AMMO  %d / %d" % [current, maximum]
	var colour: Color = LOW_COLOUR if current <= 0 else OK_COLOUR
	_ammo_label.add_theme_color_override("font_color", colour)


func _on_damage_dealt(target: Node, amount: int, _source: Node) -> void:
	var target_name: String = target.name if target != null else "?"
	_last_hit_label.text = "LAST HIT  %d  →  %s" % [amount, target_name]
	_hit_clear_timer = 1.5


func _on_stats_changed(sheet: Dictionary) -> void:
	_sheet = sheet
	_level_label.text = "LVL %d    XP %d / %d" % [
		int(sheet.get("level", 1)),
		int(sheet.get("xp_into_level", 0)),
		int(sheet.get("xp_for_level", 0)),
	]
	_credits_label.text = "CR %d" % int(sheet.get("credits", 0))
	# DEF lives on the HP line; redraw it with whatever HP currently reads.
	if _hp_label.text.begins_with("HP  "):
		var parts: PackedStringArray = _hp_label.text.split("    DEF")
		_hp_label.text = "%s    DEF %d" % [parts[0], int(sheet.get("def", 0))]


func _on_credits_changed(amount: int) -> void:
	_credits_label.text = "CR %d" % amount


## The level-up moment, in greybox form: the full heal is the player's, this is
## the announcement. M7's version is a flourish; the signal it hangs off is
## already the right one.
func _on_level_gained(new_level: int) -> void:
	_toast_label.text = "LEVEL UP  →  %d" % new_level
	_toast_timer = 2.5


func _on_toast(text: String) -> void:
	_toast_label.text = text
	_toast_timer = 2.5


# --- M4: RAM and the quickslot ----------------------------------------------

func _on_ram_changed(current: int, maximum: int) -> void:
	_ram_label.text = "RAM  %d / %d" % [current, maximum]
	_ram_label.add_theme_color_override("font_color", LOW_COLOUR if current <= 0 else HACK_COLOUR)


func _on_hack_selected(hack_id: StringName) -> void:
	_selected_hack = hack_id
	_draw_hack_line()


func _hack_name(hack_id: StringName) -> String:
	var hack: Hack = _catalog.by_id(hack_id) if _catalog != null else null
	return hack.display_name.to_upper() if hack != null else "—"


func _hack_cost(hack_id: StringName) -> int:
	var hack: Hack = _catalog.by_id(hack_id) if _catalog != null else null
	return hack.ram_cost if hack != null else 0


## The quickslot: what fires on `hack_cast`, what it costs, and the cycle
## keys. Firewall's remaining window is appended while it is up.
func _draw_hack_line() -> void:
	var text: String = "HACK  %s %s %s   %d RAM" % [
		InputPrompt.label(&"hack_prev"),
		_hack_name(_selected_hack),
		InputPrompt.label(&"hack_next"),
		_hack_cost(_selected_hack),
	]
	if _guard_timer > 0.0:
		text += "   FIREWALL %.1fs" % _guard_timer
	_hack_label.text = text
	_hack_label.add_theme_color_override("font_color", HACK_COLOUR)


func _on_hack_cast(hack_id: StringName, _ram_cost: int) -> void:
	_hack_label.text = "HACK  %s  CAST" % _hack_name(hack_id)
	_hack_label.add_theme_color_override("font_color", GOOD_COLOUR)
	_hack_flash_timer = 0.5


func _on_hack_failed(hack_id: StringName, reason: StringName) -> void:
	var why: String
	match reason:
		&"ram": why = "NO RAM"
		&"cooldown": why = "COOLING"
		&"no_target": why = "NO TARGET IN REACH"
		&"no_deck": why = "NO DECK - CANNOT CYCLE"
		_: why = "NO PROGRAM"
	_hack_label.text = "HACK  %s  %s" % [_hack_name(hack_id), why]
	_hack_label.add_theme_color_override("font_color", LOW_COLOUR)
	_hack_flash_timer = 0.8


func _on_hack_acquired(hack_id: StringName) -> void:
	_toast_label.text = "PROGRAM ACQUIRED  →  %s" % _hack_name(hack_id)
	_toast_timer = 2.5


func _on_guard_changed(active: bool, seconds: float) -> void:
	_guard_timer = seconds if active else 0.0
	_draw_hack_line()


# --- M6: the boss ---------------------------------------------------------------

func _on_boss_hp_changed(display_name: String, hp: int, max_hp: int) -> void:
	var filled: int = int(round(20.0 * float(hp) / float(maxi(max_hp, 1))))
	_boss_label.text = "%s  [%s%s]  %d / %d" % [
		display_name.to_upper(), "█".repeat(filled), "·".repeat(20 - filled), hp, max_hp
	]


func _on_boss_defeated(_boss: Node) -> void:
	_boss_label.text = ""


func _on_room_exited(_room_id: StringName) -> void:
	_boss_label.text = ""
