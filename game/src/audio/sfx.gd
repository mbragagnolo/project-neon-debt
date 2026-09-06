extends Node
## Sound effects (autoload `Sfx`; docs/audio/direction.md).
##
## One place hears the signal bus and answers with sounds, so a system that
## emits `enemy_died` never learns what dying sounds like. A pool of players,
## a small pitch wobble so repeats do not machine-gun, and a floor between
## two plays of the same id so ten hits in a frame are one sound.
##
## The ids are the file names in assets/audio/sfx (tools/audio/make_sfx.py).

const DIR := "res://assets/audio/sfx/"
const POOL := 16
const MIN_GAP_MS := 35

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _last: Dictionary = {}
var _next: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i: int in POOL:
		var player := AudioStreamPlayer.new()
		player.bus = &"SFX"
		add_child(player)
		_players.append(player)
	_connect()


func play(id: StringName, volume_db: float = 0.0, pitch_jitter: float = 0.06) -> void:
	var stream: AudioStream = _stream(id)
	if stream == null:
		return
	var now: int = Time.get_ticks_msec()
	if now - int(_last.get(id, -100000)) < MIN_GAP_MS:
		return
	# A menu that opens moves focus too; the open is the sound.
	if id == &"ui_move" and now - int(_last.get(&"ui_open", -100000)) < 200:
		return
	_last[id] = now
	var player: AudioStreamPlayer = _free_player()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = randf_range(1.0 - pitch_jitter, 1.0 + pitch_jitter)
	player.play()


func has(id: StringName) -> bool:
	return _stream(id) != null


func _stream(id: StringName) -> AudioStream:
	if _streams.has(id):
		return _streams[id]
	var path: String = DIR + String(id) + ".wav"
	var stream: AudioStream = load(path) if ResourceLoader.exists(path) else null
	if stream == null:
		push_warning("Sfx: no sound named '%s'" % id)
	_streams[id] = stream
	return stream


func _free_player() -> AudioStreamPlayer:
	for player: AudioStreamPlayer in _players:
		if not player.playing:
			return player
	var player: AudioStreamPlayer = _players[_next]
	_next = (_next + 1) % _players.size()
	return player


# --- The bus, heard ------------------------------------------------------------

func _connect() -> void:
	Events.player_action.connect(_on_player_action)
	Events.sfx_requested.connect(func(id: StringName, _at: Vector2) -> void: play(id))
	Events.damage_dealt.connect(_on_damage_dealt)
	Events.enemy_died.connect(_on_enemy_died)
	Events.boss_phase_changed.connect(func(_p: int) -> void: play(&"roar"))
	Events.boss_defeated.connect(func(_b: Node) -> void: play(&"roar", -2.0); play(&"slam"))
	Events.hack_cast.connect(_on_hack_cast)
	Events.hack_failed.connect(func(_id: StringName, _why: StringName) -> void: play(&"deny"))
	Events.hack_acquired.connect(func(_id: StringName) -> void: play(&"hack_acquire"))
	Events.ability_granted.connect(func(_id: StringName) -> void: play(&"hack_acquire"))
	Events.item_picked_up.connect(func(_id: StringName) -> void: play(&"pickup"))
	Events.stat_up_acquired.connect(func(_k: StringName, _a: int) -> void: play(&"stat_up"))
	Events.quest_item_acquired.connect(func(_id: StringName) -> void: play(&"quest"))
	Events.quest_started.connect(func(_id: StringName) -> void: play(&"toast"))
	Events.quest_completed.connect(func(_id: StringName) -> void: play(&"quest"))
	Events.level_gained.connect(func(_l: int) -> void: play(&"level_up"))
	Events.save_point_activated.connect(func(_id: StringName) -> void: play(&"save"))
	Events.door_opened.connect(func(_id: StringName) -> void: play(&"breach"))
	Events.room_entered.connect(func(_id: StringName) -> void: play(&"door_pass", -6.0))
	Events.toast_requested.connect(func(_t: String) -> void: play(&"toast", -4.0))
	Events.bark_requested.connect(func(_t: String) -> void: play(&"bark", -6.0))
	Events.shop_purchased.connect(func(_id: StringName) -> void: play(&"buy"))
	Events.item_equipped.connect(func(_s: StringName, _i: StringName) -> void: play(&"ui_confirm"))
	Events.player_died.connect(func() -> void: play(&"die"))


func _on_player_action(action: StringName, _at: Vector2, _direction: int) -> void:
	match action:
		&"jump": play(&"jump", -3.0)
		&"wall_jump": play(&"wall_jump", -3.0)
		&"dash": play(&"dash", -2.0)
		&"land": play(&"land", -8.0, 0.1)
		&"swing": play(&"swing", -4.0, 0.1)
		&"shoot_bolt": play(&"shoot", -4.0)
		&"shoot_nail": play(&"shoot_nail", -3.0)
		&"shoot_rivet": play(&"shoot_rivet", -2.0)
		&"hurt": play(&"hurt")
		&"hurt_guard": play(&"hit_guard")
		&"hazard": play(&"hazard")
		&"lift": play(&"lift", -6.0)


func _on_damage_dealt(target: Node, amount: int, _source: Node) -> void:
	if target != null and target.is_in_group(&"player"):
		return
	play(&"hit_heavy" if amount >= 12 else &"hit", -2.0, 0.1)


func _on_enemy_died(enemy: Node, _xp: int, _credits: int) -> void:
	if enemy != null and enemy.is_in_group(&"bosses"):
		return
	var mechanical: bool = false
	if enemy != null and enemy.get("config") != null:
		mechanical = enemy.get("config").get("mechanical") == true
	play(&"mech_die" if mechanical else &"enemy_die")


func _on_hack_cast(id: StringName, _cost: int) -> void:
	match id:
		&"firewall": play(&"hack_guard")
		&"overload": play(&"hack_burst")
		&"breach": play(&"hack_pulse")
		_: play(&"hack_pulse")
