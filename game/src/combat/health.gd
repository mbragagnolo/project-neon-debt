class_name Health
extends Node
## HP, DEF, stagger threshold and resistance tags for one combatant.
##
## A component, not a base class — the player is a `CharacterBody2D`, a dummy
## is a `CharacterBody2D`, M6's boss will be something else again, and none of
## them should have to inherit from each other to be hittable.
##
## Owns no pipeline logic. It answers questions the pipeline asks (am I dead,
## am I invulnerable, does this tag stop this attack) and applies the number
## the pipeline hands back.

signal damaged(amount: int, attack: Attack)
signal staggered()
signal healed(amount: int)
signal died()

## Binary tags, never percentages — at this number scale a "30% resist" is
## invisible, and tags are what a player can read mid-fight
## (docs/rpg/stats-and-curves.md, enemy stat block).
const TAG_MECHANICAL := &"mechanical"
const TAG_IMMUNE_RANGED_FRONTAL := &"immune_ranged_frontal"

@export var max_hp: int = 40
## Flat subtraction, applied at step 6. M2 ships every enemy at 0 — the locked
## tuning warning sets enemy DEF last, after weapon numbers exist.
@export var defense: int = 0
## Single-hit damage needed to interrupt this combatant into stagger. 1 means
## "anything staggers me" (the Scav); 12 means "only heavy hits" (M6's Riot
## unit).
@export var stagger_threshold: int = 1
## Seconds of invulnerability granted on hurt. The player uses this; enemies
## leave it at 0 and rely on per-swing multi-hit rejection instead, so a timer
## here can never silently throttle the nailgun's fire rate.
@export var iframe_time: float = 0.0
@export var tags: Array[StringName] = []

var hp: int = 0

var _iframe_timer: float = 0.0


func _ready() -> void:
	hp = max_hp


func _physics_process(delta: float) -> void:
	# Uses the scaled delta on purpose: during hitstop the engine's time scale
	# is zero, so this does not tick. Hitstop that eats i-frames would be a
	# stealth difficulty spike (spec, hitstop rule 3).
	_iframe_timer = maxf(_iframe_timer - delta, 0.0)


func is_dead() -> bool:
	return hp <= 0


func is_invulnerable() -> bool:
	return _iframe_timer > 0.0


## Step 5. Positional immunity is checked *before* DEF so a blocked hit is
## rejected outright rather than reduced to the floor of 1 — otherwise the
## shield leaks chip damage and the tag reads as a lie.
func blocks(attack: Attack) -> bool:
	if not attack.is_ranged:
		return false
	if not tags.has(TAG_IMMUNE_RANGED_FRONTAL):
		return false
	return _is_frontal(attack.origin)


## True when `from` is on the side this combatant is facing. A combatant with
## no facing (a dummy, a turret) is frontal from everywhere.
func _is_frontal(from: Vector2) -> bool:
	var body := get_parent()
	if body == null or not (body is Node2D):
		return true
	var facing: int = 1
	if &"facing" in body:
		facing = int(body.get(&"facing"))
	if facing == 0:
		return true
	var delta_x: float = from.x - (body as Node2D).global_position.x
	if is_zero_approx(delta_x):
		return true
	return signf(delta_x) == signf(float(facing))


## Applies an already-resolved damage number. The pipeline decides how big it
## is; this only decides what happens to hp.
func apply_damage(amount: int, attack: Attack) -> void:
	if is_dead():
		return
	hp = maxi(hp - amount, 0)
	damaged.emit(amount, attack)
	if amount >= stagger_threshold:
		staggered.emit()
	if hp <= 0:
		died.emit()


func heal(amount: int) -> void:
	if amount <= 0:
		return
	var before: int = hp
	hp = mini(hp + amount, max_hp)
	if hp != before:
		healed.emit(hp - before)


func grant_iframes(seconds: float) -> void:
	_iframe_timer = maxf(_iframe_timer, seconds)


func clear_iframes() -> void:
	_iframe_timer = 0.0


func restore() -> void:
	hp = max_hp
	_iframe_timer = 0.0
