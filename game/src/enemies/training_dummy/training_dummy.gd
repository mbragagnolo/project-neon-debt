class_name TrainingDummy
extends CharacterBody2D
## A post that reports what the pipeline did to it (M2 combat gym).
##
## Not a roster entry and never shipped in a room — the Scav is the first real
## enemy. This exists so hit-feel can be judged with nothing fighting back,
## the same way the M1 gym let movement be judged in an empty room.
##
## It is deliberately readable rather than dangerous: it prints the damage it
## took, shows its hp, takes knockback so the impulse is visible, walks back to
## its post so the next swing starts from the same place, and comes back to
## life on a timer so a tuning session is never interrupted by a corpse.

const RETURN_DEADZONE := 2.0

@export_group("Stat block")
## The reduced enemy stat block (docs/rpg/stats-and-curves.md), mirrored onto
## the `Health` child at ready.
##
## Exported on the root rather than configured on the child because the gym
## generator has to set these from code: `PackedScene.pack()` is reliable about
## overrides on an instance root and fragile about overrides reached *inside*
## an instance, and a dummy whose DEF silently reverted to 0 would look like a
## pipeline bug rather than a scene bug.
@export var max_hp: int = 40
## M2 ships every enemy at 0 — the locked tuning warning sets enemy DEF last,
## after weapon numbers exist. The gym raises it to feel the flat-DEF bias.
@export var defense: int = 0
## Single-hit damage needed to interrupt. 1 = everything staggers.
@export var stagger_threshold: int = 1
## Binary resistance tags, mirrored onto `Health`. The hack gym uses
## `mechanical` (Breach stuns it) and `immune_ranged_frontal` (shots ping off,
## Overload does not) so both halves of hacks.md rule 4 can be felt before M6
## ships an enemy that carries them.
@export var tags: Array[StringName] = []

@export_group("Post")
## px/s it walks back to its anchor at. Slow enough to read as recovering.
@export var return_speed: float = 90.0
## Seconds before a dead dummy stands back up. 0 leaves it down.
@export var respawn_delay: float = 1.5

@export_group("Contact damage")
## Enemies deal contact damage at half `attack_power`
## (docs/characters/enemies.md). Off by default: hit-feel first, then turn this
## on to feel i-frames and the spacing pressure they make fair.
@export var hurts_on_contact: bool = false
## Flat, like every enemy — no stat multiplier on the enemy side.
@export var attack_power: float = 6.0

@export_group("Readout")
@export var show_damage_numbers: bool = true

@onready var health: Health = $Health
@onready var _visual: ColorRect = $Visual
@onready var _hp_label: Label = $HpLabel
@onready var _contact_hitbox: Hitbox = $ContactHitbox

## +1 right, -1 left. Exported so the gym can turn the shielded dummy toward
## the player: `immune_ranged_frontal` needs a front to be immune from.
@export var facing: int = 1

var _anchor: Vector2 = Vector2.ZERO
var _respawn_timer: float = 0.0
var _stun_timer: float = 0.0
var _stun_label: Label
var _gravity: float = 0.0
var _config: CombatConfig
var _base_color: Color = Color.WHITE


func _ready() -> void:
	_anchor = global_position
	_gravity = float(ProjectSettings.get_setting("physics/2d/default_gravity", 980.0))
	_config = load("res://src/combat/combat_config.tres") as CombatConfig

	add_to_group(&"enemies")
	health.max_hp = max_hp
	health.defense = defense
	health.stagger_threshold = stagger_threshold
	health.tags = tags
	# Health._ready has already run (children first), so its hp is sized to the
	# scene default; restore it against the numbers we just set.
	health.restore()

	_base_color = _visual.color

	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	_refresh_label()

	if hurts_on_contact:
		_arm_contact()


func _physics_process(delta: float) -> void:
	if health.is_dead():
		_tick_respawn(delta)
		return

	if _stun_timer > 0.0:
		_stun_timer -= delta
		if _stun_timer <= 0.0:
			_end_stun()

	velocity.y += _gravity * delta

	# Knockback bleeds off through friction rather than being cancelled, so the
	# impulse the pipeline applied stays legible all the way through.
	velocity.x = move_toward(velocity.x, 0.0, 1200.0 * delta)

	if is_on_floor() and absf(velocity.x) < return_speed:
		var offset: float = _anchor.x - global_position.x
		if absf(offset) > RETURN_DEADZONE:
			velocity.x = signf(offset) * return_speed
		else:
			velocity.x = 0.0

	move_and_slide()


## Called by our `Hurtbox` at step 9. Full magnitude on a staggering hit, a
## quarter of it on a flinch — which is the only way `stagger_threshold` is
## visible without a scrap of UI.
func apply_knockback(impulse: Vector2) -> void:
	velocity += impulse


func reset() -> void:
	health.restore()
	global_position = _anchor
	velocity = Vector2.ZERO
	_visual.modulate.a = 1.0
	_respawn_timer = 0.0
	if _stun_timer > 0.0:
		_end_stun()
	_refresh_label()


# --- Hacks ------------------------------------------------------------------

## Breach's hook, same contract as `Enemy.stun()`: only a `mechanical` dummy
## answers, and while stunned it stops hurting on contact.
func stun(seconds: float) -> bool:
	if health.is_dead() or not health.tags.has(Health.TAG_MECHANICAL):
		return false
	_stun_timer = seconds
	_contact_hitbox.deactivate()
	_visual.color = Color(0.3, 0.55, 0.7)
	if _stun_label == null:
		_stun_label = Label.new()
		_stun_label.text = "STUNNED"
		_stun_label.add_theme_font_size_override("font_size", 20)
		_stun_label.modulate = Color(0.55, 1.0, 0.5)
		_stun_label.position = Vector2(-50.0, -172.0)
		add_child(_stun_label)
	_stun_label.visible = true
	return true


func is_stunned() -> bool:
	return _stun_timer > 0.0


func _end_stun() -> void:
	_stun_timer = 0.0
	_visual.color = _base_color
	if _stun_label != null:
		_stun_label.visible = false
	if hurts_on_contact and not health.is_dead():
		_arm_contact()


func _tick_respawn(delta: float) -> void:
	if respawn_delay <= 0.0:
		return
	_respawn_timer -= delta
	if _respawn_timer <= 0.0:
		reset()


func _on_damaged(amount: int, _attack: Attack) -> void:
	_refresh_label()
	_flash()
	if show_damage_numbers:
		_spawn_damage_number(amount)


## Confirmation that the hit connected, on the body that took it.
##
## Tweened through `color` rather than `modulate`, because `modulate` is
## already carrying the death dim and the two would fight over the same
## channel — the corpse would flicker back to full brightness every time a
## stray projectile landed on it.
func _flash() -> void:
	var tween := create_tween()
	_visual.color = Color(1.0, 1.0, 1.0)
	tween.tween_property(_visual, "color", _base_color, 0.12)


func _on_died() -> void:
	_respawn_timer = respawn_delay
	_visual.modulate.a = 0.25
	_refresh_label()


func _refresh_label() -> void:
	_hp_label.text = "%d / %d" % [health.hp, health.max_hp]


## Gym diagnostics, not juice. M7's damage numbers are a real UI feature that
## hangs off `Events.damage_dealt`; this is a label that floats up so a tuning
## session can see the arithmetic without reading a log.
func _spawn_damage_number(amount: int) -> void:
	var label := Label.new()
	label.text = str(amount)
	label.z_index = 10
	label.add_theme_font_size_override("font_size", 28)
	# Floor-1 hits are the "wrong tool" signal, so they read differently.
	label.modulate = Color(1.0, 0.45, 0.45) if amount <= 1 else Color(1.0, 0.95, 0.4)
	add_child(label)
	label.position = Vector2(randf_range(-24.0, 24.0), -150.0)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 70.0, 0.7)
	tween.tween_property(label, "modulate:a", 0.0, 0.7).set_delay(0.2)
	tween.chain().tween_callback(label.queue_free)


func _arm_contact() -> void:
	var attack := Attack.make(self, global_position, attack_power * _contact_mult())
	attack.scales_with_stat = false
	attack.is_contact = true
	_contact_hitbox.activate(attack)


func _contact_mult() -> float:
	return _config.contact_damage_mult if _config != null else 0.5
