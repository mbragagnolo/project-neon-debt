# Economy

**Status: built (M5), numbers `TUNE` in M7.** Credits and what they buy.

The numbers here are held as data in `systems/tables/shop.csv` and
`enemies/stats.csv` (the systems-designer's tables, read from the engine and
written back by its `export.py`); `systems/report.md` recomputes the ledger
from the placed roster and measures what each player's route actually pays.

## The one rule — LOCKED

**Credits never touch an unlock.** No ability, no program, no door is ever
for sale, in fiction or mechanics (docs/narrative/hook.md). A player who
spends everything can never be softlocked out of progression. Stitch sells
convenience and one gear piece.

## Stock — Stitch, the Mezz

| Entry | Price | Once? | What it does |
|---|---|---|---|
| Utility worker's padded jacket | 140 | yes | DEF 2, +10 max HP. The biggest DEF piece, and the only one you pay for (items.md placement). |
| Dermal weave patch | 90 | yes | Max HP +5 — the vendor's health upgrade (DESIGN.md §3.3). |
| Extended energy cell | 70 | yes | Ranged energy cap +4. **The only source of capacity** (stats-and-curves.md). |
| Energy refill | 10 | no | Tops the pool up. Cheap on purpose: meleeing is cheaper. |

Sales are `GameState` flags (`shop.<id>`), so a sold-once entry stays sold
across a load. The jacket's "sold" reads off the inventory instead.

The Sidewinder install is not stock: Stitch does it for free when the
sealed unit is carried, before the shop opens. Surgery is not a purchase.

## Income

Enemies drop credits on death (`credit_reward` on the config; the Scav's 5
is the only authored value until M6). Against the reward ratios in
enemies.md and the placed roster (stacks.md), the district holds roughly:

| Source | Count | Credits each (proposed, M6) | Total |
|---|---|---|---|
| Scav | 31 | 5 | 155 |
| Watcher drone | 17 | 7 | 119 |
| Riot unit | 7 | 15 | 105 |
| Elite Scav | 1 | 25 | 25 |
| Quest reward | 1 | 60 | 60 |
| **District, killing everything once** | | | **~465** |

The whole stall costs 300 plus refills. A thorough player affords it with
slack; a player who skips fights chooses between the jacket and the rest,
which is the only economic decision the slice asks for. Enemies respawn on
room re-entry, so credits are farmable — the sold-once flags are what keep
the stall from becoming an income sink.

## Exports

- **M6** authors `credit_reward` on the new configs against the column
  above.
- **M7** tunes prices against a real playthrough's wallet at the Mezz.
