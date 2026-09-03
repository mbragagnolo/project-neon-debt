extends Node
## Global signal bus (autoload `Events`).
##
## Systems talk to each other through this node instead of holding direct node
## references (DESIGN.md §4). Emit from the system that owns the fact; connect
## from anything that needs to react. Nothing in here holds state.
##
## Convention: signal names are past tense for things that happened
## (`enemy_died`) and imperative for requests (`hitstop_requested`).

# --- Player lifecycle -------------------------------------------------------
signal player_spawned(player: Node)
signal player_died()

# --- Combat (M2) ------------------------------------------------------------
## Emitted once per resolved hit, after defense is applied.
signal damage_dealt(target: Node, amount: int, source: Node)
## Both rewards ride the death event rather than being fetched off the corpse:
## the payout is resolved once, by the thing that knows it died, and nothing
## downstream has to reach into an enemy's config to be paid.
signal enemy_died(enemy: Node, xp_reward: int, credit_reward: int)
signal hitstop_requested(frames: int)
signal camera_shake_requested(strength: float, duration: float)

# --- Vitals (M2/M3/M4) ------------------------------------------------------
signal hp_changed(current: int, maximum: int)
signal ram_changed(current: int, maximum: int)
signal ammo_changed(current: int, maximum: int)

# --- RPG layer (M3) ---------------------------------------------------------
signal xp_gained(amount: int)
signal level_gained(new_level: int)
signal stats_changed(stats: Dictionary)
signal item_picked_up(item_id: StringName)
signal item_equipped(slot: StringName, item_id: StringName)
signal item_unequipped(slot: StringName, item_id: StringName)
signal credits_changed(amount: int)

# --- Hacks (M4) -------------------------------------------------------------
signal hack_selected(hack_id: StringName)
signal hack_cast(hack_id: StringName, ram_cost: int)
signal hack_failed(hack_id: StringName, reason: StringName)

# --- World / metroidvania (M5) ---------------------------------------------
signal room_entered(room_id: StringName)
signal room_exited(room_id: StringName)
signal door_opened(door_id: StringName)
signal save_point_activated(save_point_id: StringName)
signal game_saved(slot: int)
signal game_loaded(slot: int)

# --- Quests (M5) ------------------------------------------------------------
signal quest_offered(quest_id: StringName)
signal quest_started(quest_id: StringName)
signal quest_completed(quest_id: StringName)

# --- UI ---------------------------------------------------------------------
signal toast_requested(text: String)
