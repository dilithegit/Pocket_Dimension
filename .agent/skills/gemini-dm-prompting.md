---
name: gemini-dm-prompting
description: Use whenever writing, editing, or debugging the Gemini system prompt, API payload construction, or response parsing in lib/network/gemini_client.dart. Trigger on tasks like "update the DM prompt," "fix the AI response parsing," "add a new directive to the DM," or any change touching StateDelta generation.
---

# Pocket Dimension — Gemini DM Prompting Rules

`gemini_client.dart` is the single place the DM's "personality" and output contract
live. Every change here must preserve both the narrative tone and the strict output
schema — a prompt tweak that improves prose but breaks JSON parsing is a regression,
not an improvement.

## Active DM Model & Free-Tier Quota Rationale

- **Active Model**: `gemini-3.5-flash-lite` (specified in `lib/network/gemini_client.dart` via `defaultModelName`).
- **Quota Rationale**: Migrated from `gemini-3.6-flash` to `gemini-3.5-flash-lite` to move off the **20 Requests-Per-Day (RPD)** free-tier rate limit onto the **500 RPD** free-tier limit. `gemini-3.5-flash-lite` fully supports SSE streaming (`streamGenerateContent`) and JSON mode output shapes (`application/json`).
- **DO NOT** revert `defaultModelName` to `gemini-3.6-flash` or `gemini-2.5-flash` for "narration quality" reasons without considering the 20 RPD cap, which quickly triggers HTTP 429 errors during multi-turn testing.

## System prompt structure (required sections, in this order)

1. **Persona & tone** — the DM is a narrator, not a game master rolling dice
   against the player. No combat-failure language, no "you take damage" framing.
2. **God-Mode constraint** — explicitly instruct the model there is no HP, no
   Mana, no fail states for the player character. Stakes come from the World
   Memory consequence web and relationships, never from a health bar.
3. **World Bible context** — the current `WorldData` (location, flags,
   `consequenceWeb`, living NPCs) must be serialized and included every call.
   Never assume the model remembers prior turns beyond what's explicitly passed
   in `NarrativeMemory`.
4. **Deep-Lore NPC directive** — any newly introduced NPC MUST include a
   `loreOrigin` (a real, specific folklore/cultural anchor — see
   `lore-authenticity`) and a `culturalArchetype`. Reject/regenerate output that
   introduces an NPC without both.
5. **World Memory directive** — Pocket Dimension has no suspicion/exposure
   meter. Instruct the model to: (a) create a new consequence entry when the
   player does something narratively significant, with a one-line `summary`,
   `involvedNpcIds`, `location`, and an initial `spreadLevel` of `secret`; (b)
   reference existing entries (passed in via `consequenceWeb`) through NPC
   dialogue or environmental detail when appropriate, rather than treating every
   turn as a blank slate; (c) escalate an entry's `spreadLevel` when the player
   revisits related NPCs/locations in a way that would plausibly spread word of
   it; (d) occasionally flip a `dormant` entry to `active`, turning it into a
   real event rather than a background fact. Cap new entries at one per turn
   unless the action genuinely warrants more — a consequence web that grows too
   fast is as flat as no memory at all.
6. **Grounding context** — if `lore-rag-retrieval` surfaced relevant chunks for
   this turn, they arrive as a separate "Grounding Context" section. Weave
   specifics from it into the narration naturally — never quote it verbatim, and
   don't force a reference if nothing relevant was retrieved.
7. **Output format directive** — the model must return ONLY a JSON object
   matching the `StateDelta` schema below. No prose before or after the JSON, no
   markdown code fences unless the client strips them before parsing.

## StateDelta output schema (keep in sync with `lib/models/state_delta.dart`)

```json
{
  "narration": "string, required, the prose shown to the player",
  "flagsSet": ["string", "..."],
  "consequenceUpdates": [
    {
      "id": "string, new id for a new entry, existing id to update one",
      "summary": "string, required for new entries",
      "involvedNpcIds": ["string"],
      "location": "string",
      "spreadLevel": "secret | rumored | known | legendary",
      "status": "dormant | brewing | active | resolved",
      "triggerHint": "string, optional"
    }
  ],
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

Every field `StateDelta.fromJson` expects must appear in the prompt's schema
description. If you add a field to the Dart model, update this prompt (and this
skill file) in the same change — schema drift between the model and the prompt is
the most common source of silent parse failures.

## Reactivity & variety (prevents generic looping narration)

If the DM starts producing near-identical narration regardless of player input
("manifest divine intent," "the ether pulses," on repeat), the model is falling
back to safe filler instead of engaging with the turn. Guard against this:

- The prompt must instruct the model to **directly reference the literal content
  of the player's last message** in the first sentence of `narration`. Generic
  scene-setting disconnected from what the player typed counts as a bad response.
- Pass the player's raw input as its own clearly labeled field (e.g.
  `player_input: "..."`), never buried inside a pre-formatted paragraph — losing
  it in string concatenation is the #1 cause of "same answer no matter what I
  type."
- Instruct the model to **avoid reusing phrases, metaphors, or sentence openers**
  already present in `recentTurns` — pass the last 2–3 narration outputs back
  specifically so it can check against them, not just a summarized state.
- Temperature: keep it near 0 only for parts of the schema that must be exact
  (field names, enums, numeric ranges). For `narration` specifically, use
  ~0.8–1.0 — low temperature on a schema-constrained call is exactly why output
  loops on the same safe phrasing.
- If the raw Gemini response is already generic (not a client-side bug), fix it
  prompt-side: add 2–3 few-shot example turns showing a player action followed
  by narration that visibly reacts to specifics. This works far more reliably
  than abstract instructions like "be more descriptive."

## Opening World Briefing (turn zero)

The first message a player sees after character creation isn't a reaction to
player input — there is no player action yet. Treat it as a distinct call with
its own system prompt, not a variant of the turn-by-turn directive:

- Triggered once, automatically, the moment character creation completes —
  before the chat screen accepts input. Show a loading state during generation
  (a good candidate for streaming, so it doesn't feel like a dead pause).
- Must cover three things concretely: **where** the character currently is (a
  specific place, not "a mysterious land"), **what's currently going on** in the
  world (drawn from the World Bible's initial flags/rumors/NPCs — this should
  feel like arriving mid-story, not a blank slate), and **what the surroundings
  look like through this character's guise** specifically — origin should
  visibly color the description.
- End on an implicit invitation to act, not an explicit "what do you do?"
- May optionally seed 1–2 initial `consequenceUpdates` representing the world's
  status quo at arrival, but must not assume a player message is present in
  context, since there isn't one yet.
- Stored as the first entry in `NarrativeMemory.recentTurns`, exactly as a normal
  DM turn, so later summarization treats it consistently.

## Memory summarization

- When `recentTurns` crosses the configured threshold, trigger a summarization
  call that compresses older turns into `rollingSummary` (~500 tokens) rather
  than truncating them outright.
- Use a separate, shorter system prompt for summarization — reusing the full DM
  persona prompt wastes tokens and can leak narration style into what should be
  a neutral summary.

## Streaming

- Prefer the streaming API for narration calls so the UI can render text as it
  arrives (see `flutter-ui-conventions` for the reveal-animation requirement).
  Non-streaming is acceptable for World Bible generation, where the player is
  waiting on a structured result, not reading prose live.

## Error handling requirements

- If the response isn't valid JSON, or is missing a required field, don't crash
  or silently apply a partial delta — surface a narration-safe fallback ("The
  thread of the story wavers — try that again") and retry once before showing an
  error state.
- Never let a malformed AI response reach `applyDelta` unvalidated — enforcing
  that is `state-delta-safety`'s job, but the client must call it every time.
  Use whenever writing, editing, or debugging the Gemini system prompt, API payload construction, or response parsing in lib/network/gemini_client.dart. Trigger on tasks like "update the DM prompt," "fix the AI response parsing," "add a new directive to the DM," or any change touching StateDelta generation.

Pocket Dimension — Gemini DM Prompting Rules

gemini_client.dart is the single place the DM's "personality" and output contract live. Every change here must preserve both the narrative tone and the strict output schema — a prompt tweak that improves prose but breaks JSON parsing is a regression, not an improvement.

System prompt structure (required sections, in this order)
Persona & tone — the DM is a narrator, not a game master rolling dice against the player. No combat-failure language, no "you take damage" framing.
God-Mode constraint — explicitly instruct the model there is no HP, no Mana, no fail states for the player character. Stakes come from the World Memory consequence web and relationships, never from a health bar.
World Bible context — the current WorldData (location, flags, consequenceWeb, living NPCs) must be serialized and included every call. Never assume the model remembers prior turns beyond what's explicitly passed in NarrativeMemory.
Deep-Lore NPC directive — any newly introduced NPC MUST include a loreOrigin (a real, specific folklore/cultural anchor — see lore-authenticity) and a culturalArchetype. Reject/regenerate output that introduces an NPC without both.
World Memory directive — Pocket Dimension has no suspicion/exposure meter. Instruct the model to: (a) create a new consequence entry when the player does something narratively significant, with a one-line summary, involvedNpcIds, location, and an initial spreadLevel of secret; (b) reference existing entries (passed in via consequenceWeb) through NPC dialogue or environmental detail when appropriate, rather than treating every turn as a blank slate; (c) escalate an entry's spreadLevel when the player revisits related NPCs/locations in a way that would plausibly spread word of it; (d) occasionally flip a dormant entry to active, turning it into a real event rather than a background fact. Cap new entries at one per turn unless the action genuinely warrants more — a consequence web that grows too fast is as flat as no memory at all.
Grounding context — if lore-rag-retrieval surfaced relevant chunks for this turn, they arrive as a separate "Grounding Context" section. Weave specifics from it into the narration naturally — never quote it verbatim, and don't force a reference if nothing relevant was retrieved.
Output format directive — the model must return ONLY a JSON object matching the StateDelta schema below. No prose before or after the JSON, no markdown code fences unless the client strips them before parsing.
StateDelta output schema (keep in sync with lib/models/state_delta.dart)

The live API returns narration and delta fields nested under a state_delta key, using snake_case — not the flat camelCase originally assumed. StateDelta.fromJson now handles both shapes (checks state_delta/delta/flat, and falls back between snake_case and camelCase per field), so either shape parses correctly — but any new field added to the model must get the same dual-key fallback treatment, or it will silently fail to populate on whichever shape it doesn't handle.

Verified live shape (this is the actual current contract, test against this):

json
{
  "narration": "string, required, the prose shown to the player",
  "state_delta": {
    "flags_set": {"key": "value"},
    "consequence_updates": [
      {
        "id": "string, new id for a new entry, existing id to update one",
        "summary": "string, required for new entries",
        "involved_npc_ids": ["string"],
        "location": "string",
        "spread_level": "secret | rumored | known | legendary",
        "status": "dormant | brewing | active | resolved",
        "trigger_hint": "string, optional"
      }
    ],
    "npc_updates": [
      {
        "id": "string",
        "loreOrigin": "string, required for new NPCs",
        "culturalArchetype": "string, required for new NPCs",
        "trust": 0,
        "disposition": "string",
        "knownFacts": ["string"]
      }
    ],
    "inventory_add": ["string"],
    "inventory_remove": ["string"],
    "location_change": "string or null"
  }
}

Every field StateDelta.fromJson expects must appear in the prompt's schema description, in the shape the prompt actually asks the model to return. If you change the model instructed to the schema, or upgrade to a Gemini version that changes its default output shape again, update this block and the parser's fallback keys in the same change — schema drift between the model and the parser is the most common source of silent parse failures.

Reactivity & variety (prevents generic looping narration)

If the DM starts producing near-identical narration regardless of player input ("manifest divine intent," "the ether pulses," on repeat), the model is falling back to safe filler instead of engaging with the turn. Guard against this:

The prompt must instruct the model to directly reference the literal content of the player's last message in the first sentence of narration. Generic scene-setting disconnected from what the player typed counts as a bad response.
Pass the player's raw input as its own clearly labeled field (e.g. player_input: "..."), never buried inside a pre-formatted paragraph — losing it in string concatenation is the #1 cause of "same answer no matter what I type."
Instruct the model to avoid reusing phrases, metaphors, or sentence openers already present in recentTurns — pass the last 2–3 narration outputs back specifically so it can check against them, not just a summarized state.
Temperature: keep it near 0 only for parts of the schema that must be exact (field names, enums, numeric ranges). For narration specifically, use ~0.8–1.0 — low temperature on a schema-constrained call is exactly why output loops on the same safe phrasing.
If the raw Gemini response is already generic (not a client-side bug), fix it prompt-side: add 2–3 few-shot example turns showing a player action followed by narration that visibly reacts to specifics. This works far more reliably than abstract instructions like "be more descriptive."
Opening World Briefing (turn zero)

The first message a player sees after character creation isn't a reaction to player input — there is no player action yet. Treat it as a distinct call with its own system prompt, not a variant of the turn-by-turn directive:

Triggered once, automatically, the moment character creation completes — before the chat screen accepts input. Show a loading state during generation (a good candidate for streaming, so it doesn't feel like a dead pause).
Must cover three things concretely: where the character currently is (a specific place, not "a mysterious land"), what's currently going on in the world (drawn from the World Bible's initial flags/rumors/NPCs — this should feel like arriving mid-story, not a blank slate), and what the surroundings look like through this character's guise specifically — origin should visibly color the description.
End on an implicit invitation to act, not an explicit "what do you do?"
May optionally seed 1–2 initial consequenceUpdates representing the world's status quo at arrival, but must not assume a player message is present in context, since there isn't one yet.
Stored as the first entry in NarrativeMemory.recentTurns, exactly as a normal DM turn, so later summarization treats it consistently.
Memory summarization
When recentTurns crosses the configured threshold, trigger a summarization call that compresses older turns into rollingSummary (~500 tokens) rather than truncating them outright.
Use a separate, shorter system prompt for summarization — reusing the full DM persona prompt wastes tokens and can leak narration style into what should be a neutral summary.
Streaming
Prefer the streaming API for narration calls so the UI can render text as it arrives (see flutter-ui-conventions for the reveal-animation requirement). Non-streaming is acceptable for World Bible generation, where the player is waiting on a structured result, not reading prose live.
Rate limit (429) handling

The free tier has a daily/per-minute request ceiling. On a 429 response:

Extract the real retry delay from the API's own error message (e.g. "Please retry in 10 seconds") via a parseRetryDelaySeconds-style parser — don't guess a fixed delay.
Apply exponential backoff across repeated attempts (e.g. 10s → 20s → ...), not a single retry.
Surface the wait to the player as in-world narration (e.g. "The threads of fate are tangled — waiting 10s before trying again...") rather than a raw error or the generic malformed-response fallback — a rate limit is a different situation from a broken response and should read differently to the player.
Cover this with a dedicated test file (e.g. test/rate_limit_429_test.dart) verifying delay parsing and backoff timing, separate from the state-delta-safety validation tests.
Error handling requirements
If the response isn't valid JSON, or is missing a required field, don't crash or silently apply a partial delta — surface a narration-safe fallback ("The thread of the story wavers — try that again") and retry once before showing an error state.
Never let a malformed AI response reach applyDelta unvalidated — enforcing that is state-delta-safety's job, but the client must call it every time.