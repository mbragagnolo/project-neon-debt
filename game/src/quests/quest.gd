class_name Quest
extends Resource
## One fetch quest (DESIGN.md §3.6): offered → active → complete, no
## branching, no speech checks.
##
## The objective is a `GameState` flag — a quest item is a flag the way a
## looted chest is — so "do you have the thing" is answered by the same store
## that answers every other world question, and the tracker never learns
## what a memory chip is.

@export var id: StringName = &""
@export var title: String = ""
## Who hands it out; the quest log shows it.
@export var giver: String = ""
## The log line while active.
@export_multiline var objective: String = ""
## The log line once done.
@export_multiline var epilogue: String = ""
## The flag that says the objective is met — set by picking up the quest item.
@export var required_flag: StringName = &""
@export var reward_item_id: StringName = &""
@export var reward_credits: int = 0
