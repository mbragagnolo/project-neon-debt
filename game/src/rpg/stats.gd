extends Node
## The player's sheet (autoload `PlayerStats`, DESIGN.md §3.3).
##
## Owns level, lifetime XP and credits, and derives every stat from the level
## through `StatCurve`. Nothing here is accumulated: a level-up adds no numbers
## anywhere, it raises `level` and the getters answer differently. That is what
## makes a save file three integers instead of a stat block, and what makes
## "the curve changed" a re-tune rather than a migration.
##
## **It is an autoload, not a node on the player**, and that is load-bearing
## from M5: rooms are scenes, so the player is re-instanced every time a door
## is used. Progression hanging off that node would reset at every threshold.
## The same reasoning puts `Inventory` alongside it.
##
## It reaches for nothing. XP arrives on the bus, the sheet is published on the
## bus, and the full heal a level-up owes is applied by whoever has a `Health`
## — this file cannot heal anybody and should not learn how.

const XP_CURVE_PATH := "res://src/rpg/xp_curve.tres"
const STAT_CURVE_PATH := "res://src/rpg/stat_curve.tres"
## Key this system's data is filed under inside `GameState.snapshot()`.
const SAVE_KEY := &"stats"

var xp_curve: XPCurve
var stat_curve: StatCurve

var level: int = 1
## Lifetime XP, never spent and never reset by a level-up. The level is derived
## from it, so the two cannot disagree.
var xp: int = 0
var credits: int = 0


func _ready() -> void:
	xp_curve = load(XP_CURVE_PATH)
	stat_curve = load(STAT_CURVE_PATH)
	if xp_curve == null or stat_curve == null:
		push_error("PlayerStats: missing a curve resource — progression is disabled.")
		return
	# Rewards resolve on the death event, which the pipeline emits once per
	# enemy (docs/combat/damage-pipeline.md, death), so nothing here has to
	# de-duplicate simultaneous killing blows.
	Events.enemy_died.connect(_on_enemy_died)
	GameState.register_state(SAVE_KEY, self)


# --- The sheet --------------------------------------------------------------

func strength() -> int:
	return stat_curve.attack_stat_at(level)


func dexterity() -> int:
	return stat_curve.attack_stat_at(level)


func intelligence() -> int:
	return stat_curve.attack_stat_at(level)


## Max HP before equipment. `effective_max_hp()` is what anything outside this
## file should ask for — it folds the jacket in.
func base_max_hp() -> int:
	return stat_curve.hp_at(level)


func base_max_ram() -> int:
	return stat_curve.ram_at(level)


# --- XP and levels ----------------------------------------------------------

## XP earned since the current level began. The HUD's bar reads this.
func xp_into_level() -> int:
	return xp - xp_curve.cumulative_to(level)


## XP the current level costs end to end. Zero at max level.
func xp_for_level() -> int:
	return xp_curve.xp_to_next(level)


func grant_xp(amount: int) -> void:
	if amount <= 0:
		return
	xp += amount
	Events.xp_gained.emit(amount)

	var gained: int = xp_curve.level_for(xp) - level
	if gained > 0:
		for step: int in gained:
			level += 1
			# One signal per level, not one per grant: two levels from a single
			# boss kill should feel like two level-ups, and whoever draws the
			# flourish should not have to work out that it happened twice.
			Events.level_gained.emit(level)
	publish()


func grant_credits(amount: int) -> void:
	if amount <= 0:
		return
	credits += amount
	Events.credits_changed.emit(credits)


## Returns false and spends nothing if the wallet is short — M5's vendor is the
## only caller, and "can I afford this" is a question it should ask by trying.
func spend_credits(amount: int) -> bool:
	if amount <= 0 or credits < amount:
		return false
	credits -= amount
	Events.credits_changed.emit(credits)
	return true


func _on_enemy_died(_enemy: Node, xp_reward: int, credit_reward: int) -> void:
	grant_xp(xp_reward)
	grant_credits(credit_reward)


# --- Publication ------------------------------------------------------------

## The whole sheet, as the flat dictionary `Events.stats_changed` carries.
## Every reader of the sheet — HUD, equip screen — reads this shape and none of
## them holds a reference to this node.
func as_dictionary() -> Dictionary:
	return {
		"level": level,
		"xp": xp,
		"xp_into_level": xp_into_level(),
		"xp_for_level": xp_for_level(),
		"max_hp": base_max_hp(),
		"max_ram": base_max_ram(),
		"str": strength(),
		"dex": dexterity(),
		"int": intelligence(),
		"credits": credits,
	}


func publish() -> void:
	Events.stats_changed.emit(as_dictionary())


# --- Serialization ----------------------------------------------------------

## Three integers. Level is stored rather than re-derived on load so a future
## re-tune of the XP curve cannot silently demote a save.
func snapshot() -> Dictionary:
	return {"level": level, "xp": xp, "credits": credits}


func restore(data: Dictionary) -> void:
	level = maxi(int(data.get("level", 1)), 1)
	xp = maxi(int(data.get("xp", 0)), 0)
	credits = maxi(int(data.get("credits", 0)), 0)
	publish()
	Events.credits_changed.emit(credits)


func reset() -> void:
	level = 1
	xp = 0
	credits = 0
	publish()
	Events.credits_changed.emit(credits)
