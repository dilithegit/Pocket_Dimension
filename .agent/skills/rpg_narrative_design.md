# Skill: RPG Narrative & Game Design Rules

## Objective
Keep the "be anything, do anything" promise fun and consistent rather than chaotic.
This skill is the design-rules reference the DM Engine skill's prompts are built from.

## Rules of Engagement
- **Character creation flow**: player writes a short freeform concept ("a disgraced
  librarian who steals memories") instead of picking from a fixed class list. The
  system then:
  1. Assigns starting stat leanings that fit the concept (wit-heavy for the librarian).
  2. Generates 2-3 starting abilities from the concept, not a fixed spell list.
  3. Lets the player nudge/approve before locking in.
- **Resolution mechanic**: d20 + relevant stat modifier vs a difficulty number set by
  the DM engine based on how ambitious the action is. Mundane actions (walk, talk,
  pick a lock) usually auto-succeed with no roll — only roll when there's real stakes
  or real uncertainty. This is what keeps "limitless" actions from feeling consequence-free.
- **World consistency**: the DM must treat `world.flags` and `npc_relationships` as
  hard truth it cannot contradict. If a flag says a bridge is destroyed, no future
  narration can casually have the player walk across it. Continuity checks belong here,
  enforcement belongs in the DM Engine skill's validator.
- **Tone contract**: default tone is adventurous, PG-13-ish fantasy/sci-fi (violence in
  a game-combat sense is fine; graphic gore, sexual content involving minors, and real
  people are always out of bounds regardless of player framing). Document any tone
  changes here so the DM Engine's system prompt stays in sync with this file.
- **Failure is content, not a dead end**: a failed check should produce an interesting
  complication (the lock breaks and alarms the guards) rather than "nothing happens" or
  a hard game-over. This is what makes an open sandbox stay fun over long sessions.
  #### 4. `rpg_narrative_design.md`
```md
# Skill: RPG Narrative Design Rules

## Objective
Define the "Yes, And..." philosophy of a limitless world[cite: 4].

## Rules of Engagement
- **Character Creation**: The player defines their own reality. Ask them to describe their guise, the universe they are standing in, and their ultimate ambition[cite: 4]. Generate the world around that premise.
- **Consequence, not Failure**: Because the player cannot fail a physical or magical action, pushback must be emotional and societal. If they level a city, the narrative consequence is that an NPC they liked is now terrified of them, or the regional economy collapses.
- **World Consistency**: The DM must treat `world.flags` and `regional_suspicion` as hard truth[cite: 4]. If a regional flag says the kingdom believes a trickster spirit is active, local guards must be narrated as being on high alert for supernatural activity.
