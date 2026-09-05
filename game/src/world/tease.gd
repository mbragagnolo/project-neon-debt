class_name Tease
extends Node2D
## A double-jump tease: something worth wanting on a ledge the whole V1 kit
## cannot reach (DESIGN.md §2, §3.4; docs/narrative/hook.md — every
## unreachable ledge is a paywall).
##
## Stands on the ledge itself. Draws a sealed corp crate with a lock glyph
## and the firmware-tier notice, so "how do I get up there?" has an answer
## the player can feel in their wallet. Nothing here is interactive: the
## point is that it cannot be.

const COL_CRATE := Color(0.95, 0.65, 0.2)
const COL_LOCK := Color(1.0, 0.18, 0.58)

const COL_OPEN := Color(0.45, 0.95, 0.6)

var _phase: float = 0.0
var _unlocked: bool = false
var _notice: Sign


func _ready() -> void:
	add_to_group(&"teases")
	_notice = Sign.new()
	_notice.text = "%s FIRMWARE\nTIER 2 · LOCKED" % Lines.CORP
	_notice.width = 220.0
	_notice.warning = true
	_notice.font_size = 16
	_notice.position = Vector2(0.0, -70.0)
	add_child(_notice)


func is_unlocked() -> bool:
	return _unlocked


## The closing shot: the override handshakes with the locked firmware and
## the ledge lights up. Nothing becomes reachable — that is V2's first act.
func unlock() -> void:
	_unlocked = true
	_notice.queue_free()
	_notice = Sign.new()
	_notice.text = "%s FIRMWARE\nTIER 2 · OVERRIDE ACCEPTED" % Lines.CORP
	_notice.width = 260.0
	_notice.font_size = 16
	_notice.position = Vector2(0.0, -70.0)
	add_child(_notice)


func _process(delta: float) -> void:
	_phase += delta
	queue_redraw()


func _draw() -> void:
	# The crate.
	draw_rect(Rect2(-22.0, -46.0, 44.0, 46.0), COL_CRATE)
	draw_rect(Rect2(-22.0, -46.0, 44.0, 46.0), Color(0.3, 0.2, 0.05), false, 3.0)
	# The lock, breathing — or, after the override, open and lit.
	var pulse: float = 0.6 + 0.4 * (0.5 + 0.5 * sin(_phase * 3.0))
	var base: Color = COL_OPEN if _unlocked else COL_LOCK
	var lock := Color(base.r, base.g, base.b, pulse)
	if _unlocked:
		draw_arc(Vector2(6.0, -30.0), 8.0, PI, TAU, 12, lock, 3.0)
		draw_circle(Vector2.ZERO, 90.0 * (0.6 + 0.4 * pulse), Color(base.r, base.g, base.b, 0.08))
	else:
		draw_arc(Vector2(0.0, -30.0), 8.0, PI, TAU, 12, lock, 3.0)
	draw_rect(Rect2(-10.0, -30.0, 20.0, 14.0), lock)
