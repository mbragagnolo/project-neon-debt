class_name GymGrants
extends Node
## Gym-only. Hands out every ability flag on load so a lab stays fully
## testable regardless of where its feature sits in the district
## (DESIGN.md §3.1: "the gym grants all flags so everything stays testable;
## the district grants them via pickups").
##
## Never placed in a shipped room. The district's rooms grant abilities
## through pickups, and a room that quietly switched on the Sidewinder would
## be a room whose gates cannot be trusted.

## Ability flags to set. Defaults to every gadget and implant in the slice.
@export var abilities: Array[StringName] = [
	GameState.ABILITY_MAG_HOOK,
	GameState.ABILITY_CYBERDECK,
	GameState.ABILITY_SIDEWINDER,
]


func _ready() -> void:
	for flag: StringName in abilities:
		GameState.grant_ability(flag)
