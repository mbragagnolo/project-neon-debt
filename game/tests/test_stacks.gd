extends GutTest
## The district as data (docs/level-design/stacks.md).
##
## Reads the room specs straight from `tools/stacks/` and holds them to the
## promises DESIGN.md makes: every door leads somewhere that leads back,
## every room can be reached, every ability gate sits beyond the reach of the
## kit before it, every item is where items.md put it, and the progression
## order is the locked one. These are the breakages a level edit makes
## silently — a door retargeted to the wrong digit reads fine in a diff and
## strands the player in play.

const SPEC_DIR := "res://tools/stacks"
const START := &"unit_14c"

var _specs: Array[RoomSpec] = []
var _by_id: Dictionary = {}
var _envelope: MovementEnvelope


func before_all() -> void:
	_specs = RoomSpec.load_all(SPEC_DIR)
	for spec: RoomSpec in _specs:
		_by_id[spec.id] = spec
	_envelope = MovementEnvelope.from_project()


func _spec(room_id: StringName) -> RoomSpec:
	return _by_id.get(room_id) as RoomSpec


# --- The specs themselves -----------------------------------------------------

func test_every_spec_parses_clean() -> void:
	assert_gt(_specs.size(), 0, "no specs found")
	for spec: RoomSpec in _specs:
		for error: String in spec.errors:
			fail_test(error)
	pass_test("%d specs" % _specs.size())


func test_the_room_budget() -> void:
	# DESIGN.md §2: ~25–35 connected rooms.
	assert_between(_specs.size(), 25, 35, "%d rooms" % _specs.size())


func test_room_ids_are_unique_and_match_their_files() -> void:
	var seen: Dictionary = {}
	for spec: RoomSpec in _specs:
		assert_false(seen.has(spec.id), "duplicate room id %s" % spec.id)
		seen[spec.id] = true
		assert_true(spec.source.ends_with("/%s.room" % spec.id), "%s lives in %s" % [spec.id, spec.source])


func test_only_the_flat_has_a_player_start() -> void:
	for spec: RoomSpec in _specs:
		var starts: int = spec.positions_of("P").size()
		if spec.id == START:
			assert_eq(starts, 1, "the flat needs exactly one start")
		else:
			assert_eq(starts, 0, "%s has a player start" % spec.id)


# --- Doors ----------------------------------------------------------------------

func test_every_door_has_a_partner_that_points_back() -> void:
	for spec: RoomSpec in _specs:
		for digit: String in spec.doors:
			var link: Dictionary = spec.doors[digit]
			var target: RoomSpec = _spec(StringName(link["target_room"]))
			assert_not_null(target, "%s door %s leads to unknown room %s" % [spec.id, digit, link["target_room"]])
			if target == null:
				continue
			var back: Dictionary = target.doors.get(link["target_door"], {})
			assert_false(back.is_empty(), "%s door %s leads to %s door %s, which does not exist" % [spec.id, digit, target.id, link["target_door"]])
			if back.is_empty():
				continue
			assert_eq(String(back["target_room"]), String(spec.id), "%s:%s -> %s:%s does not point back" % [spec.id, digit, target.id, link["target_door"]])
			assert_eq(String(back["target_door"]), digit, "%s:%s -> %s:%s points back at the wrong door" % [spec.id, digit, target.id, link["target_door"]])


func test_door_partners_face_each_other_on_the_map() -> void:
	# A left door's partner is the room to the left, on the same row of
	# cells. Anything else draws as a corridor to nowhere on the map.
	for spec: RoomSpec in _specs:
		var regions: Dictionary = spec.door_regions()
		for digit: String in regions:
			var rect: Rect2i = regions[digit]
			var side: int = spec.door_side(rect)
			var here: Vector2i = spec.cell + spec.door_cell(rect)
			var target: RoomSpec = _spec(StringName(spec.doors[digit]["target_room"]))
			if target == null:
				continue
			var there_regions: Dictionary = target.door_regions()
			var there_rect: Rect2i = there_regions.get(spec.doors[digit]["target_door"], Rect2i())
			var there: Vector2i = target.cell + target.door_cell(there_rect)
			var expected: Vector2i = here
			match side:
				Door.Side.LEFT: expected = here + Vector2i(-1, 0)
				Door.Side.RIGHT: expected = here + Vector2i(1, 0)
				Door.Side.UP: expected = here + Vector2i(0, -1)
				Door.Side.DOWN: expected = here + Vector2i(0, 1)
			assert_eq(there, expected, "%s door %s is at cell %s facing %d; its partner in %s is at %s" % [spec.id, digit, here, side, target.id, there])
			var opposite: int = [Door.Side.RIGHT, Door.Side.LEFT, Door.Side.DOWN, Door.Side.UP][side]
			assert_eq(target.door_side(there_rect), opposite, "%s door %s and %s door %s are not on facing walls" % [spec.id, digit, target.id, spec.doors[digit]["target_door"]])


func test_side_doors_open_onto_a_floor() -> void:
	# The arrival spawn stands a tile and a half in; there must be ground
	# under the door run's bottom row, or every arrival is a fall.
	for spec: RoomSpec in _specs:
		var regions: Dictionary = spec.door_regions()
		for digit: String in regions:
			var rect: Rect2i = regions[digit]
			var side: int = spec.door_side(rect)
			if side != Door.Side.LEFT and side != Door.Side.RIGHT:
				continue
			var x: int = rect.end.x if side == Door.Side.LEFT else rect.position.x - 1
			assert_true(spec.is_solid(x, rect.end.y), "%s door %s has no floor under it at %d,%d" % [spec.id, digit, x, rect.end.y])
			assert_true(spec.is_air(x, rect.end.y - 1), "%s door %s opens into a wall at %d,%d" % [spec.id, digit, x, rect.end.y - 1])


func test_every_room_is_reachable_from_the_flat() -> void:
	var reached: Dictionary = _reachable({"mag_hook": true, "cyberdeck": true, "breach": true, "sidewinder": true})
	for spec: RoomSpec in _specs:
		assert_true(reached.has(spec.id), "%s cannot be reached with the whole kit" % spec.id)


# --- Progression --------------------------------------------------------------

## Rooms reachable from the flat with a given kit, with the kit growing as
## pickups are reached. Doors and markers can be annotated `requires`.
func _reachable(kit: Dictionary) -> Dictionary:
	var owned: Dictionary = kit.duplicate()
	var reached: Dictionary = {}
	var changed := true
	while changed:
		changed = false
		reached.clear()
		var frontier: Array[StringName] = [START]
		reached[START] = true
		while not frontier.is_empty():
			var current: RoomSpec = _spec(frontier.pop_back())
			if current == null:
				continue
			for digit: String in current.doors:
				var need: String = current.requires.get(digit, "")
				if need != "" and not owned.has(need):
					continue
				if current.oneway.has(digit):
					continue
				var next: StringName = StringName(current.doors[digit]["target_room"])
				if not reached.has(next):
					reached[next] = true
					frontier.append(next)
		# Grow the kit from what was reached, then walk again.
		for room_id: StringName in reached:
			var spec: RoomSpec = _spec(room_id)
			for c: String in spec.markers:
				if spec.positions_of(c).is_empty():
					continue
				var need: String = spec.requires.get(c, "")
				if need != "" and not owned.has(need):
					continue
				var marker: Dictionary = spec.markers[c]
				var grant: String = ""
				match marker["type"]:
					"ability":
						match marker["args"]:
							"ability.mag_hook": grant = "mag_hook"
							"ability.cyberdeck": grant = "cyberdeck"
							"item.sidewinder_carried": grant = "sidewinder_carried"
					"hack":
						grant = marker["args"]
				if grant != "" and not owned.has(grant):
					owned[grant] = true
					changed = true
		# Implants are surgery: the carried unit becomes the ability at Stitch.
		if owned.has("sidewinder_carried") and reached.has(&"mezz") and not owned.has("sidewinder"):
			owned["sidewinder"] = true
			changed = true
	return reached


func _reachable_with(abilities: Array[String]) -> Dictionary:
	var kit: Dictionary = {}
	for ability: String in abilities:
		kit[ability] = true
	return _reachable(kit)


func test_the_first_screens_need_nothing() -> void:
	var reached: Dictionary = _reachable({})
	for room_id: StringName in [&"unit_14c", &"hall_14", &"stairwell_east", &"hall_13", &"maintenance_closet"] as Array[StringName]:
		assert_true(reached.has(room_id), "%s should be reachable from a cold start" % room_id)


func test_the_mag_hook_is_the_first_gate() -> void:
	# The closet is reachable cold and hands out the Hook; the roof is not
	# reachable without it. The walk itself grows the kit, so the assertion
	# is on what a run that *never* picks it up can see.
	var without: Dictionary = _reachable_without(["mag_hook"])
	assert_false(without.has(&"roof_access"), "the roof is reachable without the Mag-Hook")
	assert_false(without.has(&"mezz"), "the hub is reachable without the Mag-Hook")


func test_the_cyberdeck_precedes_every_found_program() -> void:
	# hacks.md: the quickslot is the deck's, so Overload and Breach must sit
	# past it. The deck gates no door — it is a room on the only way to the
	# east lift, so a walk that never enters it never reaches a program.
	var skipping_the_deck: Dictionary = _reachable_without([], [&"pawn_back"])
	assert_false(skipping_the_deck.has(&"server_nook"), "Overload is reachable without passing the Cyberdeck")
	assert_false(skipping_the_deck.has(&"breach_gate_room"), "Breach is reachable without passing the Cyberdeck")
	assert_true(_reachable({}).has(&"pawn_back"), "the deck itself is not reachable on the way")


func test_every_room_can_be_left_the_way_it_was_entered_or_another() -> void:
	# No room may be a trap: with the whole kit, every room reaches the hub.
	# One-way drops and grates are modelled, so a drop into a dead end fails
	# here rather than in a playtest.
	for spec: RoomSpec in _specs:
		var back: Dictionary = _reachable_from(spec.id, {"mag_hook": true, "cyberdeck": true, "breach": true, "sidewinder": true})
		assert_true(back.has(&"mezz"), "%s cannot get back to the Mezz with the whole kit" % spec.id)


func test_the_gut_is_not_a_trap_before_breach() -> void:
	# A player can drop into the Gut from the Mezz before owning Breach. The
	# bulkhead stops them at the lift; the way they came must still be open.
	var back: Dictionary = _reachable_from(&"gut_lift", {"mag_hook": true, "cyberdeck": true})
	assert_true(back.has(&"mezz"), "the Gut traps a player without Breach")


## Rooms reachable from `origin` with a fixed kit, honouring one-way doors.
func _reachable_from(origin: StringName, kit: Dictionary) -> Dictionary:
	var reached: Dictionary = {origin: true}
	var frontier: Array[StringName] = [origin]
	while not frontier.is_empty():
		var current: RoomSpec = _spec(frontier.pop_back())
		for digit: String in current.doors:
			var need: String = current.requires.get(digit, "")
			if need != "" and not kit.has(need):
				continue
			if current.oneway.has(digit):
				continue
			var next: StringName = StringName(current.doors[digit]["target_room"])
			if not reached.has(next):
				reached[next] = true
				frontier.append(next)
	return reached


func test_breach_gates_the_maul_and_the_gut_below_the_lift() -> void:
	var without: Dictionary = _reachable_without(["breach"])
	assert_false(without.has(&"armory"), "the maul's room is reachable without Breach")
	assert_false(without.has(&"defaulter_den"), "the sump is reachable without Breach")
	assert_false(without.has(&"gut_deep"), "the Sidewinder is reachable without Breach")
	assert_true(without.has(&"breach_gate_room"), "the Breach program itself must be reachable")


func test_the_sidewinder_gates_collections_and_the_riveter() -> void:
	var without: Dictionary = _reachable_without(["sidewinder"])
	assert_false(without.has(&"collections"), "the boss is reachable without the Sidewinder")
	assert_false(without.has(&"collections_lobby"), "the last terminal is reachable without the Sidewinder")
	assert_true(without.has(&"catwalks"), "the catwalks' door should be open; only the gate inside needs the implant")
	var catwalks: RoomSpec = _spec(&"catwalks")
	assert_eq(catwalks.requires.get("g", ""), "sidewinder", "the rivet gun is not behind the air-dash gate")


## Reachability when the named abilities are never granted and the named
## rooms are never entered, however far the walk goes.
func _reachable_without(blocked: Array[String], avoiding: Array[StringName] = []) -> Dictionary:
	var owned: Dictionary = {}
	var reached: Dictionary = {}
	var changed := true
	while changed:
		changed = false
		reached.clear()
		var frontier: Array[StringName] = [START]
		reached[START] = true
		while not frontier.is_empty():
			var current: RoomSpec = _spec(frontier.pop_back())
			for digit: String in current.doors:
				var need: String = current.requires.get(digit, "")
				if need != "" and not owned.has(need):
					continue
				if current.oneway.has(digit) or avoiding.has(StringName(current.doors[digit]["target_room"])):
					continue
				var next: StringName = StringName(current.doors[digit]["target_room"])
				if not reached.has(next):
					reached[next] = true
					frontier.append(next)
		for room_id: StringName in reached:
			var spec: RoomSpec = _spec(room_id)
			for c: String in spec.markers:
				if spec.positions_of(c).is_empty():
					continue
				var need: String = spec.requires.get(c, "")
				if need != "" and not owned.has(need):
					continue
				var marker: Dictionary = spec.markers[c]
				var grant: String = ""
				match marker["type"]:
					"ability":
						match marker["args"]:
							"ability.mag_hook": grant = "mag_hook"
							"ability.cyberdeck": grant = "cyberdeck"
							"item.sidewinder_carried": grant = "sidewinder_carried"
					"hack":
						grant = marker["args"]
				if grant != "" and not blocked.has(grant) and not owned.has(grant):
					owned[grant] = true
					changed = true
		if owned.has("sidewinder_carried") and reached.has(&"mezz") and not owned.has("sidewinder") and not blocked.has("sidewinder"):
			owned["sidewinder"] = true
			changed = true
	return reached


# --- Gates against the envelope ------------------------------------------------

func test_air_dash_gates_measure_up() -> void:
	var count: int = 0
	for spec: RoomSpec in _specs:
		for gate: Dictionary in spec.gates:
			if gate["kind"] != "air_dash":
				continue
			count += 1
			var v: Array = gate["values"]
			var x1: int = v[0]
			var y: int = v[1]
			var x2: int = v[2]
			assert_true(spec.is_solid(x1, y), "%s: the near lip at %d,%d is not solid" % [spec.id, x1, y])
			assert_true(spec.is_solid(x2, y), "%s: the far lip at %d,%d is not solid" % [spec.id, x2, y])
			for x: int in range(x1 + 1, x2):
				assert_false(spec.is_solid(x, y), "%s: the gap has ground at %d,%d" % [spec.id, x, y])
				assert_false(spec.is_solid(x, y - 1), "%s: the gap is blocked above at %d,%d" % [spec.id, x, y - 1])
			var gap: float = float(x2 - x1 - 1) * RoomSpec.TILE
			assert_true(_envelope.is_valid_air_dash_gate(gap),
				"%s: a %.0fpx gap is not a valid Sidewinder gate (kit reach %.0f, implant reach %.0f)" % [spec.id, gap, _envelope.max_gap(false), _envelope.max_gap(true)])
	assert_gte(count, 2, "the district needs at least two Sidewinder gates")


func test_shafts_are_climbable_with_the_hook() -> void:
	var count: int = 0
	for spec: RoomSpec in _specs:
		for gate: Dictionary in spec.gates:
			if gate["kind"] != "shaft":
				continue
			count += 1
			var v: Array = gate["values"]
			var x1: int = v[0]
			var x2: int = v[1]
			var y0: int = v[2]
			var y1: int = v[3]
			for y: int in range(y0, y1 + 1):
				assert_true(spec.is_solid(x1 - 1, y), "%s: the shaft's left wall is missing at %d,%d" % [spec.id, x1 - 1, y])
				assert_true(spec.is_solid(x2 + 1, y), "%s: the shaft's right wall is missing at %d,%d" % [spec.id, x2 + 1, y])
				for x: int in range(x1, x2 + 1):
					assert_false(spec.is_solid(x, y), "%s: the shaft is blocked at %d,%d" % [spec.id, x, y])
			var width: float = float(x2 - x1 + 1) * RoomSpec.TILE
			assert_true(_envelope.is_climbable_shaft(width), "%s: a %.0fpx shaft is too wide for the Mag-Hook" % [spec.id, width])
	assert_gte(count, 3, "the district needs its Mag-Hook shafts declared")


func test_teases_are_out_of_reach_of_the_whole_kit() -> void:
	# A high single-wall ledge: higher than a jump by the margin, and no
	# facing wall within a wall jump's reach on either side.
	var count: int = 0
	var reach_tiles: int = ceili(_envelope.wall_jump_reach() / RoomSpec.TILE) + 1
	for spec: RoomSpec in _specs:
		for gate: Dictionary in spec.gates:
			if gate["kind"] != "tease":
				continue
			count += 1
			var v: Array = gate["values"]
			var x: int = v[0]
			var y: int = v[1]
			var ledge_row: int = y + 1
			assert_true(spec.is_solid(x, ledge_row), "%s: the tease at %d,%d stands on air" % [spec.id, x, y])
			assert_true(spec.has_marker_type("tease"), "%s declares a tease gate without a tease marker" % spec.id)
			# The ledge's extent along its row.
			var left: int = x
			while spec.is_solid(left - 1, ledge_row):
				left -= 1
			var right: int = x
			while spec.is_solid(right + 1, ledge_row):
				right += 1
			# The drop beside each end, to the first ground.
			for side_x: int in [left - 1, right + 1]:
				var floor_row: int = ledge_row
				while floor_row < spec.height() and not spec.is_solid(side_x, floor_row):
					floor_row += 1
				var height: float = float(floor_row - ledge_row) * RoomSpec.TILE
				assert_true(_envelope.is_valid_tease_height(height),
					"%s: the tease ledge is only %.0fpx above the ground at column %d" % [spec.id, height, side_x])
			# No facing wall in reach for the band a wall jump could use.
			for row: int in range(ledge_row, ledge_row + 4):
				for dx: int in range(2, reach_tiles + 1):
					assert_false(spec.is_solid(left - dx, row) and spec.is_air(left - 1, row),
						"%s: a wall %d tiles left of the tease ledge makes a shaft" % [spec.id, dx])
					assert_false(spec.is_solid(right + dx, row) and spec.is_air(right + 1, row),
						"%s: a wall %d tiles right of the tease ledge makes a shaft" % [spec.id, dx])
	assert_between(count, 2, 3, "DESIGN.md §2 wants 2–3 double-jump teases; found %d" % count)


# --- Placement (docs/rpg/items.md) -------------------------------------------

func _pickups_of(type: String) -> Dictionary:
	var out: Dictionary = {}
	for spec: RoomSpec in _specs:
		for marker: Dictionary in spec.markers_of_type(type):
			var key: String = String(marker["args"])
			out[key] = out.get(key, []) + [String(spec.id)]
	return out


func test_the_six_found_items_are_each_placed_once_where_items_md_put_them() -> void:
	var placed: Dictionary = _pickups_of("item")
	var expected: Dictionary = {
		"utility_blade": "east_ledges",
		"work_boots": "underpass",
		"nailgun": "gut_vent",
		"linesman_gloves": "gut_cistern",
		"breaker_maul": "armory",
		"rivet_gun": "catwalks",
	}
	for item_id: String in expected:
		assert_true(placed.has(item_id), "%s is not in the district" % item_id)
		if placed.has(item_id):
			assert_eq(placed[item_id].size(), 1, "%s is placed %d times" % [item_id, placed[item_id].size()])
			assert_eq(placed[item_id][0], expected[item_id], "%s is in %s, not %s" % [item_id, placed[item_id][0], expected[item_id]])
	# The jacket is bought and the hardhat is earned; neither lies on a floor.
	assert_false(placed.has("padded_jacket"), "the jacket is vendor stock, not a chest")
	assert_false(placed.has("scavved_hardhat"), "the hardhat is the quest reward, not a chest")
	assert_eq(placed.size(), 6, "an unexpected item is placed: %s" % str(placed.keys()))


func test_programs_and_abilities_are_placed_once_in_the_locked_order_rooms() -> void:
	var hacks: Dictionary = _pickups_of("hack")
	assert_eq(hacks.get("overload", []), ["server_nook"])
	assert_eq(hacks.get("breach", []), ["breach_gate_room"])
	assert_false(hacks.has("firewall"), "Firewall is factory-installed")
	var abilities: Dictionary = _pickups_of("ability")
	assert_eq(abilities.get("ability.mag_hook", []), ["maintenance_closet"])
	assert_eq(abilities.get("ability.cyberdeck", []), ["pawn_back"])
	assert_eq(abilities.get("item.sidewinder_carried", []), ["gut_deep"])
	var quest_items: Dictionary = _pickups_of("quest_item")
	assert_eq(quest_items.get("memory_chip", []), ["defaulter_den"])


func test_stat_pickups_terminals_and_teases_meet_the_budget() -> void:
	var hp: int = 0
	var ram: int = 0
	var saves: int = 0
	var teases: int = 0
	for spec: RoomSpec in _specs:
		hp += spec.markers_of_type("hp_up").size()
		ram += spec.markers_of_type("ram_up").size()
		saves += spec.markers_of_type("save").size()
		teases += spec.markers_of_type("tease").size()
	assert_between(hp, 2, 3, "HP Max Ups: %d" % hp)
	assert_between(ram, 2, 3, "RAM Max Ups: %d" % ram)
	assert_between(saves, 2, 3, "care terminals: %d" % saves)
	assert_between(teases, 2, 3, "teases: %d" % teases)


func test_the_hub_has_the_vendor_the_neighbour_and_a_terminal() -> void:
	var mezz: RoomSpec = _spec(&"mezz")
	assert_not_null(mezz)
	var npcs: Array = []
	for marker: Dictionary in mezz.markers_of_type("npc"):
		npcs.append(String(marker["args"]))
	assert_has(npcs, "stitch")
	assert_has(npcs, "marisol")
	assert_true(mezz.has_marker_type("save"), "the hub has no care terminal")


func test_the_shortcut_loops_exist() -> void:
	# DESIGN.md §3.4: one stat-check-free shortcut back toward the hub. The
	# district has two grates; both open from the far side only.
	var grates: Array[Dictionary] = []
	for spec: RoomSpec in _specs:
		grates.append_array(spec.markers_of_type("grate"))
	assert_gte(grates.size(), 1, "no shortcut grate in the district")


func test_the_enemy_placement_is_in_the_curves_neighbourhood() -> void:
	# stats-and-curves.md solved the XP curve against ~28 Scavs, 12 drones,
	# 8 Riot units, 3 Elites and the boss. M6 re-solves `base` against what
	# is actually placed; this only keeps the roster from drifting silently.
	var counts: Dictionary = {"e": 0, "d": 0, "r": 0, "E": 0, "B": 0}
	for spec: RoomSpec in _specs:
		for kind: String in counts:
			counts[kind] += spec.positions_of(kind).size()
	assert_between(int(counts["e"]), 20, 36, "Scavs: %d" % counts["e"])
	assert_between(int(counts["d"]), 8, 20, "drones: %d" % counts["d"])
	assert_between(int(counts["r"]), 5, 10, "Riot units: %d" % counts["r"])
	assert_between(int(counts["E"]), 1, 3, "Elites: %d" % counts["E"])
	assert_eq(int(counts["B"]), 1, "exactly one Landlord")


# --- The generated scenes and the graph ----------------------------------------

func test_every_room_scene_exists_and_matches_its_spec() -> void:
	for spec: RoomSpec in _specs:
		var path: String = World.room_path(spec.id)
		assert_true(ResourceLoader.exists(path), "%s was never generated" % path)
		if not ResourceLoader.exists(path):
			continue
		var room: Node = autofree((load(path) as PackedScene).instantiate())
		assert_is(room, Room)
		assert_eq(room.room_id, spec.id)
		var limits: Rect2i = room.camera_limits
		var view: Vector2i = Vector2i(PixelCamera.view_size())
		assert_true(limits.size.x >= view.x and limits.size.y >= view.y, "%s camera bounds hold at least one view" % spec.id)
		var tile_px: int = int(RoomSpec.TILE)
		var cell := Rect2i(Vector2i.ZERO, Vector2i(spec.width(), spec.height()))
		for y: int in spec.height():
			for x: int in spec.width():
				if spec.is_air(x, y):
					var ring: Rect2i = Rect2i(x, y, 1, 1).grow(1).intersection(cell)
					assert_true(limits.encloses(Rect2i(ring.position * tile_px, ring.size * tile_px)),
						"%s camera bounds show tile %d,%d and its ring" % [spec.id, x, y])
		for digit: String in spec.doors:
			var door: Door = room.get_node_or_null("Doors/%s" % digit) as Door
			assert_not_null(door, "%s scene lacks door %s — regenerate with tools/make_stacks.tscn" % [spec.id, digit])
			if door != null:
				assert_eq(String(door.target_room), String(spec.doors[digit]["target_room"]))
				assert_eq(String(door.target_door), String(spec.doors[digit]["target_door"]))


func test_the_world_graph_matches_the_specs() -> void:
	var graph: WorldGraph = load("res://src/world/world_graph.tres")
	assert_not_null(graph, "no world graph — regenerate with tools/make_stacks.tscn")
	if graph == null:
		return
	assert_eq(graph.rooms.size(), _specs.size(), "the graph has %d rooms, the specs %d" % [graph.rooms.size(), _specs.size()])
	for spec: RoomSpec in _specs:
		var entry: Dictionary = graph.room(spec.id)
		assert_false(entry.is_empty(), "%s is not on the map" % spec.id)
		if entry.is_empty():
			continue
		assert_eq(entry.get("cell"), spec.cell, "%s cell" % spec.id)
		assert_eq(entry.get("size"), spec.size, "%s size" % spec.id)
		assert_eq(bool(entry.get("save", false)), spec.has_marker_type("save"), "%s terminal on the map" % spec.id)
		assert_eq((entry.get("doors", []) as Array).size(), spec.doors.size(), "%s door count on the map" % spec.id)


func test_no_two_rooms_overlap_on_the_map() -> void:
	for a: RoomSpec in _specs:
		for b: RoomSpec in _specs:
			if a.id >= b.id:
				continue
			var ra := Rect2i(a.cell, a.size)
			var rb := Rect2i(b.cell, b.size)
			assert_false(ra.intersects(rb), "%s and %s overlap on the map" % [a.id, b.id])
