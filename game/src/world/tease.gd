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

var _phase: float = 0.0


func _ready() -> void:
	var notice := Sign.new()
	notice.text = "%s FIRMWARE\nTIER 2 · LOCKED" % Lines.CORP
	notice.width = 220.0
	notice.warning = true
	notice.font_size = 16
	notice.position = Vector2(0.0, -70.0)
	add_child(notice)


func _process(delta: float) -> void:
	_phase += delta
	queue_redraw()


func _draw() -> void:
	# The crate.
	draw_rect(Rect2(-22.0, -46.0, 44.0, 46.0), COL_CRATE)
	draw_rect(Rect2(-22.0, -46.0, 44.0, 46.0), Color(0.3, 0.2, 0.05), false, 3.0)
	# The lock, breathing.
	var pulse: float = 0.6 + 0.4 * (0.5 + 0.5 * sin(_phase * 3.0))
	var lock := Color(COL_LOCK.r, COL_LOCK.g, COL_LOCK.b, pulse)
	draw_arc(Vector2(0.0, -30.0), 8.0, PI, TAU, 12, lock, 3.0)
	draw_rect(Rect2(-10.0, -30.0, 20.0, 14.0), lock)
