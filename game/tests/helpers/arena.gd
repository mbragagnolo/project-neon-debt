class_name TestArena
extends RefCounted
## Builds throwaway greybox arenas for the movement tests.
##
## The tests need geometry they can reason about exactly — a ledge at a known x,
## a shaft of a known width — which the shipped rooms cannot promise while
## they are being tuned. So they build their own.

const PLAYER_SCENE := preload("res://src/player/player.tscn")
const DUMMY_SCENE := preload("res://src/enemies/training_dummy/training_dummy.tscn")


## A static box. `center` and `size` are in pixels, like everything else.
static func solid(parent: Node, center: Vector2, size: Vector2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = center
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := RectangleShape2D.new()
	shape.size = size
	var collider := CollisionShape2D.new()
	collider.shape = shape
	body.add_child(collider)
	parent.add_child(body)
	return body


## A player standing at `at` (origin is at the feet).
static func player(parent: Node, at: Vector2) -> Player:
	var instance: Player = PLAYER_SCENE.instantiate()
	parent.add_child(instance)
	instance.position = at
	return instance


## A training dummy at `at` (origin is at the feet), configured with the
## reduced enemy stat block.
static func dummy(
	parent: Node,
	at: Vector2,
	max_hp: int = 40,
	defense: int = 0,
	stagger_threshold: int = 1,
	hurts_on_contact: bool = false
) -> TrainingDummy:
	var instance: TrainingDummy = DUMMY_SCENE.instantiate()
	instance.max_hp = max_hp
	instance.defense = defense
	instance.stagger_threshold = stagger_threshold
	# Set before the dummy enters the tree: the contact box is armed in
	# `_ready`, so flipping this afterwards would be silently ignored.
	instance.hurts_on_contact = hurts_on_contact
	# Nothing should stand back up mid-assertion.
	instance.respawn_delay = 0.0
	instance.show_damage_numbers = false
	parent.add_child(instance)
	instance.position = at
	return instance


## Every action the controller reads, so a test can leave no input held.
static func release_all_input() -> void:
	for action: String in [
		"move_left",
		"move_right",
		"move_up",
		"move_down",
		"jump",
		"dash",
		"attack_melee",
		"attack_ranged",
	]:
		if Input.is_action_pressed(action):
			Input.action_release(action)
