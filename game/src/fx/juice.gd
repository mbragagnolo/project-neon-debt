class_name Juice
extends Node2D
## The small things that make a hit feel like a hit (DESIGN.md §3.7,
## docs/art/direction.md): sparks where damage lands, a number that says how
## much, dust under a landing, ghosts behind a dash, a burst where an enemy
## was, and a nudge to the camera. All of it hangs off the signal bus, so
## the systems that fight never know they are being decorated.
##
## Lives in the world scene, in world space, above the rooms.

const COL_SPARK := Color(1.0, 0.85, 0.45)
const COL_HURT := Color(1.0, 0.3, 0.4)
const COL_DUST := Color(0.6, 0.65, 0.8, 0.7)
const COL_GHOST := Color(0.3, 0.9, 1.0, 0.55)
const COL_NUMBER := Color(1.0, 0.95, 0.8)
const COL_NUMBER_BIG := Color(1.0, 0.55, 0.3)

var _spark: Texture2D = load("res://assets/fx/spark.png")
var _dot: Texture2D = load("res://assets/fx/dot.png")
var _puff: Texture2D = load("res://assets/fx/puff.png")
var _ghost_timer: float = 0.0


func _ready() -> void:
	z_index = 50
	Events.player_action.connect(_on_player_action)
	Events.damage_dealt.connect(_on_damage_dealt)
	Events.enemy_died.connect(_on_enemy_died)
	Events.impact.connect(_on_impact)
	Events.boss_defeated.connect(_on_boss_defeated)


func _process(delta: float) -> void:
	var player: Node = get_tree().get_first_node_in_group(&"player")
	if player == null or not player.has_method(&"state_name"):
		return
	if player.call(&"state_name") == &"Dash":
		_ghost_timer -= delta
		if _ghost_timer <= 0.0:
			_ghost_timer = 0.035
			_ghost(player)
	else:
		_ghost_timer = 0.0


# --- Answers --------------------------------------------------------------------

func _on_player_action(action: StringName, at: Vector2, direction: int) -> void:
	match action:
		&"land":
			_burst(at, _puff, 6, COL_DUST, 60.0, 0.35, Vector2(0.0, -1.0), 80.0, 0.6)
		&"jump":
			_burst(at, _puff, 3, COL_DUST, 40.0, 0.25, Vector2(0.0, -0.4), 60.0, 0.5)
		&"wall_jump":
			_burst(at + Vector2(direction * 20.0, -30.0), _puff, 5, COL_DUST, 70.0, 0.3, Vector2(-direction, 0.0), 40.0, 0.5)
		&"hurt", &"hurt_guard":
			_burst(at + Vector2(0.0, -40.0), _spark, 10, COL_HURT if action == &"hurt" else Color(0.6, 0.9, 1.0), 220.0, 0.4, Vector2.UP, 180.0, 0.9)
			shake(3.5, 0.18)
		&"hazard":
			_burst(at, _dot, 12, Color(0.3, 0.9, 1.0), 200.0, 0.5, Vector2.UP, 120.0, 0.9)
			shake(3.0, 0.15)
		&"swing":
			pass


func _on_damage_dealt(target: Node, amount: int, _source: Node) -> void:
	if not (target is Node2D):
		return
	var at: Vector2 = _centre(target as Node2D)
	if target.is_in_group(&"player"):
		return
	var heavy: bool = amount >= 12
	_burst(at, _spark, 12 if heavy else 7, COL_SPARK, 260.0 if heavy else 180.0, 0.32, Vector2.UP, 90.0, 1.0)
	_number(at + Vector2(randf_range(-10.0, 10.0), -30.0), str(amount), COL_NUMBER_BIG if heavy else COL_NUMBER, 30 if heavy else 24)
	shake(3.0 if heavy else 1.6, 0.14)


func _on_enemy_died(enemy: Node, _xp: int, _credits: int) -> void:
	if not (enemy is Node2D):
		return
	var at: Vector2 = _centre(enemy as Node2D)
	_burst(at, _dot, 16, COL_SPARK, 240.0, 0.6, Vector2.UP, 200.0, 1.0)
	_burst(at, _puff, 5, COL_DUST, 60.0, 0.5, Vector2.UP, 60.0, 0.5)
	shake(4.0, 0.22)


func _on_impact(at: Vector2, colour: Color) -> void:
	_burst(at, _spark, 5, colour, 140.0, 0.22, Vector2.UP, 60.0, 1.0)


func _on_boss_defeated(boss: Node) -> void:
	if boss is Node2D:
		var at: Vector2 = _centre(boss as Node2D)
		_burst(at, _dot, 40, COL_SPARK, 420.0, 1.2, Vector2.UP, 200.0, 1.0)
		_burst(at, _puff, 12, COL_DUST, 120.0, 1.0, Vector2.UP, 40.0, 0.5)
	shake(10.0, 0.6)


func shake(strength: float, seconds: float) -> void:
	if not Settings.screen_shake:
		return
	Events.camera_shake_requested.emit(strength, seconds)


# --- Parts --------------------------------------------------------------------------

func _centre(node: Node2D) -> Vector2:
	if node.has_method(&"center"):
		return node.call(&"center")
	return node.global_position


## A one-shot puff of particles, freed when it is done.
func _burst(at: Vector2, texture: Texture2D, count: int, colour: Color, speed: float, life: float, direction: Vector2, gravity: float, spread: float) -> void:
	var p := CPUParticles2D.new()
	p.texture = texture
	p.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = count
	p.lifetime = life
	p.direction = direction
	p.spread = 180.0 * spread
	p.gravity = Vector2(0.0, gravity)
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	# The fx sheets are authored at 3x like everything else; particles
	# scale them again so a spark is a few screen pixels, not one.
	p.scale_amount_min = 1.6
	p.scale_amount_max = 2.6
	p.color = colour
	p.damping_min = speed * 0.8
	p.damping_max = speed * 1.6
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 1))
	ramp.set_color(1, Color(1, 1, 1, 0))
	p.color_ramp = ramp
	p.global_position = at
	p.emitting = true
	add_child(p)
	get_tree().create_timer(life + 0.1).timeout.connect(p.queue_free)


## A number that rises and fades, in the room, where it happened.
func _number(at: Vector2, text: String, colour: Color, size: int) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", colour)
	label.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.1))
	label.add_theme_constant_override("outline_size", 4)
	label.size = Vector2(80.0, 32.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.global_position = at - Vector2(40.0, 16.0)
	label.z_index = 60
	add_child(label)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(label, "global_position:y", at.y - 62.0, 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.65).set_delay(0.25)
	tween.chain().tween_callback(label.queue_free)


## A fading copy of the player's sprite, left where the dash was.
func _ghost(player: Node) -> void:
	var sprite: Node = player.get_node_or_null("Visual/Sprite")
	if not (sprite is Sprite2D):
		return
	var source: Sprite2D = sprite as Sprite2D
	var ghost := Sprite2D.new()
	ghost.texture = source.texture
	ghost.hframes = source.hframes
	ghost.vframes = source.vframes
	ghost.frame = source.frame
	ghost.flip_h = source.flip_h
	ghost.offset = source.offset
	ghost.centered = source.centered
	ghost.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ghost.global_transform = source.global_transform
	ghost.modulate = COL_GHOST
	ghost.z_index = 40
	add_child(ghost)
	var tween := create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.22)
	tween.tween_callback(ghost.queue_free)
