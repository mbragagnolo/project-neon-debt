class_name Attack
extends RefCounted
## One swing, shot or touch, in flight toward the pipeline.
##
## Built by whatever is attacking and handed to a `Hurtbox`, which runs it
## through `Damage.resolve`. Carrying the numbers here rather than reaching
## back into the attacker is what lets a projectile outlive the gun that fired
## it, and what lets contact damage exist without an attack animation.

## Who is responsible for this hit. Used for knockback direction, for the
## `damage_dealt` signal, and to run the attacker's on-hit interlocks.
var source: Node = null
## Where the hit came from, for knockback direction. Usually the hitbox's
## global position — not the source's, so a projectile pushes from where it
## struck rather than from the shooter across the room.
var origin: Vector2 = Vector2.ZERO
## `weapon_power` for the player, flat `attack_power` for enemies.
var power: float = 0.0
## The attacking stat (STR/DEX/INT). M2 has no stat sheet yet, so this stays 0
## and the multiplier resolves to ×1.0 — the pipeline is already wired for M3.
var stat: int = 0
## Enemies skip step 4 entirely: what you author is what it hits for
## (docs/rpg/stats-and-curves.md, enemy stat block).
var scales_with_stat: bool = true
## px/s impulse on a staggering hit. Flat per weapon, never derived from
## damage — see the knockback rules in the spec.
var knockback: float = 0.0
## Ammo refunded to the attacker per hit that lands. Weapon data, not pipeline
## logic: V2 switches the intertwined kit off by zeroing this on three items.
var ammo_on_hit: int = 0
## Contact damage skips hitstop, never staggers, and runs no interlocks.
var is_contact: bool = false
## Projectiles and bullets. Only ranged attacks can be stopped by
## `immune_ranged_frontal` (M6's Riot unit).
var is_ranged: bool = false


static func make(
	source_node: Node,
	origin_position: Vector2,
	power_value: float,
	knockback_value: float = 0.0
) -> Attack:
	var attack := Attack.new()
	attack.source = source_node
	attack.origin = origin_position
	attack.power = power_value
	attack.knockback = knockback_value
	return attack
