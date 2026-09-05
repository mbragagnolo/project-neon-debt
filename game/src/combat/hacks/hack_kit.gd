class_name HackKit
extends Node
## The player's programs: what is owned, what is loaded, and casting
## (docs/combat/hacks.md).
##
## Sits on the player as a component, the way `Health` does. It owns the four
## things hacks.md hands M4 — the quickslot selection, the shared 1s cooldown,
## the RAM regen tick, and the Firewall timer — and the auto-target
## acquisition. It owns no numbers: costs and reach live on each `Hack`, the
## cooldown and regen rate on `HackConfig`.
##
## **Casting has no player state.** A cast is auto-targeted and instant, so it
## costs a cooldown and never commitment — the same reasoning that keeps
## ranged out of the state machine. It is legal while running, jumping,
## dashing or sliding, which is what makes Firewall a reaction rather than a
## plan.
##
## **Ownership is a `GameState` flag** on each hack (`Hack.flag`), so programs
## are saved the way doors and chests are. Firewall has no flag: it is
## factory-installed and always owned. The quickslot — cycling between owned
## programs — is unlocked by the Cyberdeck (DESIGN.md §2); until then the kit
## is single-slot and the one program in it is Firewall.

const CATALOG_PATH := "res://src/combat/hacks/catalog.tres"
const CONFIG_PATH := "res://src/combat/hacks/hack_config.tres"
const ENEMY_GROUP := &"enemies"
const DOOR_GROUP := &"breach_doors"

## Why the last cast was refused. Read by the HUD; cleared on a timer.
enum Failure { NONE, NO_PROGRAM, COOLDOWN, RAM, NO_TARGET, NO_DECK }

@export var catalog: HackCatalog
@export var config: HackConfig

var player: Player

var _selected: int = 0
var _cooldown_timer: float = 0.0
var _guard_timer: float = 0.0
var _guard_hack: Hack
var _regen_accumulator: float = 0.0
var _last_failure: Failure = Failure.NONE
var _failure_timer: float = 0.0


func _ready() -> void:
	if catalog == null and ResourceLoader.exists(CATALOG_PATH):
		catalog = load(CATALOG_PATH)
	if config == null and ResourceLoader.exists(CONFIG_PATH):
		config = load(CONFIG_PATH)
	if catalog == null or config == null:
		push_error("HackKit on '%s' is missing its catalog or config." % get_parent().name)
		set_physics_process(false)


func setup(owning_player: Player) -> void:
	player = owning_player
	_selected = 0
	Events.hack_selected.emit(selected().id if selected() != null else &"")


func _physics_process(delta: float) -> void:
	# Scaled delta on purpose, like `Health`: nothing here ticks during
	# hitstop, so the freeze cannot eat a cooldown or a Firewall window.
	_cooldown_timer = maxf(_cooldown_timer - delta, 0.0)
	if _failure_timer > 0.0:
		_failure_timer -= delta
		if _failure_timer <= 0.0:
			_last_failure = Failure.NONE
	_tick_guard(delta)
	_tick_regen(delta)


# --- Ownership --------------------------------------------------------------

## The programs the player has, in catalog (= acquisition) order.
func owned_hacks() -> Array[Hack]:
	var out: Array[Hack] = []
	if catalog == null:
		return out
	for hack: Hack in catalog.hacks:
		if hack != null and is_owned(hack):
			out.append(hack)
	return out


static func is_owned(hack: Hack) -> bool:
	if hack == null:
		return false
	return hack.is_factory_installed() or GameState.has_flag(hack.flag)


static func is_owned_id(hack_id: StringName) -> bool:
	return is_owned(hack_by_id(hack_id))


static func hack_by_id(hack_id: StringName) -> Hack:
	var found: HackCatalog = load(CATALOG_PATH)
	return found.by_id(hack_id) if found != null else null


## Hands the player a program. Returns false if it was already owned — or is
## factory-installed, which cannot be granted because it cannot be lacked.
## Static because the thing granting it (a pickup, a quest) has no player in
## hand and should not need one.
static func grant(hack_id: StringName) -> bool:
	var hack: Hack = hack_by_id(hack_id)
	if hack == null:
		push_error("HackKit: no hack with id '%s'" % hack_id)
		return false
	if is_owned(hack):
		return false
	GameState.set_flag(hack.flag)
	Events.hack_acquired.emit(hack.id)
	Events.toast_requested.emit("Program acquired: %s" % hack.display_name.to_upper())
	return true


# --- The quickslot ----------------------------------------------------------

## The program that fires on `hack_cast`. Null only if nothing is owned, which
## cannot happen while Firewall is factory-installed.
func selected() -> Hack:
	var owned: Array[Hack] = owned_hacks()
	if owned.is_empty():
		return null
	_selected = clampi(_selected, 0, owned.size() - 1)
	return owned[_selected]


## Cycling between programs is the Cyberdeck's feature. Without it the kit is
## single-slot: one program, no wheel.
func quickslot_unlocked() -> bool:
	return GameState.has_ability(GameState.ABILITY_CYBERDECK)


func select_next() -> void:
	_cycle(1)


func select_prev() -> void:
	_cycle(-1)


func _cycle(step: int) -> void:
	var owned: Array[Hack] = owned_hacks()
	if owned.size() < 2:
		return
	if not quickslot_unlocked():
		_fail(selected(), Failure.NO_DECK)
		return
	_selected = wrapi(_selected + step, 0, owned.size())
	Events.hack_selected.emit(owned[_selected].id)


# --- Casting ----------------------------------------------------------------

## Why `hack` cannot be cast right now, or `NONE` if it can. Asked before
## every cast, and by the HUD to grey the slot out honestly.
func cast_blocker(hack: Hack) -> Failure:
	if hack == null:
		return Failure.NO_PROGRAM
	if _cooldown_timer > 0.0:
		return Failure.COOLDOWN
	if player == null or player.ram < hack.ram_cost:
		return Failure.RAM
	if hack.effect == Hack.Effect.BURST and _nearest_target(hack.radius) == null:
		return Failure.NO_TARGET
	return Failure.NONE


func try_cast() -> bool:
	var hack: Hack = selected()
	var blocker: Failure = cast_blocker(hack)
	if blocker != Failure.NONE:
		_fail(hack, blocker)
		return false

	# Spend first. A cast that fizzled after spending would be a bug worth
	# noticing; a cast that spent nothing and fired would be an exploit.
	player.spend_ram(hack.ram_cost)
	_cooldown_timer = config.global_cooldown
	match hack.effect:
		Hack.Effect.GUARD:
			_cast_guard(hack)
		Hack.Effect.BURST:
			_cast_burst(hack)
		Hack.Effect.PULSE:
			_cast_pulse(hack)
	Events.hack_cast.emit(hack.id, hack.ram_cost)
	return true


func cooldown_remaining() -> float:
	return _cooldown_timer


func last_failure() -> Failure:
	return _last_failure


func _fail(hack: Hack, why: Failure) -> void:
	_last_failure = why
	_failure_timer = config.failure_flash_time if config != null else 0.8
	Events.hack_failed.emit(hack.id if hack != null else &"", failure_name(why))


static func failure_name(why: Failure) -> StringName:
	match why:
		Failure.NO_PROGRAM: return &"no_program"
		Failure.COOLDOWN: return &"cooldown"
		Failure.RAM: return &"ram"
		Failure.NO_TARGET: return &"no_target"
		Failure.NO_DECK: return &"no_deck"
	return &""


# --- Firewall: GUARD --------------------------------------------------------

## Hacks your own body. Sets the multiplier the pipeline reads at step 6 for
## `duration` seconds; recasting refreshes the window rather than stacking.
func _cast_guard(hack: Hack) -> void:
	_guard_hack = hack
	_guard_timer = hack.duration
	player.health.guard_mult = hack.guard_mult
	player.set_guard_visual(true, hack.color)
	Events.guard_changed.emit(true, hack.duration)
	HackFx.ring(player, player.center(), 90.0, hack.color, config.fx_time)


func is_guard_active() -> bool:
	return _guard_timer > 0.0


func guard_remaining() -> float:
	return _guard_timer


func _tick_guard(delta: float) -> void:
	if _guard_timer <= 0.0:
		return
	_guard_timer -= delta
	if _guard_timer <= 0.0:
		_end_guard()


func _end_guard() -> void:
	_guard_timer = 0.0
	_guard_hack = null
	if player != null:
		player.health.guard_mult = 1.0
		player.set_guard_visual(false, Color.WHITE)
	Events.guard_changed.emit(false, 0.0)


# --- Overload: BURST --------------------------------------------------------

## Hacks one enemy's system. Nearest valid target in radius, INT-scaled,
## through the pipeline with step 5 disabled (`Attack.is_hack`). Delivered
## straight to the hurtbox rather than through a hitbox: there is no swing to
## sweep and no projectile to fly, the target was chosen before the cast.
func _cast_burst(hack: Hack) -> void:
	var target: Hurtbox = _nearest_target(hack.radius)
	if target == null:
		return
	var attack := Attack.make(player, player.global_position, hack.power, hack.knockback)
	attack.stat = PlayerStats.intelligence()
	attack.is_hack = true
	target.receive(attack)
	HackFx.bolt(player, player.center(), target.global_position, hack.color, config.fx_time)
	HackFx.ring(player, target.global_position, 70.0, hack.color, config.fx_time)


## The closest living enemy hurtbox within `radius` of the player's centre.
func _nearest_target(radius: float) -> Hurtbox:
	if player == null or not player.is_inside_tree():
		return null
	var best: Hurtbox = null
	var best_distance: float = radius
	var from: Vector2 = player.center()
	for node: Node in player.get_tree().get_nodes_in_group(ENEMY_GROUP):
		var hurtbox: Hurtbox = _hurtbox_of(node)
		if hurtbox == null or hurtbox.health == null or hurtbox.health.is_dead():
			continue
		var distance: float = from.distance_to(hurtbox.global_position)
		if distance <= best_distance:
			best_distance = distance
			best = hurtbox
	return best


static func _hurtbox_of(node: Node) -> Hurtbox:
	if not is_instance_valid(node):
		return null
	for child: Node in node.get_children():
		if child is Hurtbox:
			return child as Hurtbox
	return null


# --- Breach: PULSE ----------------------------------------------------------

## Hacks every machine in reach. Stuns whatever answers `stun()` — only
## `mechanical` enemies do — and opens every breach door in radius. Doors
## opened this way still cost the cast; the *free* open is the terminal
## interaction (hacks.md, rule 2), which exists so an empty pool never
## softlocks a player at a gate.
func _cast_pulse(hack: Hack) -> void:
	var from: Vector2 = player.center()
	for node: Node in player.get_tree().get_nodes_in_group(ENEMY_GROUP):
		if not is_instance_valid(node) or not (node is Node2D):
			continue
		if from.distance_to((node as Node2D).global_position) > hack.radius:
			continue
		if node.has_method(&"stun"):
			node.call(&"stun", hack.duration)
	for door: Node in player.get_tree().get_nodes_in_group(DOOR_GROUP):
		if not is_instance_valid(door) or not (door is Node2D):
			continue
		if from.distance_to((door as Node2D).global_position) > hack.radius:
			continue
		if door.has_method(&"breach"):
			door.call(&"breach")
	HackFx.ring(player, from, hack.radius, hack.color, config.fx_time * 1.6)


# --- RAM regen --------------------------------------------------------------

## The slow trickle (docs/rpg/stats-and-curves.md, RAM). Fractional points
## accumulate so a 0.4/s rate is honoured exactly rather than rounded to
## nothing. Read through the stats layer so the gloves' multiplier lives in
## one place.
func _tick_regen(delta: float) -> void:
	if player == null or player.ram >= player.max_ram:
		_regen_accumulator = 0.0
		return
	_regen_accumulator += PlayerStats.effective_ram_regen(config.ram_regen_per_second) * delta
	if _regen_accumulator >= 1.0:
		var whole: int = int(_regen_accumulator)
		_regen_accumulator -= float(whole)
		player.add_ram(whole)
