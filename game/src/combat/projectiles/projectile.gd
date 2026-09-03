class_name Projectile
extends Hitbox
## A shot in flight. Extends `Hitbox` because that is exactly what it is: a
## hitbox that moves and expires, carrying its attack away from the gun that
## fired it.
##
## V1 keeps these deliberately simple (docs/rpg/items.md): single projectiles,
## no spread, no pierce, no damage falloff. Range is just how far it gets
## before its lifetime runs out, which is one number instead of a curve.

## Emitted when the shot ends for any reason — hit, wall or timeout.
signal expired()

var velocity: Vector2 = Vector2.ZERO
## px/s² of drop. Zero for everything but the rivet gun (docs/rpg/items.md).
## Named `drop` rather than `gravity` because `Area2D` already owns that name
## — and its `gravity` is the area's *effect on other bodies*, which is not
## remotely this.
var drop: float = 0.0

var _life: float = 0.0
var _visual: ColorRect


func _ready() -> void:
	super()
	# Lifetime is the range limit, so the shot must keep ticking even before
	# anything is overlapping it.
	set_physics_process(true)


## Arm, aim and release in one call. `direction` is expected normalised.
func launch(
	new_attack: Attack,
	direction: Vector2,
	speed: float,
	lifetime: float,
	size: Vector2,
	colour: Color,
	drop_rate: float = 0.0
) -> void:
	activate(new_attack)
	velocity = direction * speed
	drop = drop_rate
	_life = lifetime
	rotation = direction.angle()
	_build_shape(size)
	_build_visual(size, colour)


func _physics_process(delta: float) -> void:
	# The inherited sweep is steps 1–2; movement and expiry are ours.
	super(delta)
	if not is_active():
		return

	if not is_zero_approx(drop):
		velocity.y += drop * delta
		# The sprite follows the arc rather than the aim, so what the shot
		# looks like is where it is actually going.
		rotation = velocity.angle()
	position += velocity * delta

	_life -= delta
	if _life <= 0.0:
		_expire()
		return

	# Walls stop shots. Masking the world layer alongside hurtboxes means one
	# area answers both questions.
	if not get_overlapping_bodies().is_empty():
		_expire()


func _try_hit(hurtbox: Hurtbox) -> void:
	super(hurtbox)
	# No pierce in V1: the first resolved contact ends the shot, whether it
	# damaged, was shielded, or met an i-frame window.
	if not _already_hit.is_empty():
		_expire()


func _expire() -> void:
	if not is_active():
		return
	deactivate()
	expired.emit()
	queue_free()


func _build_shape(size: Vector2) -> void:
	var rect := RectangleShape2D.new()
	rect.size = size
	var collider := CollisionShape2D.new()
	collider.shape = rect
	add_child(collider)


func _build_visual(size: Vector2, colour: Color) -> void:
	_visual = ColorRect.new()
	_visual.color = colour
	_visual.size = size
	_visual.position = -size * 0.5
	_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_visual)
