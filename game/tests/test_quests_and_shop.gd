extends GutTest
## The fetch quest, the two NPCs, and Stitch's stall (DESIGN.md §3.3, §3.6).

const FLOOR_TOP := 600.0

var _root: Node2D
var _box: DialogueBox
var _shop: ShopScreen


func before_each() -> void:
	TestArena.release_all_input()
	GameState.reset()
	PlayerStats.reset()
	Inventory.reset()
	Quests.reset()
	_root = Node2D.new()
	add_child_autofree(_root)
	_box = DialogueBox.new()
	add_child_autofree(_box)
	_shop = ShopScreen.new()
	add_child_autofree(_shop)


func after_each() -> void:
	TestArena.release_all_input()
	get_tree().paused = false
	GameState.reset()
	PlayerStats.reset()
	Inventory.reset()
	Quests.reset()


func _npc(npc_id: StringName) -> Npc:
	var npc := Npc.new()
	npc.npc_id = npc_id
	_root.add_child(npc)
	return npc


## Runs a talk up to its first page and dismisses it. Nothing here awaits a
## frame: the dialogue pauses the tree, and a test that waits for a frame it
## just stopped would hang (the same rule the equip screen tests follow). A
## talk opens its box synchronously, and closing the box resumes the flow
## synchronously too — the quest turns over, the stall opens — before
## `close()` returns.
func _talk_through(npc: Npc) -> void:
	npc.talk()
	assert_true(_box.is_open(), "%s said nothing" % npc.npc_id)
	_box.close()


# --- The tracker ----------------------------------------------------------------

func test_a_quest_moves_from_unknown_to_active_to_complete() -> void:
	var id: StringName = Quests.MEMORY_CHIP
	assert_eq(Quests.state(id), Quests.State.UNKNOWN)
	assert_true(Quests.start(id))
	assert_false(Quests.start(id), "started twice")
	assert_eq(Quests.state(id), Quests.State.ACTIVE)
	assert_false(Quests.can_complete(id), "complete with no chip")
	assert_false(Quests.complete(id))
	GameState.set_flag(&"quest_item.memory_chip")
	assert_true(Quests.can_complete(id))
	assert_true(Quests.complete(id))
	assert_eq(Quests.state(id), Quests.State.COMPLETE)


func test_completing_pays_the_hardhat_and_the_credits_once() -> void:
	var quest: Quest = Quests.by_id(Quests.MEMORY_CHIP)
	Quests.start(quest.id)
	GameState.set_flag(quest.required_flag)
	var before: int = PlayerStats.credits
	Quests.complete(quest.id)
	assert_true(Inventory.owns(&"scavved_hardhat"), "the hardhat is the reward (items.md)")
	assert_eq(Inventory.equipped(Item.Slot.HEAD).id, &"scavved_hardhat", "clothing auto-equips into an empty slot")
	assert_eq(PlayerStats.credits, before + quest.reward_credits)
	assert_false(Quests.complete(quest.id), "paid twice")


func test_quest_state_rides_the_save_file() -> void:
	Quests.start(Quests.MEMORY_CHIP)
	var snapshot: Dictionary = GameState.snapshot()
	assert_true(snapshot.has("quests"), "the tracker is not registered with GameState")
	Quests.reset()
	assert_eq(Quests.state(Quests.MEMORY_CHIP), Quests.State.UNKNOWN)
	GameState.restore(JSON.parse_string(JSON.stringify(snapshot)))
	assert_eq(Quests.state(Quests.MEMORY_CHIP), Quests.State.ACTIVE, "the quest did not survive JSON")


# --- Marisol --------------------------------------------------------------------

func test_talking_to_marisol_starts_the_quest() -> void:
	var marisol := _npc(&"marisol")
	_talk_through(marisol)
	assert_eq(Quests.state(Quests.MEMORY_CHIP), Quests.State.ACTIVE)


func test_marisol_completes_it_once_the_chip_is_carried() -> void:
	var marisol := _npc(&"marisol")
	_talk_through(marisol)
	_talk_through(marisol)
	assert_eq(Quests.state(Quests.MEMORY_CHIP), Quests.State.ACTIVE, "completed without the chip")
	GameState.set_flag(&"quest_item.memory_chip")
	_talk_through(marisol)
	assert_eq(Quests.state(Quests.MEMORY_CHIP), Quests.State.COMPLETE)
	assert_true(Inventory.owns(&"scavved_hardhat"))


func test_the_dialogue_pauses_the_game_and_closing_lets_it_go() -> void:
	var marisol := _npc(&"marisol")
	marisol.talk()
	assert_true(_box.is_open())
	assert_true(get_tree().paused)
	_box.close()
	assert_false(get_tree().paused)


# --- Stitch ------------------------------------------------------------------------

func test_stitch_opens_the_shop_after_the_greeting() -> void:
	var stitch := _npc(&"stitch")
	_talk_through(stitch)
	assert_true(_shop.is_open(), "no shop after the greeting")
	_shop.close()


func test_stitch_installs_a_carried_sidewinder_instead_of_selling() -> void:
	GameState.set_flag(GameState.SIDEWINDER_CARRIED)
	assert_false(GameState.has_ability(GameState.ABILITY_SIDEWINDER))
	var stitch := _npc(&"stitch")
	_talk_through(stitch)
	assert_true(GameState.has_ability(GameState.ABILITY_SIDEWINDER), "the implant was not installed")
	assert_false(_shop.is_open(), "surgery is its own visit")


# --- The stall -----------------------------------------------------------------------

func _entry(id: StringName) -> ShopEntry:
	return _shop.stock.by_id(id)


func test_the_stock_is_the_locked_list() -> void:
	var ids: Array = []
	for entry: ShopEntry in _shop.stock.entries:
		ids.append(String(entry.id))
	assert_eq(ids, ["padded_jacket", "hp_up", "ammo_cap", "ammo_refill"])


func test_nothing_on_the_list_is_progression() -> void:
	# docs/narrative/hook.md: credits never touch an unlock.
	for entry: ShopEntry in _shop.stock.entries:
		assert_false(String(entry.item_id).contains("hook"))
		assert_ne(entry.kind, -1)
	assert_null(_entry(&"cyberdeck"))


func test_buying_needs_the_credits() -> void:
	assert_eq(_shop.buy(_entry(&"padded_jacket")), &"credits")
	assert_false(Inventory.owns(&"padded_jacket"))
	PlayerStats.grant_credits(200)
	assert_eq(_shop.buy(_entry(&"padded_jacket")), &"bought")
	assert_true(Inventory.owns(&"padded_jacket"))
	assert_eq(PlayerStats.credits, 200 - _entry(&"padded_jacket").price)
	assert_eq(_shop.buy(_entry(&"padded_jacket")), &"sold_out")


func test_the_patch_and_the_cell_raise_the_ceilings_once() -> void:
	PlayerStats.grant_credits(500)
	var hp_before: int = PlayerStats.effective_max_hp()
	assert_eq(_shop.buy(_entry(&"hp_up")), &"bought")
	assert_eq(PlayerStats.effective_max_hp(), hp_before + _entry(&"hp_up").amount)
	assert_eq(_shop.buy(_entry(&"hp_up")), &"sold_out")
	assert_eq(_shop.buy(_entry(&"ammo_cap")), &"bought")
	assert_eq(PlayerStats.effective_max_ammo(8), 8 + _entry(&"ammo_cap").amount)
	assert_true(GameState.has_flag(&"shop.hp_up"), "the sale is not a flag — it would be sold again after a load")


func test_a_refill_tops_the_pool_and_refuses_a_full_one() -> void:
	TestArena.solid(_root, Vector2(0, FLOOR_TOP + 100.0), Vector2(6000, 200))
	var player := TestArena.player(_root, Vector2(0, FLOOR_TOP))
	await wait_frames(3)
	PlayerStats.grant_credits(50)
	assert_eq(_shop.buy(_entry(&"ammo_refill")), &"full")
	player.spend_ammo(5)
	assert_eq(_shop.buy(_entry(&"ammo_refill")), &"bought")
	assert_eq(player.ammo, player.max_ammo)
	assert_eq(PlayerStats.credits, 50 - _entry(&"ammo_refill").price)


# --- The new pickup kinds ---------------------------------------------------------

func _pickup(kind: Pickup.Kind, payload: StringName = &"") -> Pickup:
	var pickup: Pickup = (preload("res://src/world/pickup.tscn") as PackedScene).instantiate()
	pickup.kind = kind
	pickup.pickup_id = &"test_pickup"
	match kind:
		Pickup.Kind.ABILITY: pickup.ability_id = payload
		Pickup.Kind.QUEST_ITEM: pickup.quest_item_id = payload
	add_child_autofree(pickup)
	return pickup


func test_a_max_up_bumps_the_sheet_permanently() -> void:
	var hp_before: int = PlayerStats.effective_max_hp()
	_pickup(Pickup.Kind.HP_UP).take()
	assert_eq(PlayerStats.effective_max_hp(), hp_before + PlayerStats.stat_curve.hp_up_amount)
	var ram_before: int = PlayerStats.effective_max_ram()
	_pickup(Pickup.Kind.RAM_UP).take()
	assert_eq(PlayerStats.effective_max_ram(), ram_before + PlayerStats.stat_curve.ram_up_amount)
	var snapshot: Dictionary = GameState.snapshot()
	PlayerStats.reset()
	GameState.restore(snapshot)
	assert_eq(PlayerStats.effective_max_hp(), hp_before + PlayerStats.stat_curve.hp_up_amount, "the bump did not survive a save")


func test_the_cyberdeck_expands_the_pool_and_unlocks_the_quickslot() -> void:
	var before: int = PlayerStats.effective_max_ram()
	_pickup(Pickup.Kind.ABILITY, GameState.ABILITY_CYBERDECK).take()
	assert_eq(PlayerStats.effective_max_ram(), before + PlayerStats.stat_curve.cyberdeck_ram_bonus)
	assert_true(GameState.has_ability(GameState.ABILITY_CYBERDECK))


func test_the_sidewinder_pickup_is_carried_not_installed() -> void:
	_pickup(Pickup.Kind.ABILITY, GameState.SIDEWINDER_CARRIED).take()
	assert_true(GameState.has_flag(GameState.SIDEWINDER_CARRIED))
	assert_false(GameState.has_ability(GameState.ABILITY_SIDEWINDER), "implants are surgery")


func test_the_chip_is_a_flag_the_quest_reads() -> void:
	Quests.start(Quests.MEMORY_CHIP)
	_pickup(Pickup.Kind.QUEST_ITEM, &"memory_chip").take()
	assert_true(GameState.has_flag(&"quest_item.memory_chip"))
	assert_true(Quests.can_complete(Quests.MEMORY_CHIP))
