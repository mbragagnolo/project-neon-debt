class_name Item
extends Resource
## Anything that can occupy one of the six equip slots (docs/rpg/items.md).
##
## The base is deliberately thin — an id, a name, a description, a slot —
## because the two kinds of item in V1 answer two different questions and
## share almost nothing else: a weapon is *how you hit*, a piece of clothing
## is *what you survive*. Everything that makes an item do something lives on
## the subclass.
##
## `id` is the save-file key, and it is permanent in exactly the way a room id
## is (README conventions): it lands in a save file, so renaming one orphans
## the gear someone had equipped. Rename the `display_name` freely — the
## names are still waiting on `docs/narrative/` — and never the id.

## The six slots, in the order the equip screen lists them
## (docs/ui/screens.md). Clothing is everything from HEAD down, which is what
## `is_clothing()` reads.
enum Slot { MELEE, RANGED, HEAD, BODY, LEGS, HANDS }

@export var id: StringName = &""
@export var display_name: String = ""
## One line, shown on the equip screen. Flavour, never mechanics — the numbers
## are the delta readout's job and duplicating them here would let the two
## disagree.
@export_multiline var description: String = ""
## Which slot this occupies. Weapons pin it in `_init()` (a maul is never
## headgear); clothing authors it, because one script covers four slots.
@export var slot: Slot = Slot.MELEE


static func slot_name(which: Slot) -> String:
	match which:
		Slot.MELEE: return "MELEE"
		Slot.RANGED: return "RANGED"
		Slot.HEAD: return "HEAD"
		Slot.BODY: return "BODY"
		Slot.LEGS: return "LEGS"
		Slot.HANDS: return "HANDS"
	return "?"


## True for the four worn pieces. The split matters because the two halves
## have opposite emptiness rules: a weapon slot is never empty, a clothing
## slot always may be (docs/ui/screens.md, rule 6).
func is_clothing() -> bool:
	return slot >= Slot.HEAD
