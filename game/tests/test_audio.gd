extends GutTest
## Sound and music (M7; docs/audio/direction.md): every id the Sfx autoload
## answers with exists on disk, every track in the composer's table is a
## synchronized stream of looping stems, the music follows the district's
## styles through the moods table, the states raise and drop their stems,
## and the boss takes the room over until he is down.

const SFX_SCRIPT := "res://src/audio/sfx.gd"
const STYLES: Array[String] = ["residential", "mezz", "shaft", "gut", "roof", "collections"]


func after_each() -> void:
	Music.reset()


func test_every_sound_the_bus_mapping_names_exists() -> void:
	var source: String = (load(SFX_SCRIPT) as GDScript).source_code
	var regex := RegEx.new()
	regex.compile("play\\(&\"([a-z_]+)\"")
	var seen: Dictionary = {}
	for found: RegExMatch in regex.search_all(source):
		var id: StringName = StringName(found.get_string(1))
		if seen.has(id):
			continue
		seen[id] = true
		assert_true(Sfx.has(id), "missing sound: %s" % id)
	assert_gt(seen.size(), 30, "the mapping should name most of the library")


func test_every_track_is_a_synchronized_stream_of_looping_stems() -> void:
	assert_gt(MusicTable.TRACKS.size(), 3, "the table should have the district beds, the boss and the title")
	for track: StringName in MusicTable.TRACKS:
		var path: String = Music.DIR + String(track) + ".tres"
		assert_true(ResourceLoader.exists(path), "missing track: %s" % track)
		var stream: AudioStream = Music._load(track)
		assert_not_null(stream)
		var sync := stream as AudioStreamSynchronized
		assert_not_null(sync, "%s is not an AudioStreamSynchronized" % track)
		if sync == null:
			continue
		var layers: Array = MusicTable.TRACKS[track]["layers"]
		assert_eq(sync.stream_count, layers.size(), "%s: stems in the .tres against the table" % track)
		for i in range(sync.stream_count):
			var stem: AudioStream = sync.get_sync_stream(i)
			assert_not_null(stem, "%s: stem %d is empty" % [track, i])
			if stem is AudioStreamOggVorbis:
				assert_true((stem as AudioStreamOggVorbis).loop, "%s/%s does not loop" % [track, layers[i]["id"]])
			var on: bool = layers[i]["state"] == &"base"
			assert_eq(sync.get_sync_stream_volume(i), 0.0 if on else MusicTable.SILENCE_DB, "%s/%s at rest" % [track, layers[i]["id"]])


func test_every_style_has_a_mood_and_every_mood_a_track() -> void:
	for style: String in STYLES:
		assert_true(MusicTable.MOODS.has(StringName(style)), "no mood for style %s" % style)
	assert_true(MusicTable.MOODS.has(&"title"))
	for mood: StringName in MusicTable.MOODS:
		var track: StringName = MusicTable.MOODS[mood]["track"]
		assert_true(MusicTable.TRACKS.has(track), "mood %s names track %s, not in the table" % [mood, track])
		for state: StringName in MusicTable.MOODS[mood]["states"]:
			assert_true(state in MusicTable.STATES, "mood %s raises unknown state %s" % [mood, state])


func test_styles_pick_their_beds() -> void:
	assert_eq(Music.track_for_style("gut"), &"gut")
	assert_eq(Music.track_for_style("roof"), &"roof")
	assert_eq(Music.track_for_style("residential"), &"stacks")
	assert_eq(Music.track_for_style("mezz"), &"stacks")
	assert_eq(Music.track_for_style("collections"), &"boss")
	assert_eq(Music.track_for_style("no_such_style"), &"stacks", "an unknown style plays the default mood")
	assert_eq(Music.track_for_room(&"gut_pumps"), &"gut")
	assert_eq(Music.track_for_room(&"roof_span"), &"roof")
	assert_eq(Music.track_for_room(&"unit_14c"), &"stacks")


func test_every_room_in_the_graph_has_a_known_style() -> void:
	var graph: WorldGraph = load(Music.GRAPH_PATH)
	for entry: Dictionary in graph.rooms:
		assert_true(String(entry.get("style", "")) in STYLES, "%s: style %s" % [entry.get("id"), entry.get("style")])


func test_rooms_change_the_bed_and_the_boss_holds_it() -> void:
	Events.room_entered.emit(&"unit_14c")
	assert_eq(Music.current, &"stacks")
	Events.room_entered.emit(&"gut_pumps")
	assert_eq(Music.current, &"gut")
	Events.boss_hp_changed.emit("The Landlord", 240, 240)
	assert_eq(Music.current, &"boss")
	assert_true(Music.states[&"fight"], "the bar up raises the fight")
	Events.room_entered.emit(&"unit_14c")
	assert_eq(Music.current, &"boss", "a room change mid-fight does not drop the boss track")
	Events.boss_phase_changed.emit(2)
	assert_true(Music.states[&"phase2"])
	Events.boss_defeated.emit(null)
	assert_eq(Music.current, &"title")
	assert_false(Music.states[&"fight"])
	assert_false(Music.states[&"phase2"])
	Events.room_entered.emit(&"unit_14c")
	assert_eq(Music.current, &"stacks")


func test_a_state_targets_its_stems_and_leaves_the_base_alone() -> void:
	Music.play(&"boss")
	assert_eq(Music.layer_target(&"drone"), 0.0, "a base stem is on")
	assert_eq(Music.layer_target(&"kick"), MusicTable.SILENCE_DB, "a fight stem is silent before the fight")
	assert_eq(Music.layer_volume(&"kick"), MusicTable.SILENCE_DB)
	Music.set_state(&"fight", true)
	assert_eq(Music.layer_target(&"kick"), 0.0)
	assert_eq(Music.layer_target(&"lead"), MusicTable.SILENCE_DB, "phase2 is not fight")
	assert_eq(Music.layer_target(&"drone"), 0.0)
	Music.set_state(&"phase2", true)
	assert_eq(Music.layer_target(&"lead"), 0.0)
	Music.set_state(&"fight", false)
	assert_eq(Music.layer_target(&"kick"), MusicTable.SILENCE_DB)
	assert_eq(Music.layer_target(&"lead"), 0.0, "dropping one state leaves another")


func test_a_state_fades_its_stems_over_the_table_fade() -> void:
	# `low`, not `combat`: the autoload re-derives combat from the enemies every poll.
	Music.play(&"stacks")
	Music.set_state(&"low", true)
	await wait_seconds(MusicTable.FADE * 0.5)
	var mid: float = Music.layer_volume(&"heart")
	assert_gt(mid, MusicTable.SILENCE_DB, "halfway the heart is on its way in")
	assert_lt(mid, 0.0)
	await wait_seconds(MusicTable.FADE * 0.6)
	assert_almost_eq(Music.layer_volume(&"heart"), 0.0, 0.01, "after the fade the heart is on")
	assert_almost_eq(Music.layer_volume(&"pad"), 0.0, 0.01, "the base stem never moved")
	Music.set_state(&"low", false)
	await wait_seconds(MusicTable.FADE * 1.1)
	assert_almost_eq(Music.layer_volume(&"heart"), MusicTable.SILENCE_DB, 0.01)


func test_low_hp_raises_the_heart() -> void:
	Music.play(&"gut")
	Events.hp_changed.emit(3, 10)
	assert_true(Music.states[&"low"])
	assert_eq(Music.layer_target(&"heart"), 0.0)
	Events.hp_changed.emit(8, 10)
	assert_false(Music.states[&"low"])
	assert_eq(Music.layer_target(&"heart"), MusicTable.SILENCE_DB)


func test_states_carry_across_a_track_change() -> void:
	Music.play(&"stacks")
	Events.hp_changed.emit(1, 10)
	Music.play(&"roof")
	assert_eq(Music.layer_target(&"heart"), 0.0, "the new track starts with the low stem on")
	assert_eq(Music.layer_volume(&"heart"), 0.0, "and at volume, not fading in")


func test_the_same_track_twice_is_one_play() -> void:
	Music.play(&"stacks")
	var active: AudioStreamPlayer = Music._active
	Music.play(&"stacks")
	assert_eq(Music._active, active)


func test_playing_an_unknown_sound_is_harmless() -> void:
	Sfx.play(&"no_such_sound")
	assert_false(Sfx.has(&"no_such_sound"))
	pass_test("no crash")
