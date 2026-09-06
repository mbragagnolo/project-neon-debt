extends GutTest
## Settings (M7): volumes land on the buses, choices survive a restart, and
## screen shake can be turned off.

var _saved: Dictionary = {}


func before_each() -> void:
	_saved = {
		"master": Settings.master_volume, "music": Settings.music_volume, "sfx": Settings.sfx_volume,
		"shake": Settings.screen_shake, "fullscreen": Settings.fullscreen,
	}


func after_each() -> void:
	Settings.master_volume = _saved["master"]
	Settings.music_volume = _saved["music"]
	Settings.sfx_volume = _saved["sfx"]
	Settings.screen_shake = _saved["shake"]
	Settings.fullscreen = _saved["fullscreen"]
	Settings.apply()
	Settings.save_settings()


func test_the_bus_layout_has_music_and_sfx() -> void:
	assert_gt(AudioServer.get_bus_index(&"Music"), 0)
	assert_gt(AudioServer.get_bus_index(&"SFX"), 0)


func test_a_volume_lands_on_its_bus_in_decibels() -> void:
	Settings.set_volume(&"Music", 0.5)
	var index: int = AudioServer.get_bus_index(&"Music")
	assert_almost_eq(AudioServer.get_bus_volume_db(index), linear_to_db(0.5), 0.01)
	assert_false(AudioServer.is_bus_mute(index))


func test_zero_mutes_and_values_clamp() -> void:
	Settings.set_volume(&"SFX", 0.0)
	assert_true(AudioServer.is_bus_mute(AudioServer.get_bus_index(&"SFX")))
	Settings.set_volume(&"SFX", 1.7)
	assert_eq(Settings.sfx_volume, 1.0)
	assert_false(AudioServer.is_bus_mute(AudioServer.get_bus_index(&"SFX")))
	Settings.set_volume(&"Master", -3.0)
	assert_eq(Settings.master_volume, 0.0)


func test_settings_survive_a_reload() -> void:
	Settings.set_volume(&"Music", 0.3)
	Settings.set_screen_shake(false)
	# Scribble over the live values, then read the file back.
	Settings.music_volume = 1.0
	Settings.screen_shake = true
	Settings.load_settings()
	assert_almost_eq(Settings.music_volume, 0.3, 0.001)
	assert_false(Settings.screen_shake)


func test_screen_shake_off_silences_the_camera_request() -> void:
	var juice := Juice.new()
	add_child_autofree(juice)
	watch_signals(Events)
	Settings.set_screen_shake(false)
	juice.shake(5.0, 0.2)
	assert_signal_not_emitted(Events, "camera_shake_requested")
	Settings.set_screen_shake(true)
	juice.shake(5.0, 0.2)
	assert_signal_emitted(Events, "camera_shake_requested")


func test_the_panel_walks_its_rows_and_changes_a_volume() -> void:
	var panel := SettingsPanel.new()
	add_child_autofree(panel)
	panel.open()
	assert_eq(panel.selected_id(), &"fullscreen")
	panel.handle_input(_action(&"move_down"))
	assert_eq(panel.selected_id(), &"master")
	var before: float = Settings.master_volume
	panel.handle_input(_action(&"move_left"))
	assert_almost_eq(Settings.master_volume, clampf(before - SettingsPanel.VOLUME_STEP, 0.0, 1.0), 0.001)
	panel.handle_input(_action(&"move_up"))
	panel.handle_input(_action(&"move_up"))
	assert_eq(panel.selected_id(), rows_last(panel), "up from the top wraps to the last row")


func test_a_host_row_asks_twice() -> void:
	var panel := SettingsPanel.new()
	panel.extra_rows = [[&"quit_title", "QUIT TO TITLE"]]
	add_child_autofree(panel)
	watch_signals(panel)
	panel.open()
	panel.handle_input(_action(&"move_up"))
	assert_eq(panel.selected_id(), &"quit_title")
	panel.handle_input(_action(&"interact"))
	assert_signal_not_emitted(panel, "action")
	panel.handle_input(_action(&"interact"))
	assert_signal_emitted_with_parameters(panel, "action", [&"quit_title"])


func test_back_closes_the_panel() -> void:
	var panel := SettingsPanel.new()
	add_child_autofree(panel)
	watch_signals(panel)
	panel.open()
	assert_true(panel.handle_input(_action(&"pause")))
	assert_signal_emitted(panel, "closed")


func rows_last(panel: SettingsPanel) -> StringName:
	return panel.rows[panel.rows.size() - 1][0]


func _action(name: StringName) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = name
	event.pressed = true
	return event
