class_name MeleeWeapon
extends Weapon
## A swung tool (docs/rpg/items.md — wrench, utility blade, breaker maul).


## Pinned rather than exported: a maul is never headgear, and an authoring
## mistake in a `.tres` should be impossible rather than merely unlikely.
func _init() -> void:
	slot = Item.Slot.MELEE


## Ammo refunded per hit that *lands*. The mechanical spine of the intertwined
## kit: shoot → close in → melee → back out.
##
## It lives here, on the item, rather than as a constant in the pipeline. That
## is the V2 requirement from docs/combat/README.md discharged — V2 switches
## the interlock off by zeroing a field on three items, not by refactoring.
@export var ammo_on_hit: int = 1

@export_group("Swing shape")
## Size of the hitbox, px.
@export var hitbox_size: Vector2 = Vector2(72.0, 72.0)
## Offset from the player's origin, px. x is mirrored by facing.
@export var hitbox_offset: Vector2 = Vector2(52.0, -44.0)
## Seconds the hitbox stays armed. Shorter than `commit_time` so the tail of
## the swing is recovery you can be punished during.
@export var active_time: float = 0.08
## Colour of the swing tell. Per weapon rather than global: the maul and the
## blade should not read the same, and the tell is the only thing on screen
## that says which tool is equipped.
@export var swing_color: Color = Color(0.85, 0.95, 1.0, 0.75)
## Seconds the player is locked into the swing. DESIGN.md §3.2 budgets ~0.2s
## max: long enough for the Scav's bait-and-punish lesson to have stakes,
## short enough that it never reads as input lag.
@export var commit_time: float = 0.16
