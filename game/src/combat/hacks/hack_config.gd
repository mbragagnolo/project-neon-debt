class_name HackConfig
extends Resource
## Every number the hack kit reads that is not a property of one program
## (docs/combat/hacks.md, docs/rpg/stats-and-curves.md — RAM).
##
## Same rule as `CombatConfig`: the kit owns no magic numbers. What belongs to a
## specific hack — cost, reach, duration — lives on that hack's `.tres`; what
## belongs to *casting* lives here.

@export_group("Rate cap")
## Seconds between any two casts, shared across every hack. RAM is the
## limiter; this only stops the pool being panic-dumped in one burst and gives
## each cast room to read. It must never grow into rotation-juggling
## (hacks.md, rule 1).
@export var global_cooldown: float = 1.0

@export_group("RAM")
## Points per second of passive regen, before the gloves' multiplier. Slow on
## purpose: a full pool is ~3 casts and the save terminal is where it refills.
@export var ram_regen_per_second: float = 0.4

@export_group("Greybox tells")
## Seconds the cast ring takes to expand and fade.
@export var fx_time: float = 0.35
## Seconds the kit remembers a refused cast, so the HUD can say why.
@export var failure_flash_time: float = 0.8
