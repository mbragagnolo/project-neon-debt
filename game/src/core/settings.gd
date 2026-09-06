extends Node
## Settings (autoload `Settings`): what the player set on the title screen
## and the pause shell, kept in user://settings.cfg across runs.
##
## Volumes are linear 0..1 and land on the audio buses; fullscreen lands on
## the window. Nothing else in the game reads the file: it asks here.

const PATH := "user://settings.cfg"

signal changed

var fullscreen: bool = false
var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 1.0
var screen_shake: bool = true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_settings()
	apply()


func load_settings() -> void:
	var file := ConfigFile.new()
	if file.load(PATH) != OK:
		return
	fullscreen = bool(file.get_value("video", "fullscreen", fullscreen))
	master_volume = clampf(float(file.get_value("audio", "master", master_volume)), 0.0, 1.0)
	music_volume = clampf(float(file.get_value("audio", "music", music_volume)), 0.0, 1.0)
	sfx_volume = clampf(float(file.get_value("audio", "sfx", sfx_volume)), 0.0, 1.0)
	screen_shake = bool(file.get_value("video", "screen_shake", screen_shake))


func save_settings() -> void:
	var file := ConfigFile.new()
	file.set_value("video", "fullscreen", fullscreen)
	file.set_value("video", "screen_shake", screen_shake)
	file.set_value("audio", "master", master_volume)
	file.set_value("audio", "music", music_volume)
	file.set_value("audio", "sfx", sfx_volume)
	file.save(PATH)


## Everything at once: the buses, the window. Safe to call headless.
func apply() -> void:
	_set_bus(&"Master", master_volume)
	_set_bus(&"Music", music_volume)
	_set_bus(&"SFX", sfx_volume)
	if DisplayServer.get_name() != "headless":
		var want: DisplayServer.WindowMode = DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != want:
			DisplayServer.window_set_mode(want)
	changed.emit()


func set_fullscreen(value: bool) -> void:
	fullscreen = value
	apply()
	save_settings()


func set_volume(bus: StringName, value: float) -> void:
	value = clampf(value, 0.0, 1.0)
	match bus:
		&"Master": master_volume = value
		&"Music": music_volume = value
		&"SFX": sfx_volume = value
	apply()
	save_settings()


func set_screen_shake(value: bool) -> void:
	screen_shake = value
	apply()
	save_settings()


func volume(bus: StringName) -> float:
	match bus:
		&"Master": return master_volume
		&"Music": return music_volume
		&"SFX": return sfx_volume
	return 1.0


func _set_bus(bus: StringName, linear: float) -> void:
	var index: int = AudioServer.get_bus_index(bus)
	if index < 0:
		return
	AudioServer.set_bus_mute(index, linear <= 0.001)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(linear, 0.001)))
