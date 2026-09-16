class_name Lift
extends AnimatableBody2D
## A freight platform that rides between two heights (the drain riser).
##
## A shaft too tall to wall-jump gets a lift instead of a ladder of ledges.
## `sync_to_physics` lets the player's `move_and_slide` ride it for free. It
## waits at each end so a player can step on, and it never stops in between
## — a lift that can be stalled mid-shaft is a lift that strands someone.

const COL_DECK := Color(0.5, 0.56, 0.7)
const COL_RAIL := Color(0.98, 0.78, 0.25)

## Distance travelled upward from the resting position, px.
@export var travel: float = 1000.0
@export var width: float = 360.0
@export var speed: float = 280.0
## Seconds held at each end.
@export var pause: float = 1.4

var _origin: Vector2 = Vector2.ZERO
var _progress: float = 0.0
var _direction: int = 1
var _wait: float = 0.0


func _ready() -> void:
	sync_to_physics = true
	collision_layer = 1
	collision_mask = 0
	_origin = position
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width, 24.0)
	var collider := CollisionShape2D.new()
	collider.shape = rect
	collider.position = Vector2(0.0, 12.0)
	add_child(collider)
	var deck := TextureRect.new()
	deck.texture = load("res://assets/props/lift_deck.png")
	deck.stretch_mode = TextureRect.STRETCH_TILE
	deck.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	deck.position = Vector2(-width * 0.5, 0.0)
	deck.size = Vector2(width, 24.0)
	deck.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(deck)
	var light := PointLight2D.new()
	light.texture = load("res://assets/fx/light_soft.png")
	light.color = Color(1.0, 0.75, 0.3)
	light.energy = 0.6
	light.texture_scale = 2.0
	light.position = Vector2(0.0, 12.0)
	add_child(light)
	_wait = pause


func _physics_process(delta: float) -> void:
	if _wait > 0.0:
		_wait -= delta
		return
	_progress += float(_direction) * speed * delta
	if _progress >= travel:
		_progress = travel
		_direction = -1
		_wait = pause
	elif _progress <= 0.0:
		_progress = 0.0
		_direction = 1
		_wait = pause
	position = _origin - Vector2(0.0, _progress)
