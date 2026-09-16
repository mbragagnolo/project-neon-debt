class_name ShopStock
extends Resource
## Stitch's whole inventory, in display order (docs/rpg/economy.md).

@export var entries: Array[ShopEntry] = []


func by_id(entry_id: StringName) -> ShopEntry:
	for entry: ShopEntry in entries:
		if entry != null and entry.id == entry_id:
			return entry
	return null
