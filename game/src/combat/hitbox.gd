class_name Hitbox
extends Area2D
## The delivering half of the shared component pair (DESIGN.md §3.2).
##
## Owns steps 1–2: find overlapping hurtboxes, and refuse to hit the same
## target twice with the same swing.
##
## Multi-hit rejection is a **per-attack-instance target set, not a cooldown
## timer**. Any timer long enough to stop the wrench double-hitting is also
## long enough to throttle the 4/s nailgun and quietly delete the fast
## weapons' identity; a set scoped to the swing is correct at 0.5/s and at 4/s
## with no per-weapon tuning at all. M6's lingering boss hitboxes get this
## behaviour for free.

signal hit_landed(hurtbox: Hurtbox, result: DamageResult)

## Contact damage is a continuous condition, not a swing, so its box clears
## the target set every frame and lets the victim's i-frames do the rate
## limiting instead. Leave this off for anything with a windup: a swing that
## re-hits is a swing that multi-hits.
@export var continuous: bool = false

## The attack delivered on contact. Set by whoever activates this box.
var attack: Attack = null

var _active: bool = false
var _already_hit: Dictionary = {}


func _ready() -> void:
	monitoring = false
	monitorable = false
	set_physics_process(false)


## Arm the box with an attack. Clears the target set, so re-activating is a
## genuinely new swing that may hit the same target again.
func activate(new_attack: Attack) -> void:
	attack = new_attack
	_already_hit.clear()
	_active = true
	monitoring = true
	set_physics_process(true)


func deactivate() -> void:
	_active = false
	attack = null
	_already_hit.clear()
	monitoring = false
	set_physics_process(false)


func is_active() -> bool:
	return _active


## Swept every physics frame rather than driven by `area_entered`, so a target
## that was already inside the box when it armed is hit just like one that
## walks in afterwards. The target set is what makes the sweep safe to repeat.
func _physics_process(_delta: float) -> void:
	if not _active or attack == null:
		return
	if continuous:
		_already_hit.clear()
	for area: Area2D in get_overlapping_areas():
		# The overlap list is a snapshot, and a single hit can disarm the box
		# midway through it: a projectile expires on its first resolved
		# contact and takes its attack with it. Re-ask every step instead of
		# trusting the check above for the whole sweep.
		if not _active or attack == null:
			return
		if area is Hurtbox:
			_try_hit(area as Hurtbox)


func _try_hit(hurtbox: Hurtbox) -> void:
	# Step 2 — this swing already hit this target.
	var key: int = hurtbox.get_instance_id()
	if _already_hit.has(key):
		return
	# Never hit the thing that swung.
	if hurtbox.get_parent() == attack.source:
		return

	attack.origin = global_position
	var result: DamageResult = hurtbox.receive(attack)
	if result.rejection == DamageResult.Rejection.ALREADY_HIT:
		return

	# Consume the target on any *resolved* outcome, including a shield or an
	# i-frame window. Retrying every frame against an invulnerable target
	# would spam the pipeline for the whole swing to no effect.
	_already_hit[key] = true
	if result.landed:
		hit_landed.emit(hurtbox, result)
