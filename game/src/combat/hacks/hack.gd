class_name Hack
extends Resource
## One program (docs/combat/hacks.md).
##
## Same rule as every other tuning resource: no hack number lives in code. A
## hack is a `.tres` — cost, power, reach, duration — and the kit only knows
## the three *shapes* a program can take:
##
## - `GUARD`  — hacks your own body. A timed self-buff (Firewall).
## - `BURST`  — hacks one enemy's system. INT-scaled damage to the nearest
##   valid target in `radius` (Overload).
## - `PULSE`  — hacks every machine in reach. Stuns `mechanical` enemies for
##   `duration` and opens hack-doors (Breach).
##
## The fiction rule every entry must pass: the player is hacking a *specific
## system*. A shape that hacks nothing — a wall of force in empty air — does
## not belong here, which is why Static Wall was cut for Firewall.
##
## Hacks are programs, not items: they live outside the ten-item budget and
## outside the inventory. Ownership is a `GameState` flag (`flag`), so it is
## saved the way a door or a chest is, with no provider to register.

enum Effect { GUARD, BURST, PULSE }

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var effect: Effect = Effect.GUARD

@export_group("Cost")
## RAM spent per cast. The pool is the limiter; the shared 1s cooldown is only
## the rate cap (hacks.md, rule 1).
@export var ram_cost: int = 1

@export_group("Effect")
## `BURST` only — plays the `weapon_power` role at step 4, scaled by INT.
@export var power: float = 0.0
## px/s impulse on the target. `BURST` only.
@export var knockback: float = 0.0
## px. `BURST`: how far the auto-target looks. `PULSE`: how far it reaches.
@export var radius: float = 400.0
## Seconds. `GUARD`: how long the buff holds. `PULSE`: how long the stun holds.
@export var duration: float = 0.0
## `GUARD` only — incoming damage is multiplied by this after DEF, before the
## floor. 0.5 is "halved" (hacks.md).
@export var guard_mult: float = 1.0

@export_group("Ownership")
## The `GameState` flag that says the player has this program. Empty means it
## is factory-installed and always owned — Firewall ships with the body.
@export var flag: StringName = &""

@export_group("Greybox tell")
## The one colour that says which program just fired.
@export var color: Color = Color(0.6, 0.95, 1.0)


func is_factory_installed() -> bool:
	return flag == &""
