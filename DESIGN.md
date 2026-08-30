# NEON DEBT — Vertical Slice Design & Development Plan

*Working title. Cyberpunk 2D metroidvania with Castlevania-style RPG elements.*
*V1 goal: one vertical slice district that proves the game is worth building.*

---

## 1. Locked decisions

| Area | Decision |
|---|---|
| Genre | 2D side-view metroidvania: one interconnected handcrafted map, ability-gated progression |
| Setting | Cyberpunk megacity; augmentations ARE the metroidvania abilities |
| RPG layer | Castlevania-style: XP → levels, gear (weapons + clothing) with combat stats |
| Stats scope | Combat only — no speech checks, no dialogue skills |
| Quests | Light fetch quests (Hollow Knight / Castlevania style) as extra reasons to explore |
| Combat | Melee, ranged, and **hacks** (act as magic, consume RAM). No stealth. **V1 is one intertwined kit** — verbs share resource loops and enemies force switching; independent build-your-own systems are the V2 direction (§6). |
| Engine | **Godot 4.x** (GDScript) — text-based scenes, headless CLI, agent-friendly |
| Art (V1) | **Greybox first** — shapes + placeholder tiles until movement/combat feel right; art pass on the slice only at the end |
| Team | Marcos + coding agents |
| V1 scope | Vertical slice: one district, progression gated by a double jump the player **never obtains**, ending in a **boss fight** |

---

## 2. The vertical slice — what it must prove

A vertical slice is thin but full-depth: every core system present at small scale.

The slice succeeds if a stranger playing 30–45 minutes says:

1. **Movement feels great.** Jumping, dashing, attacking mid-air are responsive (this kills or carries the genre).
2. **Combat has texture.** Melee vs ranged vs hacks are meaningfully different; enemies force choices.
3. **Exploration pulls.** The map makes them want to poke into corners; the visible-but-unreachable double-jump ledges create desire ("I'll come back for that").
4. **Numbers matter.** Leveling up and swapping gear produce a felt difference without trivializing enemies.
5. **The boss is a wall worth climbing.** Hard enough to demand engagement with all three combat verbs.

### Slice content budget

- **1 district** ("The Stacks" — vertical low-income housing towers): ~25–35 connected rooms/screens
- **Player kit:** run, jump (coyote time + jump buffer), dash (ground ability from start or found early), melee weapon, ranged weapon, 3 hacks
- **2–3 visible double-jump gates** — ledges/shafts the player can see but never reach in V1 (the metroidvania promise)
- **1–2 soft gates** the player CAN open (e.g., a hack-locked door found after acquiring a specific hack) so ability-gating is experienced, not just teased
- **3 regular enemy types** + 1 elite variant
- **1 boss** at the slice's end
- **1 hub micro-area:** save point, vendor NPC, quest NPC
- **1 fetch quest:** NPC asks for an item hidden behind exploration; reward = notable gear piece
- **Gear:** ~10 items total (3 melee, 3 ranged, 4 clothing pieces — one per clothing slot)
- **Stat pickups:** 2–3 HP Max Up + 2–3 RAM Max Up hidden in exploration spots (SotN-style permanent upgrades)
- **Levels:** tuned so a player finishing the slice reaches ~level 5–6

---

## 3. Systems design

### 3.1 Player movement (build FIRST, polish obsessively)

- Run with slight acceleration/deceleration; instant turn
- Jump: variable height (release to cut), **coyote time (~0.1s)**, **jump buffering (~0.15s)**
- Dash: fixed distance, brief i-frames optional (decide in playtest), cooldown
- Wall slide: cheap to add, greatly improves platforming texture — include
- Attack while moving and mid-air; no movement lock on melee
- Tuning lives in one `movement_config.tres` resource so iteration = editing numbers, not code

### 3.2 Combat

**Locked: in V1 the three verbs are one intertwined kit, not three parallel
builds.** Melee feeds ranged energy, Breach sets up the other two verbs, and
enemies like the Riot unit force switching. Depth comes from picking the right
verb moment to moment, not from a character build — build identity is
deliberately deferred to V2 (§6). Implementation note: the interlocks (ammo
regen on melee, stun windows) are tuning data, not hard-wired logic, so V2 can
retune or detach them without a rewrite.

Three verbs, one shared enemy/damage pipeline:

- **Melee** — highest DPS, close range, small commitment window (anim lock ~0.2s max). Scales with **STR**.
- **Ranged** — safe chip damage, limited by ammo/energy that regenerates on melee hits (creates a rhythm: shoot → close in → melee → back out); rare enemy drops and vendor refills as secondary faucets, cap upgrades vendor-only. Scales with **DEX**.
- **Hacks (= magic)** — cast from a quickslot, consume **RAM** (mana; slow passive regen, fully restored on save; regen rate increasable through gear). Scales with **INT**.
  - Slice hacks: **Overload** (single-target burst damage), **Static Wall** (short-lived barrier/zone denial), **Breach** (opens hack-locked doors + briefly stuns mechanical enemies — doubles as the slice's experienced ability gate)

Damage pipeline: `damage = max(1, weapon_power × stat_multiplier − defense)`, where `stat_multiplier` is a soft-capped saturating curve — locked, spec and constants in [`docs/rpg/stats-and-curves.md`](docs/rpg/stats-and-curves.md), with knockback, hitstop (~2–3 frames), and i-frames on player hurt. All combat entities share a `Hurtbox`/`Hitbox` component pair.

### 3.3 RPG layer (Castlevania model)

- **Stats:** HP, RAM, STR (melee), DEX (ranged), INT (hacks), DEF. Level-up auto-allocates a base curve over HP/RAM/STR/DEX/INT — **DEF comes from gear only**; gear does the differentiation (keeps V1 simple — manual allocation and respec arrive in V2 together with the independent-builds rework, §6).
- **XP:** enemies grant XP; curve tuned so the slice spans ~5 levels. Level-up = full heal (classic, feels great, paces difficulty).
- **Gear slots:** melee weapon, ranged weapon, head, body, legs, hands. Items carry flat stats + occasionally one modifier ("+10% RAM regen", "dash cooldown −15%").
- **Inventory/equip screen** + pickup toasts. Loot from chests, hidden rooms, quest reward, vendor.
- **Currency:** credits only — V1 has no crafting, so a scrap/material currency would have nothing to buy. Enemies drop credits; one vendor with a short stock list (a health upgrade, a gear piece, ammo capacity).

### 3.4 World / metroidvania structure

- Rooms are Godot scenes connected by door/transition markers; a lightweight `WorldGraph` resource records connections → drives the in-game **map screen** (explored rooms revealed).
- **Save points** (cyberdeck terminals): save, full heal + full RAM, respawn point. 2–3 in the slice.
- Gate types in slice: double-jump gates (teased, never opened), Breach doors (opened mid-slice), one stat-check-free environmental shortcut loop (unlock a one-way door back to the hub — the genre's signature relief moment).
- Persistent world state: opened doors, collected items, defeated boss stored in one `GameState` singleton, serialized to a save file.

### 3.5 Enemies + boss

- Shared `Enemy` base: patrol/aggro/attack/stagger states, XP + loot on death.
- Slice roster: **Scav** (melee rusher, teaches spacing), **Watcher drone** (flying, ranged, teaches vertical threat + ranged verb), **Riot unit** (shielded — frontal ranged immunity, teaches melee positioning or Overload), **Elite Scav** (fetch-quest area guard).
- **Boss — "The Landlord"** (chromed-up debt enforcer of The Stacks): 2 phases, telegraphed attacks, arena with platforms so movement skills matter; resistant enough that hacks + weapon swapping are rewarded. Boss death = slice end screen + "to be continued" shot of an unreachable double-jump ledge lighting up.

### 3.6 Quests (light)

- One `QuestTracker` singleton, quest = simple state machine (offered → active → complete).
- Slice quest: vendor's neighbor asks you to recover a **memory chip** from a body deep in a hazard area; reward: unique clothing item + credits. No branching, no speech checks.

### 3.7 UI/HUD

HP bar, RAM bar, ammo/energy pips, hack quickslot, XP/level indicator, credits. Pause menu: map / inventory-equip / quest log / settings. Controller + keyboard from day one (input map abstraction).

---

## 4. Technical architecture (Godot 4 / GDScript)

```
game/
  project.godot
  src/
    player/        # controller, state machine, movement_config.tres
    combat/        # hitbox, hurtbox, damage, projectiles, hacks/
    rpg/           # stats.gd, xp_curve.tres, items/ (Resource-based), inventory.gd
    enemies/       # enemy_base.gd, scav/, drone/, riot/, boss_landlord/
    world/         # room.gd, door.gd, save_point.gd, world_graph.tres
    quests/        # quest_tracker.gd, quest resources
    ui/            # hud, menus, map_screen
    core/          # game_state.gd (singleton), save_load.gd, events.gd (signal bus)
  rooms/           # one .tscn per room
  tests/           # GUT unit tests (damage math, xp curve, save/load, quest states)
```

Agent-friendly practices (this is what makes the solo+agents model work):

- **Everything as text:** GDScript, `.tscn`/`.tres` text resources — agents can read and diff all of it.
- **Data-driven balance:** items, enemies, XP curve, movement numbers in `.tres`/JSON so tuning never touches logic.
- **Signal bus** (`events.gd`) instead of deep node references — agents can wire features without traversing scene trees.
- **Headless tests:** `godot --headless` + GUT run in CI on every change; pure-logic systems (damage, XP, inventory, save, quests) get unit tests. Feel (movement/combat juice) is human-playtested — that's Marcos's job.
- **Git from commit zero**; small PR-sized changes per agent task.

---

## 5. Milestones

Each milestone ends in something playable. Never proceed while the previous layer feels bad.

| # | Milestone | Contents | Exit test |
|---|---|---|---|
| M0 | Skeleton | Godot project, git, folder structure, input map, signal bus, GUT + headless CI, one empty test room | Runs headless + windowed; tests green |
| M1 | **Movement feel** | Full controller: run/jump/dash/wall-slide, coyote, buffer, tuning resource, test gym room with platforming challenges | Marcos: "moving around an empty room is fun" — do not pass until true |
| M2 | Combat core | Melee + ranged vs training dummy + Scav enemy; damage pipeline, hitstop, knockback, i-frames, death | Fighting 3 Scavs is legible and satisfying |
| M3 | RPG layer | Stats, XP/levels, items as resources, inventory + equip screen, pickups, level-up moment | Equipping better gear visibly changes combat math; HUD shows it |
| M4 | Hacks | RAM resource, 3 hacks, quickslot UI, Breach-locked door | All three combat verbs used naturally in one fight |
| M5 | The district | 25–35 greybox rooms of The Stacks, doors/transitions, map screen, save points, double-jump teases, shortcut loop, vendor + quest NPC, fetch quest | Can play the loop: explore → find gear → level → open Breach door → complete quest |
| M6 | Enemies + boss | Drone, Riot unit, Elite; boss "The Landlord" 2 phases + arena + slice ending | Boss beatable, demands all verbs, ~3–8 attempts for a decent player |
| M7 | Slice polish | Balance pass, SFX pass (free packs), screen shake/juice, minimal art pass on hero rooms if time, menus, settings, save/load hardened | External playtesters run it start to finish without guidance |

Rough expectation with agents doing implementation: M0–M2 fast, **M1 and M5 are where the calendar goes** (feel iteration and level design are human-judgment loops, not code volume).

---

## 6. V1 success criteria (the go/no-go gate)

Give the slice to 3–5 people who owe you nothing. Continue to full development only if:

- Testers finish without being told what to do (readability of the loop)
- At least one tester asks **"how do I get up there?"** about a double-jump ledge (the pull works)
- Testers can articulate why they'd pick melee vs ranged vs hacks (combat depth)
- Someone asks when they can play more

If the slice is good → V2 planning: 2nd and 3rd district, double jump actually granted (and every tease pays off), more hacks/gear tiers, real art direction pass, narrative layer, and the **combat rework to independent systems**: manual stat allocation + respec, every verb viable as a main verb, every enemy and boss beatable with any verb. V1's mandatory interlocks become optional gear-driven synergies instead of the only loop. This is a real rework with real cost — it is priced into V2 on purpose and must not leak into the slice.

---

## 7. Open questions (fine to defer, listed so they're not forgotten)

- Death penalty: none / lose unbanked credits (Souls-lite) / return to save with world reset? *(Slice default: respawn at save point, enemies respawn, keep everything — simplest.)*
- Dash from the start vs. found in the first 10 minutes as a mini ability-gate tutorialization?
- Name, tone and narrative hook (why is the protagonist in The Stacks? "Neon Debt" implies: augment debt — you owe the corp for the body you live in).
- Pixel art vs. hand-drawn vs. hi-bit for the eventual art pass.
