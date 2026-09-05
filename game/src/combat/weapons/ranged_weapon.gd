class_name RangedWeapon
extends Weapon
## A fired tool (docs/rpg/items.md — zipgun, nailgun, rivet gun).
##
## All three draw from the single shared energy pool, which gives ranged a
## second sidegrade axis beyond speed: damage-per-second against
## damage-per-energy.

## Energy spent per shot. The nailgun's equal-cost-per-nail is deliberate:
## hungry, so its users close to melee *more* and the regen rhythm stays
## central.
@export var energy_per_shot: int = 1


func _init() -> void:
	slot = Item.Slot.RANGED

@export_group("Projectile")
@export var projectile_speed: float = 900.0
## Seconds before an unspent projectile despawns. Doubles as the range limit —
## V1 has no damage falloff, so range is simply how far it gets.
@export var projectile_lifetime: float = 1.1
## Where the shot spawns, px from the player's origin. x is mirrored by facing.
@export var muzzle_offset: Vector2 = Vector2(34.0, -46.0)
## px/s² pulling the shot down in flight. Zero for every weapon but the rivet
## gun, whose slight arc is the one exception V1 allows to "straight lines"
## (docs/rpg/items.md) — it is what makes the big slug a skill-shot rather
## than a slower hitscan hose.
@export var projectile_gravity: float = 0.0
@export var projectile_size: Vector2 = Vector2(18.0, 8.0)
@export var projectile_color: Color = Color(1.0, 0.85, 0.35)
