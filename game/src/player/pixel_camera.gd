class_name PixelCamera
extends Camera2D
## The follow camera, snapped to the art grid (docs/art/environment.md, 6).
##
## The art is baked at two world pixels per art pixel and the camera looks
## through a 1.5x zoom, so an art pixel is three screen pixels at 1080p:
## the density of the references, with Dani at 15% of the frame instead of
## 10%. Any whole world pixel lands an art pixel on three whole screen
## pixels; a half world pixel does not. So this camera follows its parent
## with its own smoothing and lands on whole art pixels (two world px), and
## `rendering/2d/snap/snap_2d_transforms_to_pixel` does the same for every
## sprite. It also owns the shake: `Events.camera_shake_requested` decays
## into `offset`, and the ending's pan tweens `offset` as well.

## Screen px per world px. 1.5 makes a 2x-baked art pixel three screen px.
const ZOOM := 1.5
## One art pixel in world px; the camera and the shake land on multiples.
const PIXEL := 2.0

@export var smoothing: float = 9.0

var _follow: Node2D
var _anchor: Vector2 = Vector2.ZERO
var _target: Vector2 = Vector2.ZERO
var _shake_strength: float = 0.0
var _shake_time: float = 0.0
var _shake_left: float = 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_follow = get_parent() as Node2D
	_anchor = position
	zoom = Vector2(ZOOM, ZOOM)
	position_smoothing_enabled = false
	top_level = true
	Events.camera_shake_requested.connect(shake)
	snap_to_target()


func _process(delta: float) -> void:
	if _follow == null:
		return
	var wanted: Vector2 = _follow.global_position + _anchor
	_target = _target.lerp(wanted, 1.0 - exp(-smoothing * delta))
	global_position = (_target / PIXEL).round() * PIXEL
	_tick_shake(delta)


## Drops the lag: after a room swap or a respawn the camera must not glide
## across the new room from wherever it was.
func snap_to_target() -> void:
	if _follow == null:
		return
	_target = _follow.global_position + _anchor
	global_position = (_target / PIXEL).round() * PIXEL
	reset_smoothing()


func shake(strength: float, duration: float) -> void:
	if not Settings.screen_shake:
		return
	_shake_strength = maxf(_shake_strength, strength)
	_shake_time = maxf(_shake_time, duration)
	_shake_left = maxf(_shake_left, duration)


func _tick_shake(delta: float) -> void:
	if _shake_left <= 0.0:
		return
	_shake_left -= delta
	var t: float = clampf(_shake_left / maxf(_shake_time, 0.001), 0.0, 1.0)
	var amount: float = _shake_strength * t
	var jitter := Vector2(_rng.randf_range(-amount, amount), _rng.randf_range(-amount, amount))
	# Snap the jitter too, so the shake is a shake and not a blur.
	offset = (jitter / PIXEL).round() * PIXEL + _pan
	if _shake_left <= 0.0:
		_shake_strength = 0.0
		offset = _pan


## The ending pans with this; the shake rides on top of it.
var _pan: Vector2 = Vector2.ZERO


func set_pan(value: Vector2) -> void:
	_pan = value
	if _shake_left <= 0.0:
		offset = _pan


func get_pan() -> Vector2:
	return _pan


## What the camera shows, in world px: the project viewport over the zoom.
## The room generator sizes its camera limits from this.
static func view_size() -> Vector2:
	var w: float = float(ProjectSettings.get_setting("display/window/size/viewport_width", 1920))
	var h: float = float(ProjectSettings.get_setting("display/window/size/viewport_height", 1080))
	return Vector2(w, h) / ZOOM
