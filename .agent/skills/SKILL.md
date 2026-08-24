---
name: gemini-dm-prompting
description: Use whenever writing, editing, or debugging the Gemini system prompt, API payload construction, or response parsing in lib/network/gemini_client.dart. Trigger on tasks like "update the DM prompt," "fix the AI response parsing," "add a new directive to the DM," or any change touching StateDelta generation.
---

# Pocket Dimension — Gemini DM Prompting Rules

`gemini_client.dart` is the single place the DM's "personality" and output contract
live. Every change here must preserve both the narrative tone and the strict output
schema — a prompt tweak that improves prose but breaks JSON parsing is a regression,
not an improvement.

## System prompt structure (required sections, in this order)

1. **Persona & tone** — the DM is a narrator, not a game master rolling dice against
   the player. No combat-failure language, no "you take damage" framing.
2. **God-Mode constraint** — explicitly instruct the model there is no HP, no Mana,
   no fail states for the player character. Stakes come from suspicion, relationships,
   and narrative consequence, never from a health bar.
3. **World Bible context** — the current `WorldData` (location, flags, suspicion,
   living NPCs) must be serialized and included every call. Never assume the model
   remembers prior turns beyond what's explicitly passed in `NarrativeMemory`.
4. **Deep-Lore NPC directive** — any newly introduced NPC MUST include a `loreOrigin`
   (a real, specific folklore/cultural anchor — see `lore-authenticity` skill) and a
   `culturalArchetype`. Reject/regenerate output that introduces an NPC without both.
5. **Suspicion directive** — instruct the model to propose `suspicionIncrease` values
   proportional to the narrative action's risk, not fixed increments. Large spikes
   should be reserved for genuinely exposing actions.
6. **Output format directive** — the model must return ONLY a JSON object matching
   the `StateDelta` schema below. No prose before or after the JSON, no markdown code
   fences unless the client strips them before parsing.

## StateDelta output schema (keep in sync with `lib/models/state_delta.dart`)

```json
{
  "narration": "string, required, the prose shown to the player",
  "flagsSet": ["string", "..."],
  "suspicionIncrease": 0,
  "npcUpdates": [
    {
      "id": "string",
      "loreOrigin": "string, required for new NPCs",
      "culturalArchetype": "string, required for new NPCs",
      "trust": 0,
      "disposition": "string",
      "knownFacts": ["string"]
    }
  ],
  "inventoryAdd": ["string"],
  "inventoryRemove": ["string"],
  "locationChange": "string or null"
}
```

Every field the client's `StateDelta.fromJson` expects must appear in the prompt's
schema description. If you add a field to the Dart model, update this prompt (and
this skill file) in the same change — schema drift between the model and the prompt
is the most common source of silent parse failures.

## Memory summarization

- When `recentTurns` in `NarrativeMemory` crosses the configured threshold, the
  client should trigger a summarization call that compresses older turns into
  `rollingSummary` (~500 tokens) rather than truncating them outright.
- The summarization prompt is a separate, shorter system prompt — don't reuse the
  full DM persona prompt for it, it wastes tokens and can leak DM narration style
  into what should be a neutral summary.

## Streaming

- Prefer the streaming API for narration calls so the UI can render text as it
  arrives (see `flutter-ui-conventions` for the reveal-animation requirement).
  Non-streaming calls are acceptable for the World Bible generation step, where
  the player is waiting for a structured result, not reading prose live.

## Error handling requirements

- If the response isn't valid JSON, or is missing a required field, do not crash or
  silently apply a partial delta — surface a narration-safe fallback ("The thread of
  the story wavers — try that again") and retry once before showing an error state.
- Never let a malformed AI response reach `applyDelta` unvalidated — that's the job
  of the `state-delta-safety` skill, but the client must call it every time.
