class_name HackCatalog
extends Resource
## Every program in the slice, in acquisition order (docs/combat/hacks.md).
##
## Order is load-bearing: it is the order the quickslot cycles through, and it
## is the order the district hands them out — Firewall (factory), Overload
## (found), Breach (the gate beat). A save file names hacks by id and resolves
## them here, the same shape `ItemCatalog` gives items.

@export var hacks: Array[Hack] = []


func by_id(hack_id: StringName) -> Hack:
	for hack: Hack in hacks:
		if hack != null and hack.id == hack_id:
			return hack
	return null


func ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for hack: Hack in hacks:
		if hack != null:
			out.append(hack.id)
	return out
