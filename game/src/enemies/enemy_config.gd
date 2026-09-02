class_name EnemyConfig
extends Resource
## Everything one enemy is (docs/characters/enemies.md, stat block shape in
## docs/rpg/stats-and-curves.md).
##
## Same rule as `MovementConfig` and `CombatConfig`: no number in code. An
## enemy is a `.tres`, which is what lets M6's Elite Scav be *the same scene
## and the same scripts* as the Scav with a different resource attached —
## "same silhouette and moveset, faster, and no overcommit" is a promise about
## data, and this is where it gets kept.
##
## The teaching role is the anchor. Any tuning change that breaks the lesson is
## wrong even if the numbers look better.

@export var display_name: String = ""
## One sentence on what this enemy exists to teach. Not decoration: if a tuning
## change makes this sentence false, the change is wrong.
@export_multiline var teaches: String = ""

@export_group("Stat block")
## Enemies run the reduced block — no six-stat sheet. A Scav with an INT score
## is bookkeeping with no gameplay output.
@export var max_hp: int = 16
## **Flat.** No stat multiplier on the enemy side: what an encounter author
## types is what the thing hits for.
@export var attack_power: float = 6.0
## M2 ships every enemy at 0. The locked tuning warning sets enemy DEF last,
## after weapon numbers exist — and low-end DEF is swingy against light
## weapons.
@export var defense: int = 0
## Single-hit damage needed to interrupt into stagger. 1 = anything interrupts,
## which is right for the tutorial enemy.
@export var stagger_threshold: int = 1
## Binary tags, never percentages — at this number scale a "30% resist" is
## invisible, and tags are what a player can read mid-fight.
@export var tags: Array[StringName] = []

@export_group("Rewards")
## Ratios between enemies are the locked part; the absolute curve gets solved
## in M5 once room counts fix the district's XP total.
@export var xp_reward: int = 10
@export var credit_reward: int = 5

@export_group("Patrol")
@export var patrol_speed: float = 90.0
## px either side of where it spawned. "A short beat" — long enough to read as
## alive, short enough that it is still where the player left it.
@export var patrol_range: float = 170.0
## Seconds paused at each end of the beat. The pause is what makes a patrol
## legible as a patrol rather than as pacing.
@export var patrol_pause: float = 0.7

@export_group("Aggro")
@export var detection_range: float = 460.0
@export var chase_speed: float = 235.0
## Chases past this and it goes home. Without a leash the first Scav follows
## the player through the whole district.
@export var give_up_range: float = 820.0

@export_group("Lunge")
## How close it must be to commit.
@export var lunge_range: float = 165.0
## **The telegraph.** The whole lesson lives in this number: long enough to
## read and react to, short enough that waiting it out is not free.
@export var windup_time: float = 0.38
@export var lunge_speed: float = 660.0
@export var lunge_time: float = 0.2
## **The overcommit.** The single number that separates the Scav from M6's
## Elite Scav: the Scav is punishable here, the Elite recovers safely and the
## tutorial answer stops working. Shortening this does not make the Scav
## harder — it makes it a different enemy.
@export var recover_time: float = 0.75
## Seconds before it may commit again, measured from the end of recovery.
@export var lunge_cooldown: float = 0.55
## Reach of the lunge. Sized from the config rather than the scene so the
## Elite Scav can differ without a second scene file.
@export var attack_size: Vector2 = Vector2(76.0, 76.0)
## Offset from the enemy origin. x is mirrored by facing.
@export var attack_offset: Vector2 = Vector2(42.0, -40.0)
## px/s the lunge shoves the player. Player-side knockback is clamped to its
## own much smaller constant, so this is the enemy's intent, not the result.
@export var lunge_knockback: float = 260.0

@export_group("Reactions")
## Seconds interrupted when a hit meets `stagger_threshold`. Must stay under
## the player's fastest weapon cooldown or melee becomes a stunlock.
@export var stagger_time: float = 0.3
@export var death_time: float = 0.45

@export_group("Greybox tells")
## Colour per state. These are the entire read until there is art: the player
## has to be able to see a windup coming and see a recovery to punish, or the
## enemy teaches nothing.
@export var color_idle: Color = Color(0.72, 0.36, 0.33)
@export var color_chase: Color = Color(0.86, 0.42, 0.36)
## Deliberately the loudest colour on screen. This is the tell being taught.
@export var color_windup: Color = Color(1.0, 0.85, 0.3)
@export var color_lunge: Color = Color(1.0, 0.45, 0.25)
## Deliberately drained. Recovery should look like an opening, because it is.
@export var color_recover: Color = Color(0.45, 0.4, 0.5)
@export var color_stagger: Color = Color(1.0, 1.0, 1.0)


## Contact damage is half `attack_power` for every enemy
## (docs/characters/enemies.md, cross-cutting rules).
func contact_power(contact_mult: float) -> float:
	return attack_power * contact_mult
