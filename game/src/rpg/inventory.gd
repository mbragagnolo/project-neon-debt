extends Node
## What the player owns and what they are wearing (autoload `Inventory`).
##
## Ten items and no bag pressure (DESIGN.md §2), so this is not a container
## system: it is a set of owned ids plus one item per slot. Everything it
## exposes beyond that is a *modifier read* — the four engine hooks clothing
## carries (docs/rpg/items.md), each with exactly one caller.
##
## An autoload for the same reason `PlayerStats` is: from M5 the player is
## re-instanced per room, and gear that lived on that node would be handed back
## at every door.
##
## Items are stored as ids and resolved through the catalog, never stored as
## resources. That is what makes the snapshot a list of strings rather than a
## set of serialized `.tres` copies frozen at the moment of saving — a
## re-balanced maul must reach an old save.

const CATALOG_PATH := "res://src/rpg/items/catalog.tres"
## Key this system's data is filed under inside `GameState.snapshot()`.
const SAVE_KEY := &"inventory"

var catalog: ItemCatalog

## Owned item ids, as String keys so the set is JSON-safe by construction.
var _owned: Dictionary = {}
## slot (int) -> Item currently equipped there.
var _equipped: Dictionary = {}


func _ready() -> void:
	catalog = load(CATALOG_PATH)
	if catalog == null:
		push_error("Inventory: no item catalog — nothing can be owned or equipped.")
		return
	GameState.register_state(SAVE_KEY, self)
	reset()


# --- Ownership --------------------------------------------------------------

func owns(item_id: StringName) -> bool:
	return _owned.has(String(item_id))


## Every owned item, in catalog order so the equip screen's list never
## reshuffles itself between openings.
func owned_items() -> Array[Item]:
	var out: Array[Item] = []
	for item: Item in catalog.items:
		if owns(item.id):
			out.append(item)
	return out


## Owned items that fit one slot — the right-hand column of the equip screen.
func owned_in_slot(which: Item.Slot) -> Array[Item]:
	var out: Array[Item] = []
	for item: Item in owned_items():
		if item.slot == which:
			out.append(item)
	return out


## Grants an item. Returns false if it was already owned, which is what makes
## a chest that somehow fires twice harmless.
##
## A found piece auto-equips **only into an empty slot**. Clothing therefore
## goes straight on — it is progression, not choice, one piece per slot, and
## making the player equip the only jacket in the game is a menu chore. Found
## weapons never displace what is in hand: the trio are sidegrades, and which
## one is right is exactly the decision the equip screen exists for.
func grant(item_id: StringName) -> bool:
	var item: Item = catalog.by_id(item_id)
	if item == null:
		push_error("Inventory: no item with id '%s'" % item_id)
		return false
	if owns(item_id):
		return false

	_owned[String(item_id)] = true
	Events.item_picked_up.emit(item_id)
	Events.toast_requested.emit("Picked up %s" % item.display_name)
	if _equipped.get(item.slot) == null:
		equip(item_id)
	return true


# --- Equipment --------------------------------------------------------------

func equipped(which: Item.Slot) -> Item:
	return _equipped.get(which) as Item


func equipped_melee() -> MeleeWeapon:
	return equipped(Item.Slot.MELEE) as MeleeWeapon


func equipped_ranged() -> RangedWeapon:
	return equipped(Item.Slot.RANGED) as RangedWeapon


func equip(item_id: StringName) -> bool:
	var item: Item = catalog.by_id(item_id)
	if item == null or not owns(item_id):
		return false
	var current: Item = equipped(item.slot)
	if current == item:
		return false

	if current != null:
		Events.item_unequipped.emit(StringName(Item.slot_name(current.slot)), current.id)
	_equipped[item.slot] = item
	Events.item_equipped.emit(StringName(Item.slot_name(item.slot)), item.id)
	return true


## Empties a slot. Weapon slots refuse: the player owns a starter of each from
## minute zero and can only ever swap them, so an empty weapon slot is a state
## with no legitimate way in and one obvious way to soft-brick a fight
## (docs/ui/screens.md, rule 6).
func unequip(which: Item.Slot) -> bool:
	var current: Item = equipped(which)
	if current == null or not current.is_clothing():
		return false
	_equipped.erase(which)
	Events.item_unequipped.emit(StringName(Item.slot_name(which)), current.id)
	return true


# --- The four modifier reads ------------------------------------------------

## Every point of DEF in the game comes from here. Levels never grant it.
func total_defense() -> int:
	var total: int = 0
	for slot: int in _equipped:
		var piece: Clothing = _equipped[slot] as Clothing
		if piece != null:
			total += piece.defense
	return total


func max_hp_bonus() -> int:
	var piece: Clothing = equipped(Item.Slot.BODY) as Clothing
	return piece.max_hp_bonus if piece != null else 0


func dash_cooldown_mult() -> float:
	var piece: Clothing = equipped(Item.Slot.LEGS) as Clothing
	return piece.dash_cooldown_mult if piece != null else 1.0


func ram_regen_mult() -> float:
	var piece: Clothing = equipped(Item.Slot.HANDS) as Clothing
	return piece.ram_regen_mult if piece != null else 1.0


func melee_energy_bonus() -> int:
	var piece: Clothing = equipped(Item.Slot.HEAD) as Clothing
	return piece.melee_energy_bonus if piece != null else 0


# --- Serialization ----------------------------------------------------------

func snapshot() -> Dictionary:
	var owned: PackedStringArray = PackedStringArray(_owned.keys())
	owned.sort()
	var worn: Dictionary = {}
	for slot: int in _equipped:
		worn[Item.slot_name(slot)] = String((_equipped[slot] as Item).id)
	return {"owned": owned, "equipped": worn}


func restore(data: Dictionary) -> void:
	reset()
	for item_id: Variant in data.get("owned", []):
		if catalog.by_id(StringName(str(item_id))) != null:
			_owned[str(item_id)] = true
		else:
			# An id the catalog no longer knows is dropped rather than fatal:
			# a save from a build with a cut item must still load.
			push_warning("Inventory: save names unknown item '%s'" % item_id)
	var worn: Dictionary = data.get("equipped", {})
	for slot_label: Variant in worn:
		equip(StringName(str(worn[slot_label])))


## Back to the starting kit: the wrench and the zipgun, both in hand
## (DESIGN.md §2). The kit is catalog data, so a fresh run and a reset agree by
## construction.
func reset() -> void:
	_owned.clear()
	_equipped.clear()
	if catalog == null:
		return
	for item: Item in catalog.starting_items:
		_owned[String(item.id)] = true
		_equipped[item.slot] = item
