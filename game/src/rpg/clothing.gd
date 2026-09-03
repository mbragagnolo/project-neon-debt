class_name Clothing
extends Item
## A worn piece: DEF plus exactly one modifier (docs/rpg/items.md).
##
## Two locked rules this file exists to keep honest:
##
## **No stat points on clothing.** Levels raise the five stats, clothing owns
## DEF, modifiers carry the personality. There is deliberately no `str_bonus`
## field to author into — stat-bearing gear becomes interesting exactly when
## V2 makes builds real, and adding the field early is how it leaks in.
##
## **The modifier pool contains exactly the modifiers shipped items use** —
## currently four, one per piece. They are four typed fields rather than the
## one loose dictionary the doc sketches: the sizing claim the doc actually
## makes (four modifiers, four read-sites, no framework) holds either way, and
## typed fields keep the read-sites statically typed like the rest of the
## codebase instead of fishing Variants out of a bag.

@export var defense: int = 0

@export_group("Modifier — exactly one per piece")
## Jacket. Folded into max HP by the stats layer.
@export var max_hp_bonus: int = 0
## Boots. A multiplier on the *effective* dash cooldown, read through the
## stats layer rather than off `MovementConfig` — the indirection items.md
## asked M3 to force into existence.
@export var dash_cooldown_mult: float = 1.0
## Gloves. Consulted by M4's RAM regen tick; displays but does nothing in M3.
@export var ram_regen_mult: float = 1.0
## Hardhat. Added to the melee weapon's `ammo_on_hit`, which is what makes the
## intertwined kit's spine equipment-adjustable rather than a constant.
@export var melee_energy_bonus: int = 0


## How many of the four modifier fields this piece actually carries. Exists
## for the test that holds "one modifier each" to the locked table — the rule
## is cheap to state and easy to break by authoring a second field.
func modifier_count() -> int:
	var count: int = 0
	if max_hp_bonus != 0:
		count += 1
	if not is_equal_approx(dash_cooldown_mult, 1.0):
		count += 1
	if not is_equal_approx(ram_regen_mult, 1.0):
		count += 1
	if melee_energy_bonus != 0:
		count += 1
	return count
