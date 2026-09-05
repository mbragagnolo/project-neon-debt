class_name ItemCatalog
extends Resource
## Every item in the slice, in one place (docs/rpg/items.md, ten items).
##
## Two jobs. It is the id → `Item` lookup a save file needs to turn
## `"breaker_maul"` back into a resource on load, and it is where the starting
## kit is *data* rather than a constant in code or an export on a room's
## player node. The latter matters more than it looks: from M5 the player is
## re-instanced per room, so a kit authored on a scene would be a kit that
## re-grants itself every time a door is used.

## Every item that exists in the slice. Order is display order.
@export var items: Array[Item] = []
## What the player owns and has equipped at a fresh start — the wrench and the
## zipgun (DESIGN.md §2 starting kit).
@export var starting_items: Array[Item] = []


func by_id(item_id: StringName) -> Item:
	for item: Item in items:
		if item != null and item.id == item_id:
			return item
	return null


func ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for item: Item in items:
		if item != null:
			out.append(item.id)
	return out


func in_slot(which: Item.Slot) -> Array[Item]:
	var out: Array[Item] = []
	for item: Item in items:
		if item != null and item.slot == which:
			out.append(item)
	return out
