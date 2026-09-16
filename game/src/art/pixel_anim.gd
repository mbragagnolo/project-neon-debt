class_name PixelAnim
extends Sprite2D
## A sprite sheet with named clips (docs/art/direction.md).
##
## Sheets come out of `tools/art/make_*.py` as one row of uniform frames,
## pre-scaled 3x; `clips` is the table the generator prints:
## name -> [first frame, frame count, fps, loops]. `play()` is idempotent,
## so a state can call it every physics frame without restarting the clip.

@export var frame_width: int = 66
@export var frame_height: int = 96
## name -> [start: int, count: int, fps: float, loop: bool]
@export var clips: Dictionary = {}
@export var autoplay: StringName = &"idle"

var current: StringName = &""
var _time: float = 0.0
var _index: int = 0
var _done: bool = false


func _ready() -> void:
	centered = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if texture != null and frame_width > 0:
		hframes = maxi(1, texture.get_width() / frame_width)
		vframes = maxi(1, texture.get_height() / frame_height)
	if autoplay != &"":
		play(autoplay)


func has_clip(clip: StringName) -> bool:
	return clips.has(String(clip))


func play(clip: StringName, restart: bool = false) -> void:
	if not has_clip(clip):
		return
	if clip == current and not restart:
		return
	current = clip
	_index = 0
	_time = 0.0
	_done = false
	frame = int(clips[String(clip)][0])


func is_done() -> bool:
	return _done


func _process(delta: float) -> void:
	if current == &"" or _done:
		return
	var clip: Array = clips[String(current)]
	var fps: float = float(clip[2])
	if fps <= 0.0 or int(clip[1]) <= 1:
		return
	_time += delta
	var step: float = 1.0 / fps
	while _time >= step:
		_time -= step
		_index += 1
		if _index >= int(clip[1]):
			if bool(clip[3]):
				_index = 0
			else:
				_index = int(clip[1]) - 1
				_done = true
		frame = int(clip[0]) + _index
