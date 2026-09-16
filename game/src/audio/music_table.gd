class_name MusicTable
## The music table: written by the godot-integrator's music.py from the composer's audio/music/music.json.
## Do not edit; a track is edited in audio/music/tracks/<track>.json, a mood in bible/moods.json.
##
## TRACKS: per track, its stems in the order the .tres wires them, each with the state that plays it
## (`base` always plays). MOODS: what the Music autoload asks for (a room's style, a screen) -> the track
## and the states it may raise there. STATES: every state the engine raises.

const SILENCE_DB := -60.0
const FADE := 1.2

const TRACKS := {
	&"boss": {
		"class": "fight",
		"tempo": 128.0,
		"bars": 16,
		"seconds": 30.0,
		"layers": [
			{"id": &"drone", "state": &"base"},
			{"id": &"tick", "state": &"base"},
			{"id": &"kick", "state": &"fight"},
			{"id": &"snare", "state": &"fight"},
			{"id": &"hats", "state": &"fight"},
			{"id": &"bass", "state": &"fight"},
			{"id": &"stabs", "state": &"fight"},
			{"id": &"riser", "state": &"fight"},
			{"id": &"lead", "state": &"phase2"},
			{"id": &"heart", "state": &"low"},
		],
	},
	&"gut": {
		"class": "bed",
		"tempo": 60.0,
		"bars": 8,
		"seconds": 32.0,
		"layers": [
			{"id": &"drone", "state": &"base"},
			{"id": &"pad", "state": &"base"},
			{"id": &"throb", "state": &"base"},
			{"id": &"steam", "state": &"base"},
			{"id": &"clanks", "state": &"base"},
			{"id": &"hammer", "state": &"combat"},
			{"id": &"heart", "state": &"low"},
		],
	},
	&"roof": {
		"class": "bed",
		"tempo": 64.0,
		"bars": 8,
		"seconds": 30.0,
		"layers": [
			{"id": &"wind", "state": &"base"},
			{"id": &"pad", "state": &"base"},
			{"id": &"bells", "state": &"base"},
			{"id": &"siren", "state": &"base"},
			{"id": &"drive", "state": &"combat"},
			{"id": &"heart", "state": &"low"},
		],
	},
	&"stacks": {
		"class": "bed",
		"tempo": 68.0,
		"bars": 8,
		"seconds": 28.235294,
		"layers": [
			{"id": &"pad", "state": &"base"},
			{"id": &"rain", "state": &"base"},
			{"id": &"hum", "state": &"base"},
			{"id": &"sub", "state": &"base"},
			{"id": &"thump", "state": &"base"},
			{"id": &"blips", "state": &"base"},
			{"id": &"pulse", "state": &"combat"},
			{"id": &"heart", "state": &"low"},
		],
	},
	&"title": {
		"class": "title",
		"tempo": 60.0,
		"bars": 8,
		"seconds": 32.0,
		"layers": [
			{"id": &"pad", "state": &"base"},
			{"id": &"rain", "state": &"base"},
			{"id": &"theme", "state": &"base"},
			{"id": &"sub", "state": &"base"},
		],
	},
}

const MOODS := {
	&"residential": {"track": &"stacks", "states": [&"combat", &"low"]},
	&"mezz": {"track": &"stacks", "states": [&"combat", &"low"]},
	&"shaft": {"track": &"stacks", "states": [&"combat", &"low"]},
	&"gut": {"track": &"gut", "states": [&"combat", &"low"]},
	&"roof": {"track": &"roof", "states": [&"combat", &"low"]},
	&"collections": {"track": &"boss", "states": [&"fight", &"phase2", &"low"]},
	&"title": {"track": &"title", "states": []},
}

const STATES: Array[StringName] = [&"combat", &"fight", &"low", &"phase2"]
