extends Node
## Music (autoload `Music`; docs/audio/direction.md).
##
## One track at a time, crossfaded. A track is a set of stems that play in
## sync (an AudioStreamSynchronized in assets/audio/music, written by the
## godot-integrator from the composer's audio/music/music.json), and every
## stem is either always on (`base`) or belongs to a state this autoload
## raises: `combat` while an enemy is on the player, `fight` while the
## Landlord's bar is up, `phase2` from his second phase, `low` at 30 % HP
## or under. A room asks for its style's mood (MusicTable.MOODS), the title
## asks for `title`. A state fades its stems in and out over MusicTable.FADE;
## a track change crossfades over FADE. A track that is a single .ogg (a
## project with no stems) still plays and loops.

const DIR := "res://assets/audio/music/"
const FADE := 1.8
const GRAPH_PATH := "res://src/world/world_graph.tres"
const DEFAULT_MOOD := &"residential"
const COMBAT_HOLD := 3.0
const COMBAT_POLL := 0.25
const LOW_HP := 0.3
## An enemy in one of these states has the player: the district's combat layer comes in.
const CHASING: Array[StringName] = [&"Chase", &"Windup", &"Lunge", &"Aim", &"Track"]

var current: StringName = &""
## state -> on; every state the table declares, false until raised.
var states: Dictionary = {}

var _a: AudioStreamPlayer
var _b: AudioStreamPlayer
var _active: AudioStreamPlayer
var _graph: WorldGraph
var _boss_active: bool = false
var _tween: Tween
var _layer_tweens: Dictionary = {}
var _combat_until: float = -1.0
var _poll: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_a = _player()
	_b = _player()
	_active = _a
	for state: StringName in MusicTable.STATES:
		states[state] = false
	if ResourceLoader.exists(GRAPH_PATH):
		_graph = load(GRAPH_PATH)
	Events.room_entered.connect(_on_room_entered)
	Events.boss_hp_changed.connect(_on_boss_hp)
	Events.boss_phase_changed.connect(_on_boss_phase)
	Events.boss_defeated.connect(_on_boss_defeated)
	Events.hp_changed.connect(_on_hp)


func _process(delta: float) -> void:
	_poll -= delta
	if _poll > 0.0:
		return
	_poll = COMBAT_POLL
	var now: float = Time.get_ticks_msec() / 1000.0
	if _any_enemy_chasing():
		_combat_until = now + COMBAT_HOLD
	set_state(&"combat", now < _combat_until)


func _player() -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = &"Music"
	add_child(player)
	return player


## Crossfade to `track`. The same track twice is a no-op, so a room change
## inside one district does not restart the bed. The new track starts with
## its stems at the current states.
func play(track: StringName, fade: float = FADE) -> void:
	if track == current:
		return
	var stream: AudioStream = _load(track)
	if stream == null:
		return
	current = track
	var next: AudioStreamPlayer = _b if _active == _a else _a
	var previous: AudioStreamPlayer = _active
	_active = next
	_kill_layer_tweens(next)
	next.stream = stream
	_apply_layers(next, 0.0)
	next.volume_db = -40.0
	next.play()
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(next, "volume_db", 0.0, fade).set_trans(Tween.TRANS_SINE)
	if previous.playing:
		_tween.tween_property(previous, "volume_db", -40.0, fade).set_trans(Tween.TRANS_SINE)
		_tween.chain().tween_callback(previous.stop)


## Raise or drop a state: its stems fade in or out on the playing track.
func set_state(state: StringName, on: bool) -> void:
	if states.get(state, false) == on:
		return
	states[state] = on
	_apply_layers(_active, MusicTable.FADE)


## Back to silence, no boss, no state, for a test or a fresh title.
func reset() -> void:
	_boss_active = false
	_combat_until = -1.0
	current = &""
	for state: StringName in states:
		states[state] = false
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_kill_layer_tweens(_a)
	_kill_layer_tweens(_b)
	_a.stop()
	_b.stop()


func stop(fade: float = FADE) -> void:
	current = &""
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_active, "volume_db", -40.0, fade)
	_tween.tween_callback(_active.stop)


## A room's track, from its style in the world graph.
func track_for_room(room_id: StringName) -> StringName:
	var style: String = String(DEFAULT_MOOD)
	if _graph != null:
		var entry: Dictionary = _graph.room(room_id)
		style = String(entry.get("style", style))
	return track_for_style(style)


## A mood's track: the style's entry in the table, or the default mood's.
func track_for_style(style: String) -> StringName:
	var mood: Dictionary = MusicTable.MOODS.get(StringName(style), MusicTable.MOODS.get(DEFAULT_MOOD, {}))
	return mood.get("track", &"")


## The volume a layer of the current track should sit at under the states: 0 on, SILENCE_DB off.
func layer_target(layer_id: StringName) -> float:
	for layer: Dictionary in _layers(current):
		if layer["id"] == layer_id:
			return 0.0 if _layer_on(layer) else MusicTable.SILENCE_DB
	return MusicTable.SILENCE_DB


## The volume a layer of the playing stream actually sits at now (mid-fade included).
func layer_volume(layer_id: StringName) -> float:
	var sync := _active.stream as AudioStreamSynchronized
	if sync == null:
		return MusicTable.SILENCE_DB
	var layers: Array = _layers(current)
	for i in range(mini(layers.size(), sync.stream_count)):
		if layers[i]["id"] == layer_id:
			return sync.get_sync_stream_volume(i)
	return MusicTable.SILENCE_DB


func _layers(track: StringName) -> Array:
	return MusicTable.TRACKS.get(track, {}).get("layers", [])


func _layer_on(layer: Dictionary) -> bool:
	return layer["state"] == &"base" or states.get(layer["state"], false)


func _apply_layers(player: AudioStreamPlayer, fade: float) -> void:
	var sync := player.stream as AudioStreamSynchronized
	if sync == null:
		return
	var layers: Array = _layers(current)
	_kill_layer_tweens(player)
	var tween: Tween = null
	for i in range(mini(layers.size(), sync.stream_count)):
		var target: float = 0.0 if _layer_on(layers[i]) else MusicTable.SILENCE_DB
		var now: float = sync.get_sync_stream_volume(i)
		if is_equal_approx(now, target):
			continue
		if fade <= 0.0:
			sync.set_sync_stream_volume(i, target)
			continue
		if tween == null:
			tween = create_tween().set_parallel(true)
			_layer_tweens[player] = tween
		tween.tween_method(func(v: float) -> void: sync.set_sync_stream_volume(i, v), now, target, fade) \
			.set_trans(Tween.TRANS_SINE)


func _kill_layer_tweens(player: AudioStreamPlayer) -> void:
	var tween: Tween = _layer_tweens.get(player)
	if tween != null and tween.is_valid():
		tween.kill()
	_layer_tweens.erase(player)


func _any_enemy_chasing() -> bool:
	if not is_inside_tree():
		return false
	for enemy: Node in get_tree().get_nodes_in_group(&"enemies"):
		if enemy.has_method(&"state_name") and enemy.call(&"state_name") in CHASING:
			return true
	return false


func _on_room_entered(room_id: StringName) -> void:
	if _boss_active:
		return
	play(track_for_room(room_id))


func _on_boss_hp(_name: String, hp: int, _max_hp: int) -> void:
	if hp <= 0 or _boss_active:
		return
	_boss_active = true
	play(track_for_style("collections"), 0.8)
	set_state(&"fight", true)


func _on_boss_phase(phase: int) -> void:
	set_state(&"phase2", phase >= 2)


func _on_boss_defeated(_boss: Node) -> void:
	_boss_active = false
	set_state(&"fight", false)
	set_state(&"phase2", false)
	play(&"title", 3.0)


func _on_hp(hp: int, max_hp: int) -> void:
	set_state(&"low", max_hp > 0 and float(hp) / float(max_hp) <= LOW_HP)


func _load(track: StringName) -> AudioStream:
	var tres: String = DIR + String(track) + ".tres"
	if ResourceLoader.exists(tres):
		# A copy: the cached resource keeps its stem volumes between plays otherwise.
		return (load(tres) as AudioStream).duplicate()
	var path: String = DIR + String(track) + ".ogg"
	if not ResourceLoader.exists(path):
		push_warning("Music: no track named '%s'" % track)
		return null
	var stream: AudioStream = load(path)
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	return stream
