extends Node
## Global hitstop (autoload `Hitstop`).
##
## Freezes the whole combat picture for a beat on connection. Global rather
## than per-entity on purpose: freezing one body reads as lag or a dropped
## frame, while holding everything reads as impact, which is the entire point
## (docs/combat/damage-pipeline.md, hitstop rule 1).
##
## Implemented as `Engine.time_scale = 0`, which is also why the rest of the
## codebase can stay ignorant of it: every `delta` in the game becomes zero, so
## i-frames, jump buffers and attack cooldowns all stop ticking for free. That
## is hitstop rule 3 — frozen frames must be free, or hitstop becomes a stealth
## difficulty spike that eats reaction windows.
##
## The duration is counted in *real* milliseconds, because scaled time cannot
## measure its own suspension.

const CONFIG_PATH := "res://src/combat/combat_config.tres"
const DEFAULT_MAX_SECONDS := 0.5

var _config: CombatConfig
var _end_msec: int = 0
var _active: bool = false


func _ready() -> void:
	# Keep running while the tree is paused, or a pause during hitstop would
	# strand the game at time_scale 0 with nothing left to restore it.
	process_mode = Node.PROCESS_MODE_ALWAYS
	if ResourceLoader.exists(CONFIG_PATH):
		_config = load(CONFIG_PATH) as CombatConfig
	Events.hitstop_requested.connect(_on_hitstop_requested)


func _process(_delta: float) -> void:
	if not _active:
		return
	if Time.get_ticks_msec() >= _end_msec:
		_release()


## Hold for `frames` at the project's physics rate.
##
## Overlapping requests take the maximum remaining, never the sum. Without
## that rule the three-Scav exit test degrades into a slideshow exactly when
## the fight gets interesting — and it would present as a performance bug
## rather than as a tuning mistake.
func request(frames: int) -> void:
	if frames <= 0:
		return
	var seconds: float = float(frames) / float(Engine.physics_ticks_per_second)
	seconds = minf(seconds, _max_seconds())
	var candidate: int = Time.get_ticks_msec() + int(seconds * 1000.0)
	if candidate <= _end_msec and _active:
		return
	_end_msec = candidate
	_engage()


## True while the game is held. Tests and the debug HUD read this.
func is_active() -> bool:
	return _active


## Real milliseconds still to hold. 0 when not active.
func remaining_msec() -> int:
	if not _active:
		return 0
	return maxi(_end_msec - Time.get_ticks_msec(), 0)


func cancel() -> void:
	if _active:
		_release()


func _on_hitstop_requested(frames: int) -> void:
	request(frames)


func _engage() -> void:
	if _active:
		return
	_active = true
	Engine.time_scale = 0.0


func _release() -> void:
	_active = false
	_end_msec = 0
	Engine.time_scale = 1.0


func _max_seconds() -> float:
	return _config.hitstop_max_seconds if _config != null else DEFAULT_MAX_SECONDS


func _exit_tree() -> void:
	# Never leave the engine frozen behind us — a stranded time_scale of 0 is
	# indistinguishable from a hang.
	if _active:
		Engine.time_scale = 1.0
