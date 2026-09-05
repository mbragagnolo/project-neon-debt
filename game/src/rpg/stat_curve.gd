class_name StatCurve
extends Resource
## What a level is worth (docs/rpg/stats-and-curves.md, starting values).
##
## The auto-allocated sheet, as data. No player ever spends a point in V1, so
## this resource *is* the progression a level-up delivers, and level is the
## only stored truth — every stat is derived from it rather than accumulated,
## which means a level-up cannot drift out of sync with a save file.
##
## **DEF is deliberately absent.** No level ever grants it (locked): gear has a
## monopoly on survivability so that grinding makes you hit harder and never
## tank better, which is the right bias for a metroidvania. The way to keep
## that rule is to have nowhere to type the number.
##
## STR, DEX and INT share one field for the same reason. "All three attack
## stats rise in lockstep" is locked, so the resource has no shape in which
## they can diverge; V2's independent builds change this resource, not the
## call sites, which already ask for each stat separately.

@export_group("Level 1")
@export var start_hp: int = 40
@export var start_ram: int = 12
## STR, DEX and INT alike.
@export var start_attack_stat: int = 5

@export_group("Per level")
@export var hp_per_level: int = 5
@export var ram_per_level: int = 2
@export var attack_stat_per_level: int = 3


func hp_at(level: int) -> int:
	return start_hp + hp_per_level * (maxi(level, 1) - 1)


func ram_at(level: int) -> int:
	return start_ram + ram_per_level * (maxi(level, 1) - 1)


func attack_stat_at(level: int) -> int:
	return start_attack_stat + attack_stat_per_level * (maxi(level, 1) - 1)
