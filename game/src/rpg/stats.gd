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
	# Gear changes the sheet as surely as a level does, and everything that
	# draws the sheet listens to one signal.
	Events.item_equipped.connect(_on_equipment_changed)
	Events.item_unequipped.connect(_on_equipment_changed)
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


# --- The effective sheet ----------------------------------------------------
#
# Everything outside this file asks for these, never for the base values. The
# indirection is what items.md asked M3 to force into existence: the boots
# cannot make the dash faster unless *something* sits between `MovementConfig`
# and the controller, and the same seam is what V2's independent builds need
# anyway. Four modifier reads, four callers, no framework.

func effective_max_hp() -> int:
	return base_max_hp() + Inventory.max_hp_bonus()


func effective_max_ram() -> int:
	# No RAM modifier exists — the gloves move the *regen rate*, not the pool.
	return base_max_ram()


## Every point of DEF the player has. Levels contribute nothing, forever.
func effective_defense() -> int:
	return Inventory.total_defense()


## The boots' hook. Takes the authored cooldown rather than reading
## `MovementConfig` itself, so the tuning resource stays the single source of
## the *base* number and this layer only ever bends it.
func effective_dash_cooldown(base_cooldown: float) -> float:
	return base_cooldown * Inventory.dash_cooldown_mult()


## The gloves' hook. Nothing calls it until M4's regen tick exists; it lives
## here now so the equip screen can show the number it will move.
func effective_ram_regen(base_rate: float) -> float:
	return base_rate * Inventory.ram_regen_mult()


## The hardhat's hook: the melee→energy interlock, made equipment-adjustable.
## The weapon still owns the base amount, so V2 switches the whole intertwined
## kit off by zeroing a field on three items and this stays true.
func effective_ammo_on_hit(weapon: MeleeWeapon) -> int:
	if weapon == null:
		return 0
	return weapon.ammo_on_hit + Inventory.melee_energy_bonus()


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


func _on_equipment_changed(_slot: StringName, _item_id: StringName) -> void:
	publish()


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
		"max_hp": effective_max_hp(),
		"max_ram": effective_max_ram(),
		"def": effective_defense(),
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
