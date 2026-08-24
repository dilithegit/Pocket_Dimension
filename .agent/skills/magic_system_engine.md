# Skill: Magic System Engine

## Objective
Extend the Gemini DM Engine skill with rules specifically for freeform spellcasting —
the core fantasy of Pocket Dimension. A player can type any spell in plain language;
this skill defines how it gets resolved fairly.

## Rules of Engagement
- **Every cast is parsed into three dimensions** before resolution:
  1. `target_type`: self / object / willing creature / unwilling sentient creature
  2. `magnitude`: cosmetic (light a candle) → minor (lockpick, small illusion) →
     major (turn someone into an animal, raise the dead briefly) → reality-bending
     (stop time, resurrect permanently)
  3. `duration`: instant / scene-length / permanent
- **Difficulty formula**: base DC 8, +4 per magnitude tier above cosmetic, +4 if the
  target is an unwilling sentient creature, +4 if duration is permanent. This is what
  turns "make someone a donkey" into a genuinely risky, exciting act rather than a
  free win — exactly the kind of check the RPG Narrative Design skill calls for.
- **Resource cost**: every non-cosmetic cast costs `mana` (a stat-like resource in the
  character sheet, regenerates on rest). Reality-bending attempts should also risk
  `resolve` damage (mental/spiritual strain) on failure, not just "nothing happens."
- **Failure is a complication, never a null result**: per the Narrative Design skill,
  a failed cast should misfire in an interesting, in-world way — wrong target, delayed
  effect, unwanted attention, temporary side-effect on the caster.
- **Discipline flavor, not hard class walls**: a character's `magic discipline`
  (set at character creation) should make certain spells feel natural (lower DC) and
  others feel strained (higher DC) — but never outright forbidden. This preserves
  "be anything" while still making character concept matter.
- **Grounding in the DM Engine's `state_delta`**: a successful/failed cast still only
  ever proposes a delta (HP/mana change, flag set, inventory change) — this skill
  changes how the DC is computed, not how state gets written.
