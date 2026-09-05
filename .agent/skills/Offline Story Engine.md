---
name: offline-story-engine
description: Use whenever building, modifying, or debugging the offline authored-story mode (StoryNode graph, intent matching, the Grimoire Settings story picker). Trigger on tasks like "add a story node," "fix branch matching," "add a new offline tale," or any file under lib/offline_story/.
---

# Pocket Dimension — Offline Story Engine

This is a separate system from the online Gemini DM. It powers fixed, authored
storylines that work with zero network calls — not a smaller/local version of
the AI DM. Don't try to make this generative; its strength is being reliably
authored, not improvised.

## Data model

- `StoryNode`: `id`, `narrationVariants` (List<String>, 2-3 phrasings),
  `branches` (List<StoryBranch>), `flagsSetOnEntry` (Map<String,dynamic>),
  `requiredFlags` (optional gating — node only reachable if these are set)
- `StoryBranch`: `intentKeywords` (List<String>), `targetNodeId`,
  `flagsSet` (applied when this branch is taken)
- A story is a `List<StoryNode>` plus a `startNodeId`, authored as a JSON asset
  (e.g. `assets/stories/greek_african_fantasy.json`), not hardcoded Dart —
  keep authoring separate from engine code so new tales don't require a code
  change.

## Intent matching (free text, no model)

- On player input, score each `StoryBranch` available from the current node by
  keyword/phrase overlap between the input and `intentKeywords`. Take the
  highest-scoring branch above a minimum overlap threshold.
- If nothing clears the threshold, do not dead-end or repeat the same
  narration verbatim. Show a small set of 2-3 suggested next actions (drawn
  from the current node's branches) as tappable quick-replies beneath the
  input, so the player always has a visible way forward without breaking the
  free-text feel of typing.

## Variety (this is what makes it feel dynamic, not the branching alone)

- Each node must have at least 2 `narrationVariants`. Pick between them
  (random or based on a per-node visit counter) so revisiting a node — or a
  player who backtracks — never sees identical text twice in a row.
- Use simple template substitution for character name/origin and any flags
  already set, so the same node can read slightly differently depending on
  what's happened earlier in this playthrough.

## State carries forward, reusing existing patterns

- Reuse the `ConsequenceEntry` shape from the online World Memory system for
  any callback moments in the offline story (an earlier choice referenced by
  an NPC later) — don't invent a second, parallel state format for the same
  concept.
- Flags set via `flagsSetOnEntry`/`branches.flagsSet` are scoped to this
  offline playthrough only — they must never leak into or read from the
  online `WorldData`/`consequenceWeb`, these are separate save contexts.

## Integration point

- Extend the existing Grimoire Settings toggle (already used for the offline
  Nigerian mythology sandbox) into a picker between offline tales, rather than
  a single fixed offline experience — add the Greek-African-mixed-fantasy
  story as a second selectable option alongside it.
- This mode requires zero network calls at any point — verify no code path in
  this system ever calls `gemini_client.dart`.

## What this is not

- Not a replacement for the online DM's open-ended generation — that
  capability requirement doesn't apply here, this is intentionally a fixed,
  bounded story.
- Not a candidate for an on-device LLM — a fixed storyline doesn't need
  generation at all, and adding one here would just add cost/complexity/
  battery drain for a case that's already solved by authoring.