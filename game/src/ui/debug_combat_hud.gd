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

var _level_label: Label
var _hp_label: Label
var _ammo_label: Label
var _credits_label: Label
var _last_hit_label: Label
var _toast_label: Label

var _hit_clear_timer: float = 0.0
var _toast_timer: float = 0.0
## Last published sheet, kept because the HP line draws DEF beside the bar and
## the two arrive on different signals.
var _sheet: Dictionary = {}


func _ready() -> void:
	layer = 10
	var box := VBoxContainer.new()
	box.position = Vector2(32.0, 24.0)
	add_child(box)

	_level_label = _make_label(box, "LVL —")
	_hp_label = _make_label(box, "HP —")
	_ammo_label = _make_label(box, "AMMO —")
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

	# The bus carries no history, so a HUD built after the sheet was published
	# would start blank until something happened. Ask once.
	_on_stats_changed(PlayerStats.as_dictionary())


func _process(delta: float) -> void:
	if _hit_clear_timer > 0.0:
		_hit_clear_timer -= delta
		if _hit_clear_timer <= 0.0:
			_last_hit_label.text = ""
	if _toast_timer > 0.0:
		_toast_timer -= delta
		if _toast_timer <= 0.0:
			_toast_label.text = ""


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
