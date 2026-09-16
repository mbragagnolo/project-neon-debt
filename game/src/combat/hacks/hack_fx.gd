class_name HackFx
extends Node2D
## The greybox tell for a cast: an expanding ring, or a bolt to the target.
##
## A cast is instant and auto-targeted, so without this there is nothing on
## screen to say it happened, which program it was, or what it reached. The
## ring is drawn at the program's real radius for the same reason the swing
## tell is drawn at the hitbox's real size: in a tuning lab the tell has to be
## the truth. M7's art pass replaces the look, not the contract.

var _color: Color = Color.WHITE
var _radius: float = 0.0
var _life: float = 0.3
var _elapsed: float = 0.0
var _to: Vector2 = Vector2.ZERO
var _is_bolt: bool = false


static func ring(parent: Node, at: Vector2, radius: float, colour: Color, seconds: float) -> HackFx:
	var fx := HackFx.new()
	fx._color = colour
	fx._radius = radius
	fx._life = maxf(seconds, 0.05)
	fx.z_index = 20
	parent.get_parent().add_child(fx)
	fx.global_position = at
	return fx


static func bolt(parent: Node, from: Vector2, to: Vector2, colour: Color, seconds: float) -> HackFx:
	var fx := ring(parent, from, 0.0, colour, seconds)
	fx._is_bolt = true
	fx._to = to - from
	return fx


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= _life:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var t: float = clampf(_elapsed / _life, 0.0, 1.0)
	var alpha: float = 1.0 - t
	var colour := Color(_color.r, _color.g, _color.b, alpha)
	if _is_bolt:
		draw_line(Vector2.ZERO, _to, colour, 6.0 * (1.0 - t) + 2.0)
		return
	var current: float = _radius * (0.35 + 0.65 * t)
	draw_arc(Vector2.ZERO, current, 0.0, TAU, 48, colour, 4.0)
	draw_circle(Vector2.ZERO, current, Color(_color.r, _color.g, _color.b, alpha * 0.12))
