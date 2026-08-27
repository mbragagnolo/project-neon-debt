# quests/

One `QuestTracker` singleton; a quest is a small state machine
(offered → active → complete). No branching, no speech checks (DESIGN.md §3.6).

- `quest_tracker.gd`, quest `Resource` files — **M5**
