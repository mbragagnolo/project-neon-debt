extends Node
## Music (autoload `Music`; docs/audio/direction.md).
##
## One track at a time, crossfaded. The district picks by room style —
## the residential floors, the Gut and the roof each have a bed — the
## Landlord's arena takes over when his bar appears, and the title and the
## ending share a track. Tracks are the files in assets/audio/music
## (tools/audio/make_music.py); every one loops.

const DIR := "res://assets/audio/music/"
const FADE := 1.8
const GRAPH_PATH := "res://src/world/world_graph.tres"

var current: StringName = &""

var _a: AudioStreamPlayer
var _b: AudioStreamPlayer
var _active: AudioStreamPlayer
var _graph: WorldGraph
var _boss_active: bool = false
var _tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_a = _player()
	_b = _player()
	_active = _a
	if ResourceLoader.exists(GRAPH_PATH):
		_graph = load(GRAPH_PATH)
	Events.room_entered.connect(_on_room_entered)
	Events.boss_hp_changed.connect(_on_boss_hp)
	Events.boss_defeated.connect(func(_b: Node) -> void: _boss_active = false; play(&"title", 3.0))


func _player() -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = &"Music"
	add_child(player)
	return player


## Crossfade to `track`. The same track twice is a no-op, so a room change
## inside one district does not restart the bed.
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
	next.stream = stream
	next.volume_db = -40.0
	next.play()
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(next, "volume_db", 0.0, fade).set_trans(Tween.TRANS_SINE)
	if previous.playing:
		_tween.tween_property(previous, "volume_db", -40.0, fade).set_trans(Tween.TRANS_SINE)
		_tween.chain().tween_callback(previous.stop)


## Back to silence and no boss, for a test or a fresh title.
func reset() -> void:
	_boss_active = false
	current = &""
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_a.stop()
	_b.stop()


func stop(fade: float = FADE) -> void:
	current = &""
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_active, "volume_db", -40.0, fade)
	_tween.tween_callback(_active.stop)


## A room's bed, from its style in the world graph.
func track_for_room(room_id: StringName) -> StringName:
	var style: String = "residential"
	if _graph != null:
		var entry: Dictionary = _graph.room(room_id)
		style = String(entry.get("style", style))
	return track_for_style(style)


func track_for_style(style: String) -> StringName:
	match style:
		"gut": return &"gut"
		"roof": return &"roof"
		_: return &"stacks"


func _on_room_entered(room_id: StringName) -> void:
	if _boss_active:
		return
	play(track_for_room(room_id))


func _on_boss_hp(_name: String, hp: int, _max_hp: int) -> void:
	if hp <= 0 or _boss_active:
		return
	_boss_active = true
	play(&"boss", 0.8)


func _load(track: StringName) -> AudioStream:
	var path: String = DIR + String(track) + ".ogg"
	if not ResourceLoader.exists(path):
		push_warning("Music: no track named '%s'" % track)
		return null
	var stream: AudioStream = load(path)
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	return stream
