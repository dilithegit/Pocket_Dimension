# Skill: Living NPC System

## Objective
Make named NPCs feel like individuals with their own story, not narration props —
they should remember the player, want things independent of the player, and change
over time.

## Rules of Engagement
- **NPC record shape** (stored under `world.npc_relationships[npc_id]`, extending the
  Game State Schema):

```json
{
  "name": "string",
  "role": "string, e.g. 'town guard captain'",
  "personality_tags": ["string", "..."],
  "goal": "string, what they privately want, independent of the player",
  "secret": "string or null, something not yet revealed to the player",
  "trust": 0,
  "disposition": "friendly|neutral|wary|hostile",
  "known_facts": ["short strings the NPC has learned from/about the player"],
  "last_seen_turn": 0
}
```

- **NPCs are created lazily**: the first time the DM engine names a recurring NPC, it
  proposes a new NPC record in the same `state_delta` used for everything else — don't
  pre-author a full cast list unless you want hand-picked major characters.
- **Memory persists across the whole playthrough**, not just the current scene. When
  the player re-encounters an NPC, include their record (goal, trust, known_facts) in
  the DM engine's prompt context so continuity holds — a guard you humiliated with a
  transfiguration spell three sessions ago should still act like it.
- **NPCs act on their own goals**, not just react to the player. Periodically (e.g. on
  location change or day passing), the DM engine may narrate an NPC advancing their own
  goal off-screen — this is what makes the world feel alive rather than paused when the
  player isn't looking at it.
- **Trust changes gradually and asymmetrically**: small kindnesses raise trust slowly;
  betrayals or hostile magic used on an NPC drop it sharply and are remembered
  indefinitely (store as a `known_fact`, not just a numeric dip that can silently recover).
- **Cap active memory**: only keep detailed records for NPCs the player has actually
  met more than once. Background/one-off NPCs don't need persistent records — this
  keeps prompt size (and cost) manageable in a large open world.
### 3. `living_npc_system.md`
```md
# Skill: Living NPC System

## Objective
Make named NPCs feel like individuals with their own story and their own perspective on the player's divine actions. 

## Rules of Engagement
- **NPC record shape**:
```json
{
  "name": "string",
  "role": "string",
  "personality_tags": ["string"],
  "goal": "string (independent of the player)",
  "trust": 0,
  "disposition": "friendly|neutral|wary|hostile",
  "known_facts": ["short strings the NPC has learned/observed about the player"]
}