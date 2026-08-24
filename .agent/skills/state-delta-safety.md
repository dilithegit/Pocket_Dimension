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

1. **Suspicion**: clamp `suspicionIncrease` to a defined sane range (e.g. 0–25 per
   turn) before adding it to `RegionalSuspicion.heatLevel`. Never trust the raw
   model value directly into a running total.
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
