class_name SwingTell
extends Node2D
## The melee swing, drawn (DESIGN.md §3.2; the M2 rule that the tell is the
## truth).
##
## Sits inside the melee hitbox and is sized to it exactly, so what the
## player sees is where the box is: a crescent slash across the box, solid
## while the box can hit, a fading ghost through the recovery. The box's
## `size` is the contract `tests/test_player_combat.gd` holds it to.

var size: Vector2 = Vector2(72.0, 72.0)
var colour: Color = Color(0.85, 0.95, 1.0, 0.75)
var alpha: float = 1.0
var _phase: float = 0.0


func _ready() -> void:
	z_index = 5
	visible = false


func set_alpha(value: float) -> void:
	alpha = value
	queue_redraw()


func show_swing(box: Vector2, tint: Color) -> void:
	size = box
	colour = tint
	alpha = 1.0
	_phase = 0.0
	visible = true
	queue_redraw()


func _process(delta: float) -> void:
	if visible:
		_phase += delta
		queue_redraw()


func _draw() -> void:
	var half: Vector2 = size * 0.5
	var radius: float = maxf(half.x, half.y)
	var c := Color(colour.r, colour.g, colour.b, colour.a * alpha)
	var faint := Color(colour.r, colour.g, colour.b, colour.a * alpha * 0.35)
	# The arc sweeps from above the leading edge down and across; three
	# bands of decreasing weight read as motion in a single frame.
	var centre := Vector2(-half.x * 0.6, 0.0)
	draw_arc(centre, radius * 0.95, -0.9, 0.9, 18, c, 9.0)
	draw_arc(centre, radius * 0.72, -1.1, 0.7, 16, faint, 5.0)
	draw_arc(centre, radius * 0.5, -1.3, 0.5, 12, faint, 3.0)
	# A hot tip.
	var tip: Vector2 = centre + Vector2(cos(0.85), sin(0.85)) * radius * 0.95
	draw_circle(tip, 5.0, Color(1.0, 1.0, 1.0, alpha * 0.9))
