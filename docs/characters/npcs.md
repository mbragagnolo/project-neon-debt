# NPCs

**Status: built (M5).** Names under the conventions in
docs/narrative/hook.md — Stacks slang for people, one corp name everywhere.

| Who | Where | Role | Talking to them |
|---|---|---|---|
| **Stitch** | The Mezz | Ripperdoc and pawn. Vendor. | First visit: a greeting, then the stall opens. Carrying the sealed Sidewinder: the install, instead of the stall. After: one line, then the stall. |
| **Marisol** | The Mezz, "14th floor tenants' association" | The neighbour. The quest. | First visit offers *What He Didn't Want Repossessed* and starts it — no accept button, no branching. With the chip: completion, the hardhat and 60 credits. After: one line. |
| **Ferro** | The sump, dead | The defaulter who ran. | A sign and a chip. He does not talk. |
| **The Landlord** | Collections, floor 40 | The enforcer. The boss. | M6. |

Every line is in `src/narrative/lines.gd`; the flows are in
`src/world/npc.gd`. A talk pauses the tree, shows pages one button at a time,
and what happens after the last page — the stall, the quest state, the
implant — is decided by what the player is carrying, never by a choice.

Each NPC's want, voice, never-says and sample lines are `narrative/cast/<id>.md`;
every line by key is `narrative/strings.json` and the scenes `narrative/dialogue/`,
from which the narrative-designer exports `lines.gd`.
