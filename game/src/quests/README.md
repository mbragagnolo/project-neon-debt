# quests/

One `QuestTracker` singleton; a quest is a small state machine
(offered → active → complete). No branching, no speech checks (DESIGN.md §3.6).

- `quest_tracker.gd` (autoload `Quests`), `quest.gd`, `memory_chip.tres` —
  **M5.** States ride the save file; rewards are paid once on completion;
  the objective is a `GameState` flag the quest item sets.
