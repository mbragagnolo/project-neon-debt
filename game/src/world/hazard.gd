class_name Hazard
extends Hitbox
## Live water, exposed conduit, a floor you should not be standing on.
##
## A hitbox that is always armed and never moves: contact damage at a flat
## power through the same pipeline as everything else (contact skips hitstop,
## stagger and interlocks; the player's i-frames rate-limit it). On top of the
## damage it *bounces* the player upward and away, so a pool is a thing you
## get out of rather than a thing you sit in taking a tick every 0.85s.

const COL_HAZARD := Color(0.1, 0.55, 0.6, 0.85)

@export var size: Vector2 = Vector2(60.0, 60.0)
## Flat damage per touch. Enemy-style: what is typed is what it hits for.
@export var power: float = 8.0
## A drop rather than a pool: the player is put back on the last ground they
## stood on, with the damage. Used under the roof gap, where falling short of
## the Sidewinder gate would otherwise mean a very long walk back.
@export var returns_player: bool = false

var _visual: ColorRect


func _ready() -> void:
	super()
	continuous = true
	collision_layer = 256  # hazard
	collision_mask = 8  # player_hurtbox
	var rect := RectangleShape2D.new()
	rect.size = size
	var collider := CollisionShape2D.new()
	collider.shape = rect
	add_child(collider)

	_visual = ColorRect.new()
	_visual.color = Color(0.02, 0.02, 0.04, 0.95) if returns_player else COL_HAZARD
	_visual.position = -size * 0.5
	_visual.size = size
	_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_visual)

	var attack := Attack.make(self, global_position, power)
	attack.scales_with_stat = false
	attack.is_contact = true
	activate(attack)
	hit_landed.connect(_on_hit_landed)


func _process(_delta: float) -> void:
	# A slow electric shimmer, so a live floor reads as live.
	var t: float = 0.75 + 0.25 * sin(Time.get_ticks_msec() / 180.0)
	_visual.modulate.a = t


func _on_hit_landed(hurtbox: Hurtbox, _result: DamageResult) -> void:
	var body: Node = hurtbox.get_parent()
	if body == null:
		return
	if returns_player and body.has_method(&"void_return"):
		body.call(&"void_return")
	elif body.has_method(&"hazard_bounce"):
		body.call(&"hazard_bounce", global_position)
