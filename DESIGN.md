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
- **Starting kit:** run, jump (coyote time + jump buffer), ground dash, wall slide, melee weapon, and **Firewall** on a small starting RAM pool — the factory-installed hack, single-slot (no quickslot UI needed yet). The corp protects its collateral; every cast is using the leash.
- **Ability progression (in acquisition order):**
  1. **Mag-Hook** (gadget, first few screens) → unlocks **wall jump**. First taste of ability-gating, minutes in.
  2. **Ranged weapon** (early pickup or vendor)
  3. **Cyberdeck** (early-mid) → expands the RAM pool and unlocks the **quickslot**, so you can carry more than the one factory hack. The deck is the capacity upgrade, not the first hack.
  4. **Overload** (found in the world, mid-early) → the first *offensive* program: the moment the player starts repurposing corporate property as a weapon.
  5. **Breach** (the set-piece gate beat, before the district midpoint) → opens hack-locked doors and briefly stuns mechanical enemies. Acquisition order locked in [`docs/combat/hacks.md`](docs/combat/hacks.md).
  6. **Sidewinder implant** (late) → unlocks **air dash**. Found as an item, must be *installed* at the ripperdoc (the vendor) — makes the hub visit matter and sells the fiction: gadgets are carried, implants are surgery.
- **2–3 visible double-jump gates** — ledges the player can see but never reach in V1 (the metroidvania promise)
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
- Wall slide from the start (teaches that walls are interactive); **wall jump** exists in the codebase but is gated behind the Mag-Hook
- **Air dash** exists in the codebase but is gated behind the Sidewinder implant
- Attack while moving and mid-air; no movement lock on melee
- Tuning lives in one `movement_config.tres` resource so iteration = editing numbers, not code
- **Tuning vs possession are separate systems.** `MovementConfig` answers "how does the ability behave"; `GameState` ability flags (`has_wall_jump`, `has_air_dash`, `has_breach`, …) answer "does the player have it". States check the flag before offering the move. The gym grants all flags so everything stays testable; the district grants them via pickups.
- **Anti-exploit requirement:** a single wall must not be climbable by re-sticking after a wall jump off it (push + lockout must guarantee net height loss on the same wall). Cover with a unit test — the double-jump teases depend on it.

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
  - Slice hacks: **Firewall** (brief self-buff halving incoming damage — you hack your own corporate-owned body; the starting hack), **Overload** (single-target burst damage, found in-world), **Breach** (opens hack-locked doors + briefly stuns mechanical enemies — doubles as the slice's experienced ability gate). One answer each: defense / damage / control. Full spec: [`docs/combat/hacks.md`](docs/combat/hacks.md)

Damage pipeline: `damage = max(1, weapon_power × stat_multiplier − defense)`, where `stat_multiplier` is a soft-capped saturating curve — locked, spec and constants in [`docs/rpg/stats-and-curves.md`](docs/rpg/stats-and-curves.md), with knockback, hitstop (~2–3 frames), and i-frames on player hurt. All combat entities share a `Hurtbox`/`Hitbox` component pair.

### 3.3 RPG layer (Castlevania model)

- **Stats:** HP, RAM, STR (melee), DEX (ranged), INT (hacks), DEF. Level-up auto-allocates a base curve over HP/RAM/STR/DEX/INT — **DEF comes from gear only**; gear does the differentiation (keeps V1 simple — manual allocation and respec arrive in V2 together with the independent-builds rework, §6).
- **XP:** enemies grant XP; curve tuned so the slice spans ~5 levels. Level-up = full heal (classic, feels great, paces difficulty).
- **Gear slots:** melee weapon, ranged weapon, head, body, legs, hands. Weapons carry flat stats only in V1; each clothing piece carries one modifier (table in [`docs/rpg/items.md`](docs/rpg/items.md)).
- **Inventory/equip screen** + pickup toasts. Loot from chests, hidden rooms, quest reward, vendor.
- **Currency:** credits only — V1 has no crafting, so a scrap/material currency would have nothing to buy. Enemies drop credits; one vendor with a short stock list (a health upgrade, a gear piece, ammo capacity).

### 3.4 World / metroidvania structure

- Rooms are Godot scenes connected by door/transition markers; a lightweight `WorldGraph` resource records connections → drives the in-game **map screen** (explored rooms revealed).
- **Save points** (cyberdeck terminals): save, full heal + full RAM, respawn point. 2–3 in the slice.
- **Gating grammar** — each gate shape maps to exactly one ability, so gates are readable at a glance:

  | Gate shape | Opened by | Notes |
  |---|---|---|
  | Two facing walls / shaft | Mag-Hook (wall jump) | Any shaft is climbable post-Hook — so a shaft may NEVER be used as a double-jump tease |
  | Sealed door with terminal | Breach hack | Also stuns mechanical enemies — one tool, two uses |
  | Wide flat gap | Sidewinder (air dash) | Gate band comfortably beyond jump+ground-dash reach |
  | High single-wall ledge, ideally with overhang lip | Double jump — **teased only in V1** | No facing wall nearby; forever out of reach this slice |

- **Movement envelope rule:** with current tuning, max flat jump carries ~290px, a ground dash crosses ~288px (dash holds altitude), and chains reach further. Level design must not hand-guess these: the coder derives reach programmatically from `MovementConfig` (a "movement envelope" helper) and every gate in the district gets an automated test asserting it exceeds the reachable envelope of the kit available at that point by ≥15%. Retuning movement then re-validates every gate for free.
- One stat-check-free environmental shortcut loop (unlock a one-way door back to the hub — the genre's signature relief moment).
- Persistent world state: opened doors, collected items, defeated boss stored in one `GameState` singleton, serialized to a save file.

### 3.5 Enemies + boss

- Shared `Enemy` base: patrol/aggro/attack/stagger states, XP + loot on death.
- Slice roster: **Scav** (melee rusher, teaches spacing), **Watcher drone** (flying, ranged, teaches vertical threat + ranged verb), **Riot unit** (shielded — frontal ranged immunity, teaches melee positioning or Overload), **Elite Scav** (fetch-quest area guard).
- **Boss — "The Landlord"** (chromed-up debt enforcer of The Stacks): 2 phases, telegraphed attacks, arena with platforms so movement skills matter; resistant enough that hacks + weapon swapping are rewarded. Boss death = slice end screen + "to be continued" shot of an unreachable double-jump ledge lighting up — the stolen collections override handshaking with your locked firmware (docs/narrative/hook.md).

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
| M5 | The district | 25–35 greybox rooms of The Stacks, doors/transitions, map screen, save points, ability pickups (Mag-Hook → Cyberdeck → Sidewinder), double-jump teases, shortcut loop, vendor/ripperdoc + quest NPC, fetch quest, movement-envelope gate tests | Can play the loop: explore → unlock ability → open what it gates → gear up → level → complete quest |
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
- ~~Dash from the start vs. found early?~~ **Decided:** ground dash from the start; air dash is the Sidewinder implant, late-slice. Wall jump is the Mag-Hook, first pickup.
- Dash i-frames on/off — still a playtest call (config flag, currently off).
- ~~Name, tone and narrative hook~~ — **resolved**: augment-debt premise, feature-locked firmware as gate fiction, the Landlord as lockholder; see [`docs/narrative/hook.md`](docs/narrative/hook.md). (Actual names still open inside its conventions.)
- Pixel art vs. hand-drawn vs. hi-bit for the eventual art pass.
