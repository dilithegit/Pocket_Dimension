# Skill: Game State Schema

## Objective
Define the single source of truth for the player's god-mode game state. Every other skill reads and writes through this schema.

## Rules of Engagement
- **Canonical shape**: State is one JSON object per save slot:
```json
{
  "schema_version": 2,
  "character": {
    "name": "string",
    "origin": "string (the player's chosen physical/conceptual guise)",
    "inventory": [ { "id": "string", "name": "string", "qty": 1 } ]
  },
  "world": {
    "current_location": "string",
    "regional_suspicion": { "region_name": { "heat_level": 0, "rumors": ["string"] } },
    "flags": { "any_key": "boolean | string | number" },
    "npc_relationships": { "npc_id": { "trust": 0, "disposition": "string", "known_facts": ["string"] } }
  },
  "narrative_memory": {
    "recent_turns": ["last ~10 raw exchanges"],
    "rolling_summary": "string, updated by the summarizer, ~500 tokens max"
  }
}