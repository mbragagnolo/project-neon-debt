extends CanvasLayer
## Gym-only readout for the M2 tuning session.
##
## The real HUD is M7's, and it will hang off exactly these signals. This one
## exists because the melee→ammo interlock is the spine of the intertwined kit
## and it is completely invisible without a number on screen: you cannot tune
## "one wrench hit buys one zipgun shot" by feel if the pool is imaginary.
##
## Reads the signal bus only. It holds no references to the player, so dropping
## it into any room is safe and deleting it breaks nothing.

const OK_COLOUR := Color(0.6, 0.95, 1.0)
const LOW_COLOUR := Color(1.0, 0.45, 0.45)

var _hp_label: Label
var _ammo_label: Label
var _last_hit_label: Label
var _hit_clear_timer: float = 0.0


func _ready() -> void:
	layer = 10
	var box := VBoxContainer.new()
	box.position = Vector2(32.0, 24.0)
	add_child(box)

	_hp_label = _make_label(box, "HP —")
	_ammo_label = _make_label(box, "AMMO —")
	_last_hit_label = _make_label(box, "")

	Events.hp_changed.connect(_on_hp_changed)
	Events.ammo_changed.connect(_on_ammo_changed)
	Events.damage_dealt.connect(_on_damage_dealt)


func _process(delta: float) -> void:
	if _hit_clear_timer <= 0.0:
		return
	_hit_clear_timer -= delta
	if _hit_clear_timer <= 0.0:
		_last_hit_label.text = ""


func _make_label(parent: Node, text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 30)
	label.add_theme_color_override("font_color", OK_COLOUR)
	parent.add_child(label)
	return label


func _on_hp_changed(current: int, maximum: int) -> void:
	_hp_label.text = "HP  %d / %d" % [current, maximum]
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
