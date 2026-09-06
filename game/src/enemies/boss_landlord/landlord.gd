class_name Landlord
extends Enemy
## The Landlord — the debt enforcer of the Stacks (DESIGN.md §3.5;
## docs/characters/boss-landlord.md).
##
## The one roster entry that is a subclass: two phases, an attack picked by
## distance, an arena that locks, and a death that ends the slice. He still
## runs the shared pipeline, the shared state machine and the shared
## config — the baton is the Scav's windup → lunge → recover with bigger
## numbers, and his stagger is everyone's stagger. What is his alone lives
## here: the slam, the repo beam, the phase shift, and the doors.
##
## Tuned so every verb has a job (DESIGN.md §2, "the boss is a wall worth
## climbing"): DEF 4 blunts light hits, stagger threshold 16 means only the
## maul, the rivet gun and Overload interrupt him, and the drones he calls in
## phase two are the thing Breach is for.

signal phase_changed(phase: int)

const DRONE_SCENE := "res://src/enemies/drone/drone.tscn"

@export_group("Slam")
## The telegraph: crouched and lit before the shockwave.
@export var slam_windup: float = 0.7
@export var slam_speed: float = 420.0
@export var slam_power: float = 12.0
@export var slam_lifetime: float = 1.7
## Beyond this the slam is not worth throwing; he closes instead.
@export var slam_range: float = 760.0

@export_group("Repo beam (phase two)")
## Under this he would rather swing.
@export var beam_range_min: float = 380.0

@export_group("Pacing")
## Seconds between attacks, from the end of one recovery to the next pick.
@export var attack_cooldown: float = 1.1
@export var phase2_cooldown_mult: float = 0.7
@export var phase2_speed_mult: float = 1.3
## Seconds the phase shift holds him invulnerable and roaring.
@export var phase_shift_time: float = 1.4
@export var drones_on_phase_two: int = 2

var phase: int = 1
var _attack_cooldown_timer: float = 0.0
var _locked_doors: Array[Door] = []


func _ready() -> void:
	super()
	add_to_group(&"bosses")
	Events.boss_hp_changed.emit(config.display_name, health.hp, health.max_hp)
	_lock_arena()


func _physics_process(delta: float) -> void:
	_attack_cooldown_timer = maxf(_attack_cooldown_timer - delta, 0.0)
	super(delta)


# --- Attacks ------------------------------------------------------------------

func can_attack() -> bool:
	return _attack_cooldown_timer <= 0.0


func start_attack_cooldown() -> void:
	_attack_cooldown_timer = attack_cooldown * (phase2_cooldown_mult if phase == 2 else 1.0)


func approach_speed() -> float:
	return config.chase_speed * (phase2_speed_mult if phase == 2 else 1.0)


## Which attack fits the distance. Empty means keep closing.
func pick_attack() -> StringName:
	if not has_player():
		return &""
	var distance: float = distance_to_player()
	if distance <= config.lunge_range and can_lunge():
		return &"Windup"
	if phase == 2 and distance >= beam_range_min and can_fire():
		return &"BeamWindup"
	if distance <= slam_range:
		return &"SlamWindup"
	return &""


## Two shockwaves along the floor, one each way. Jump them — the ledges and
## the dais are what the arena's platforms are for.
func slam() -> void:
	for side: int in [-1, 1]:
		var attack := Attack.make(self, global_position, slam_power, config.lunge_knockback * 0.6)
		attack.scales_with_stat = false
		attack.is_ranged = true
		var wave := Projectile.new()
		wave.collision_layer = 512
		wave.collision_mask = 8  # the player's hurtbox only; the floor is where it lives
		get_parent().add_child(wave)
		wave.global_position = global_position + Vector2(float(side) * 50.0, -22.0)
		wave.launch(attack, Vector2(float(side), 0.0), slam_speed, slam_lifetime, Vector2(44.0, 30.0), Color(1.0, 0.55, 0.2), 0.0, load("res://assets/fx/wave.png"))
		if side < 0:
			wave.get_child(wave.get_child_count() - 1).set(&"flip_h", true)


func summon_drones() -> void:
	var scene: PackedScene = load(DRONE_SCENE)
	if scene == null:
		return
	for i: int in drones_on_phase_two:
		var drone: Node2D = scene.instantiate()
		var side: float = -1.0 if i % 2 == 0 else 1.0
		drone.position = position + Vector2(side * 420.0, -320.0)
		get_parent().add_child(drone)


## Recover and Stagger hand control back here, and every hand-back starts
## the attack cooldown — a boss that swings again the instant recovery ends
## is a boss with no punish window.
func after_recover_state() -> StringName:
	start_attack_cooldown()
	return &"Approach"


# --- Phases ---------------------------------------------------------------------

func _on_damaged(amount: int, attack: Attack) -> void:
	super(amount, attack)
	Events.boss_hp_changed.emit(config.display_name, health.hp, health.max_hp)
	if phase == 1 and not health.is_dead() and health.hp <= health.max_hp / 2:
		phase = 2
		phase_changed.emit(phase)
		Events.boss_phase_changed.emit(phase)
		_state_machine.transition_to(&"PhaseShift")


## The phase shift is not interrupted by the hit that caused it: `damaged`
## fires before `staggered`, and the shift must win.
func _on_staggered() -> void:
	if state_name() == &"PhaseShift":
		return
	super()


func _on_died() -> void:
	super()
	Events.boss_hp_changed.emit(config.display_name, 0, health.max_hp)
	GameState.set_flag(&"boss.landlord_defeated")
	_unlock_arena()
	Events.boss_defeated.emit(self)


# --- The arena ------------------------------------------------------------------

## Every door in the room seals while he lives. The player got in; they
## leave over him or through the terminal.
func _lock_arena() -> void:
	var room: Node = _find_room()
	if room == null:
		return
	var doors: Node = room.get_node_or_null("Doors")
	if doors == null:
		return
	for door: Node in doors.get_children():
		if door is Door:
			(door as Door).lock()
			_locked_doors.append(door as Door)


func _unlock_arena() -> void:
	for door: Door in _locked_doors:
		if is_instance_valid(door):
			door.unlock()
	_locked_doors.clear()


func _find_room() -> Node:
	var node: Node = get_parent()
	while node != null:
		if node is Room:
			return node
		node = node.get_parent()
	return null
