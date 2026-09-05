class_name ShopEntry
extends Resource
## One line of Stitch's stock (docs/rpg/economy.md).
##
## Credits buy convenience and one gear piece, never progression: no ability
## and no program is ever on this list, so a player who spends everything can
## never be softlocked (docs/narrative/hook.md).

enum Kind { ITEM, HP_UP, AMMO_CAP, AMMO_REFILL }

@export var id: StringName = &""
@export var label: String = ""
@export_multiline var description: String = ""
@export var price: int = 0
@export var kind: Kind = Kind.ITEM
## `ITEM` only.
@export var item_id: StringName = &""
## `HP_UP`: max HP added. `AMMO_CAP`: max ammo added.
@export var amount: int = 0
## Sold once; the sale is a `GameState` flag (`shop.<id>`).
@export var once: bool = true
