---
name: state-delta-safety
description: Use whenever modifying lib/state/game_state_manager.dart, applyDelta, or anything that consumes AI-generated StateDelta output and mutates GameState. Trigger on tasks like "apply the AI's changes to state," "fix a state mutation bug," or "add a new field to StateDelta handling."
---

# Pocket Dimension — State Delta Safety Rules

`GameStateManager.applyDelta` is the only place AI output is allowed to touch real
game state. Treat every `StateDelta` as untrusted input, even though it comes from
your own `gemini_client.dart` — a model can still return an out-of-range or
malformed value, and a bug in parsing shouldn't corrupt a player's save.

## Validate before mutating, every time

1. **Consequence entries**: validate every `consequenceUpdates` entry before
   merging it into `WorldData.consequenceWeb`. New entries require a non-empty
   `summary` — drop (and log) any entry missing one rather than inserting a blank
   memory. `spreadLevel` and `status` must match the defined enum values exactly;
   reject unrecognized values rather than storing them as free text. Cap new
   entries to a sane number per turn (e.g. 2) — if a delta proposes more, keep the
   most significant and drop the rest rather than flooding the World Memory panel.
   Updates to an existing entry (matched by `id`) may only move `status` forward
   (`dormant → brewing → active → resolved`) or `spreadLevel` forward
   (`secret → rumored → known → legendary`) in one step at a time — reject a
   delta that tries to jump multiple stages or move backward in a single turn.
2. **NPC updates**: if `npcUpdates` references an `id` not already in
   `WorldData.livingNpcs`, treat it as a new NPC and require `loreOrigin` and
   `culturalArchetype` to be present — if either is missing, drop that NPC update
   and log it rather than inserting a lore-less NPC into the world.
3. **Flags**: only accept `flagsSet` values that match an expected naming pattern
   (e.g. lowercase, underscore-separated) — reject anything that looks like it
   could be a stray instruction or injected content rather than a game flag.
4. **Inventory**: `inventoryRemove` should never remove an item the character
   doesn't have — silently no-op that entry rather than erroring the whole delta.
5. **Location**: `locationChange` should be validated against the World Bible's
   known location set where possible; if it references an unknown location, treat
   it as a new discovery and add it, don't silently drop the player's location.

## Apply atomically

- Build the full validated mutation first, then commit it in a single
  `notifyListeners()` pass. Never apply half a delta and leave `GameState` in a
  partially-mutated state if a later field in the same delta fails validation.
- On validation failure, keep the previous valid `GameState` intact and surface a
  narration-safe fallback (per `gemini-dm-prompting`), don't leave the UI showing
  a state that doesn't match what's persisted.

## Logging, not silent failure

- Every rejected or clamped field should be logged with enough context to debug
  later (which delta, which field, what was rejected and why) — but never logged
  in a way that's shown to the player as raw error text. Narration stays in-world.

## Testing requirement

- Any change to `applyDelta` needs a corresponding unit test in
  `test/game_state_manager_test.dart` covering at least: a valid delta, a delta
  with an out-of-range suspicion value, a delta introducing an NPC missing
  `loreOrigin`, and a delta with malformed/missing required fields. Don't consider
  a change to this file done until those four cases are covered.
