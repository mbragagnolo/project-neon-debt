extends Node
## Quest states (autoload `Quests`, DESIGN.md §3.6).
##
## One dictionary of id → state, registered with `GameState` so it rides the
## save file. Rewards are paid here, once, on completion — the NPC decides
## *when* by reading the state and the objective flag, this decides *what*.

enum State { UNKNOWN, ACTIVE, COMPLETE }

const SAVE_KEY := &"quests"
const MEMORY_CHIP := &"memory_chip"
const QUEST_PATHS: Array[String] = [
	"res://src/quests/memory_chip.tres",
]

var quests: Array[Quest] = []
var _states: Dictionary = {}


func _ready() -> void:
	for path: String in QUEST_PATHS:
		var quest: Quest = load(path)
		if quest != null:
			quests.append(quest)
	GameState.register_state(SAVE_KEY, self)


func by_id(quest_id: StringName) -> Quest:
	for quest: Quest in quests:
		if quest.id == quest_id:
			return quest
	return null


func state(quest_id: StringName) -> State:
	return _states.get(String(quest_id), State.UNKNOWN) as State


func is_active(quest_id: StringName) -> bool:
	return state(quest_id) == State.ACTIVE


func start(quest_id: StringName) -> bool:
	if by_id(quest_id) == null or state(quest_id) != State.UNKNOWN:
		return false
	_states[String(quest_id)] = State.ACTIVE
	Events.quest_started.emit(quest_id)
	Events.toast_requested.emit("QUEST: %s" % by_id(quest_id).title.to_upper())
	return true


## The objective flag is set. The quest still needs handing in.
func can_complete(quest_id: StringName) -> bool:
	var quest: Quest = by_id(quest_id)
	if quest == null or state(quest_id) != State.ACTIVE:
		return false
	return quest.required_flag == &"" or GameState.has_flag(quest.required_flag)


func complete(quest_id: StringName) -> bool:
	if not can_complete(quest_id):
		return false
	var quest: Quest = by_id(quest_id)
	_states[String(quest_id)] = State.COMPLETE
	if quest.reward_item_id != &"":
		Inventory.grant(quest.reward_item_id)
	if quest.reward_credits > 0:
		PlayerStats.grant_credits(quest.reward_credits)
	Events.quest_completed.emit(quest_id)
	Events.toast_requested.emit("QUEST COMPLETE: %s" % quest.title.to_upper())
	return true


# --- Serialization ----------------------------------------------------------

func snapshot() -> Dictionary:
	var out: Dictionary = {}
	for key: String in _states:
		out[key] = int(_states[key])
	return out


func restore(data: Dictionary) -> void:
	_states.clear()
	for key: Variant in data:
		var value: int = int(data[key])
		if value >= State.UNKNOWN and value <= State.COMPLETE:
			_states[str(key)] = value as State


func reset() -> void:
	_states.clear()
