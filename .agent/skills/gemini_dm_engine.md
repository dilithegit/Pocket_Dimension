# Skill: AI Dungeon Master Engine (Gemini)

## Objective
Build and maintain the layer that turns "current game state + player's freeform text
action" into "narration + a validated state delta," using the Gemini API. This is what
makes "be anything, do anything" work without hand-scripting every outcome.

## Rules of Engagement
- **One call, structured output.** Every player turn sends: (1) a system prompt with
  the DM persona and world tone, (2) `narrative_memory.rolling_summary`, (3) the last
  few raw turns, (4) the current `character` and `world` objects, (5) the player's new
  input. Request a JSON response shaped as:

```json
{
  "narration": "string, 1-3 paragraphs, second person, shown to the player",
  "state_delta": {
    "hp_change": 0,
    "inventory_add": [], "inventory_remove": [],
    "flags_set": {}, "xp_gain": 0,
    "new_quest": null, "quest_update": null
  },
  "requires_check": null
}
```

- **Resolve uncertain/risky actions with a check, not vibes.** If the player attempts
  something with a real chance of failure or a fantastical/limitless action ("I try to
  reshape the sky"), the model should NOT just narrate success. It sets
  `requires_check: { "stat": "wit", "difficulty": 14 }`; the client rolls
  (1d20 + stat modifier) and sends the result back in a second call for the model to
  narrate the outcome. This keeps "you can do anything" fun instead of consequence-free.
- **Never let the model freely rewrite the state object.** It only ever proposes a
  *delta*. The Game State Schema skill's validator is the gatekeeper — apply deltas
  through `GameStateManager`, never trust `state_delta` blindly.
- **Summarization pass**: once `recent_turns` exceeds ~10 entries, run a separate
  lightweight call that folds the oldest entries into `rolling_summary` and trims them
  out. This keeps token usage (and cost) flat as playtime grows — critical for a
  "go big" open sandbox where sessions can run long.
- **Cost/rate-limit discipline**: batch the "did we cross the summarization threshold"
  check client-side so you're not calling the model more than once per real player turn
  plus occasional summarization passes. Cache the system prompt server-side if the SDK
  supports it.
- **Content boundaries**: the DM persona prompt should explicitly forbid generating
  content involving minors in sexual/romantic contexts, real identifiable people, or
  extremist material, regardless of player prompting — bake this into the system
  prompt once, don't rely on per-turn filtering.
- **Error handling**: on malformed JSON or API failure, retry once with a stricter
  "return ONLY valid JSON" instruction; on second failure, show the player a graceful
  in-world message ("the mists swirl and the path is unclear... try again") rather than
  a raw error.
#### 2. `secret_god_engine.md`
```md
# Skill: Secret God Engine (Gemini DM)

## Objective
Power the narration loop using the Gemini API. The player has absolute omnipotence; actions never fail. The challenge is entirely about managing the world's memory, mortal reactions, and the unfolding butterfly effect of playing god in secret.

## Rules of Engagement
- **One call, structured output.** Every player turn sends: the system prompt, `narrative_memory`, recent turns, current `character` and `world` states, and the player input. Request this JSON response:
```json
{
  "narration": "string, 2-3 paragraphs, describing the immediate sensory output and local mortal reactions.",
  "state_delta": {
    "flags_set": {}, 
    "suspicion_increase": { "region_name": 10, "new_rumor": "string" },
    "npc_updates": [ { "id": "string", "trust_change": 0, "new_fact": "string" } ]
  }
}