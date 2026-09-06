extends GutTest
## Sound and music (M7; docs/audio/direction.md): every id the Sfx autoload
## answers with exists on disk, the music follows the district's styles, and
## the boss takes the room over until he is down.

const SFX_SCRIPT := "res://src/audio/sfx.gd"
const TRACKS: Array[StringName] = [&"stacks", &"gut", &"roof", &"boss", &"title"]
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


func test_every_track_exists_and_loops() -> void:
	for track: StringName in TRACKS:
		var path: String = Music.DIR + String(track) + ".ogg"
		assert_true(ResourceLoader.exists(path), "missing track: %s" % track)
		var stream: AudioStream = Music._load(track)
		assert_not_null(stream)
		if stream is AudioStreamOggVorbis:
			assert_true((stream as AudioStreamOggVorbis).loop)


func test_styles_pick_their_beds() -> void:
	assert_eq(Music.track_for_style("gut"), &"gut")
	assert_eq(Music.track_for_style("roof"), &"roof")
	assert_eq(Music.track_for_style("residential"), &"stacks")
	assert_eq(Music.track_for_style("mezz"), &"stacks")
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
	Events.room_entered.emit(&"unit_14c")
	assert_eq(Music.current, &"boss", "a room change mid-fight does not drop the boss track")
	Events.boss_defeated.emit(null)
	assert_eq(Music.current, &"title")
	Events.room_entered.emit(&"unit_14c")
	assert_eq(Music.current, &"stacks")


func test_the_same_track_twice_is_one_play() -> void:
	Music.play(&"stacks")
	var active: AudioStreamPlayer = Music._active
	Music.play(&"stacks")
	assert_eq(Music._active, active)


func test_playing_an_unknown_sound_is_harmless() -> void:
	Sfx.play(&"no_such_sound")
	assert_false(Sfx.has(&"no_such_sound"))
	pass_test("no crash")
