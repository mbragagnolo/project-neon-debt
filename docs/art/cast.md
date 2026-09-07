# Cast look sheet — for sign-off

**Status: approved 2026-09-06** (skin tone, height and chrome legs decided;
see the end). One entry per character the slice draws. The *Look* paragraph
is the contract; everything else in an entry is derived from it and from
what the code already needs. Style target: hi-bit pixel per
[`refs/README.md`](refs/README.md).

## Rules that apply to everyone

- **Scale.** Art is drawn at 1×, placed at 2×. At 1080p one art pixel is two
  screen pixels; the 60 px tile is 30 art px. Heights below are art px.
- **Dani's collider does not change.** It is 48×88 screen px today. Her
  sprite may be taller than the box (hair and head overhang it), but her feet
  sit at its bottom edge, so every gap and step in the district keeps its
  arithmetic.
- **Light from the upper left**, one rim light on the far edge. Every part of
  every character is lit the same way, which is what lets rig parts from one
  still sit together in any pose.
- **No black outlines.** Edges are a darker step of the local colour, and
  absent where the rim light hits. Dark clothes separate from dark rooms by
  that rim, not by a line.
- **Accents mean things** (as in `direction.md`): **cyan** is Dani and
  VESTA's infrastructure, **magenta** is money and the Landlord, **amber** is
  a threat's eye and a warning lamp, **green** is a working machine. A
  character carries one accent, two at most.
- **Tells stay engine-side.** The state tint (`Enemy.tint`) still blends
  over the sprite on windup, so a pose only has to *agree* with the tint,
  never carry the read alone.
- **Rig parts.** Every character is generated once as a still, cut into the
  parts listed, rigged in Godot, and baked to sheets (see the animation
  decision in the art-pass notes). Far-side limbs are the same parts, one
  shade darker.

Sizes are relative to Dani and rounded, so the roster keeps the proportions
the greybox taught the player.

| | Today (3×) | Proposed (2×) | Screen px at 1080p |
|---|---|---|---|
| Dani | 22×32 | ~28×56 | 112 |
| Scav, Elite Scav | 20×28 | ~26×50 | 100 |
| Watcher drone | 18×12 | ~28×18 | 36 |
| Riot unit (+ shield) | 26×34 (+8×36) | ~34×62 (+10×66) | 124 |
| The Landlord | 28×44 | ~40×80 | 160 |
| Stitch | 22×30 | ~30×54 | 108 |
| Marisol | 20×30 | ~28×52 | 104 |

---

## Dani Okonkwo — the player

**Role.** Behind on payments, not a hero. Terse, tired, working-class wry.

**Look.** Early twenties, slim, light warm-toned skin (the M7 `skin`
swatch; the surname may change to match, that is a narrative call for
later), dark hair cropped close at the sides and left a little longer on
top. She wears a padded navy utility
jacket a size too big, sleeves shoved to the elbow, with a single **cyan
piping line down the front closure**: VESTA's collateral marking, the corp
tagging what it owns. A thin magenta eye-band visor, cracked at one corner,
sits over her eyes; it is the stock eyewear that came with the finance plan.
Dark work trousers with a knee patch. From the knee down her legs are the
corp's standard chrome, **matte black with a dim cyan status seam** that
runs to the ankle: the locked leg firmware, visible, waiting. Heavy work
boots. The pipe wrench rides in her right hand, head down, and is the
biggest single shape on her.

**Silhouette.** Narrow shoulders, big boots, the wrench head. Read her by
the wrench and the visor.

**Colour.** `navy` / `navy_l` / `navy_d` jacket, `cyan` piping and leg
seam, `magenta` visor, `black` / `black_l` trousers and chrome legs, `skin`
/ `skin_d`, `chrome_d` wrench.

**Rig parts.** Head (hair and visor on it), torso with jacket, near upper
arm, near forearm, near hand, far arm as one part, near thigh, near shin
with boot, far leg as one part, weapon. The weapon is its own part so the
blade and the maul can replace the wrench on the rig later without a new
character.

**Clips.** `idle`, `run`, `jump`, `fall`, `wall`, `dash`, `attack`, `hurt`.
The rig makes an aim pose for the ranged weapons nearly free; it is not
required for the slice.

---

## Scav — melee rusher

**Role.** Teaches spacing. Lunges with a telegraphed overcommit; dies to
being reached.

**Look.** A person who lives in the Stacks' write-off floors. Hunched,
hooded, the face lost in the hood except **one amber eye**: a cheap ocular
implant that never stopped glowing. Layers of olive and rust: a hooded
canvas coat over a stained work shirt, trousers tied at the ankle, boots
wrapped in tape. A length of steel pipe in both hands, held low. Wiry rather
than big. The overcommit pose is a full-body reach with the pipe, feet
leaving the ground.

**Silhouette.** The hood and the hunch, pipe angled down. Shorter than Dani.

**Colour.** `olive` / `olive_l` coat, `rust1` / `rust2` shirt and wraps,
`amber` eye, `grey_d` pipe, `skin2_d` for the little skin that shows.

**Rig parts.** Hooded head, torso, near arm (upper, forearm, hand), far arm,
near leg (thigh, shin), far leg, pipe.

**Clips.** `idle`, `run`, `windup`, `lunge`, `recover`, `stagger`, `dead`.

---

## Elite Scav — the quest guard

**Role.** A Scav that learned. Same silhouette and moveset, no punish window.

**Look.** The Scav's body and rig, re-dressed. Coat and hood in **black and
concrete grey**, cleaner and better-fitting than any Scav's: he is paid. The
pipe is a **red-painted rebar cutter** with a lick of tape at the grip. The
eye is **magenta**, not amber: somebody else's money is behind it. Stands
straighter than a Scav in idle, hunches only to lunge.

**Silhouette.** Identical to the Scav. That is the point.

**Colour.** `black_l` / `concrete1` coat, `red` / `red_d` weapon, `magenta`
eye.

**Rig parts / clips.** The Scav's, re-textured.

---

## Watcher drone — flying sentry

**Role.** Teaches the vertical threat and the ranged verb. `mechanical`.

**Look.** A flattened steel disc the width of a dinner plate with a single
**red lens** on its underside rim, a rotor ring on top that reads as a blur
in flight, and a short gun barrel under the lens. A **cyan status ring**
around the body: VESTA infrastructure, working as intended. Dents and a
scorched patch on the shell; it has been in service a long time. When it
aims, the lens brightens and the body tilts toward the target. Stunned, the
rotor stops and it drops nose-first.

**Silhouette.** A disc with a rotor above and a lens below. Nothing else
in the roster is horizontal.

**Colour.** `steel1` / `steel2` / `steel3` shell, `red` lens, `cyan` ring,
`grey_d` barrel.

**Rig parts.** Body, rotor ring, lens, barrel. Four parts.

**Clips.** `idle`, `hover`, `aim`, `stunned`, `dead`.

---

## Riot unit — the shield wall

**Role.** Teaches heavy hits and hacks. `mechanical`, frontal
`immune_ranged`.

**Look.** A crowd-suppression frame, not a robot with a face: a squat,
heavy-shouldered chassis in **matte steel** with hydraulic lines at the
joints and a **narrow cyan visor slit** where a face would be. An **amber
warning lamp** on one shoulder blinks in idle and stays lit in the windup.
It carries a **full-height polycarbonate riot shield**, scuffed and
concrete-grey, with **VESTA COLLECTIONS** stencilled across it in the
corp's type. It walks with a slow, planted, forward lean. The bash tell is
the shield drawn back; the lunge is the shield driven forward with the
whole frame behind it. Stunned, it sags at the knees and the visor goes
dark.

**Silhouette.** A wall with legs. Wider than anything else that walks.

**Colour.** `steel1` / `steel2` / `steel3` chassis, `cyan` / `cyan_d`
visor, `amber` lamp, `concrete1` / `concrete2` shield, `black_l` joints.

**Rig parts.** Head unit, torso, near arm (upper, forearm), far arm, near
leg (thigh, shin), far leg, shield (its own node, as today).

**Clips.** `idle`, `run`, `windup`, `lunge`, `recover`, `stagger`,
`stunned`, `dead`.

---

## The Landlord — the enforcer

**Role.** The boss. A man in chrome; the Stacks never learned his name.

**Look.** Tall, still, expensive. A **long black coat with chrome piping**
at the collar and cuffs, worn open over a fitted dark shirt. Both forearms
and hands are **polished chrome**, the only bright metal on anyone in the
slice, and the **collections deck** sits on his chest like a breastplate:
a dark slab with a **magenta readout** that is dim until he uses it. Pale,
clean-shaven, hair slicked back; no visor, no implants showing on the face,
because he can afford not to. The **baton** is a telescoping shock stick
that lights magenta along its length in the windup. Phase two: the deck's
readout stays hot, and the coat is off the shoulders and hanging from the
belt so the chrome arms read at full length.

**Silhouette.** The tallest thing in the game. The coat's line, the baton's
length, the deck's square.

**Colour.** `black` / `black_l` coat and shirt, `chrome` / `chrome_d`
arms and piping, `magenta` / `magenta_d` deck and baton, `skin`, `hair`.

**Rig parts.** Head, torso with deck, coat tails (two parts, so they swing),
near arm (upper, chrome forearm, hand), far arm, near leg (thigh, shin),
far leg, baton.

**Clips.** `idle`, `run`, `windup`, `lunge`, `recover`, `stagger`,
`slam_windup`, `beam`, `phase`, `dead`.

---

## Stitch — ripperdoc and pawn

**Role.** Vendor on the Mezz. Installs the Sidewinder.

**Look.** Broad, fifties, brown skin, shaved head. **Surgical loupes pushed
up onto the forehead**, a stained canvas apron over a green scrub top with
the sleeves gone, nitrile gloves. One arm is a plain working prosthetic,
unpainted, better made than anything he sells. A **green work lamp** on a
gooseneck over the stall is his light. He does not stand up; he sits behind
the counter, elbows on it, and leans in to talk.

**Silhouette.** A wide seated block with the loupes on top.

**Colour.** `green` / `green_d` scrub and lamp, `concrete2` / `concrete3`
apron, `skin2` family, `chrome_d` arm.

**Rig parts.** Head, torso, near arm, far arm (seated: no legs). Four parts.

**Clips.** `idle` (breathing, two or three poses), `talk`.

---

## Marisol — the neighbour

**Role.** Fourteenth-floor tenants' association. Gives the quest.

**Look.** Sixties, small, upright. A **violet headscarf** knotted at the
nape, a rust-coloured cardigan buttoned to the top, a long dark skirt, flat
shoes. Reading glasses on a cord. **Arms folded**, always; she unfolds one
hand to point when she gives the quest and folds it again. No implants
showing anywhere, which in the Stacks is its own statement.

**Silhouette.** Narrow and vertical, the headscarf's knot, folded arms.

**Colour.** `violet` / `violet_d` headscarf, `rust1` / `rust2` cardigan,
`black_l` skirt, `skin` family.

**Rig parts.** Head, torso with folded arms, one free forearm and hand, near
leg, far leg.

**Clips.** `idle` (breathing), `talk` (the pointing hand).

---

## Ferro — the defaulter who ran

**Role.** A sign and a chip in the sump. He does not talk.

**Look.** A prop, not a character: a body in the same work gear as Dani,
face down in the sump water, one chrome leg showing under the trouser cuff
with its **status seam dead**. The hardhat is gone from his head (it is the
quest reward). Replaces `props/body.png`.

---

## Decided (2026-09-06)

1. **Dani's skin tone stays the M7 `skin` swatch.** Whether the surname
   changes to match is a narrative decision, deferred.
2. **Dani is 56 art px tall** (112 screen px at 1080p), collider unchanged
   at 48×88 screen px, feet on the box's bottom edge, 24 screen px of head
   overhang above it.
3. **The chrome legs stay.** The leg-firmware fiction is on the sprite; the
   ending's ledge shot has a body to light up.
4. The Riot shield stencil and the Landlord's phase-two coat stand as
   written. Everything else is a re-dressing of what M7 drew.
