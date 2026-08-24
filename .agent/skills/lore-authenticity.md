---
name: lore-authenticity
description: Use whenever generating or reviewing World Bible content, NPC loreOrigin/culturalArchetype fields, or any narrative/prompt content describing a setting's folklore or culture. Trigger on tasks like "generate the World Bible," "create a new NPC," or "write flavor text for this region."
---

# Pocket Dimension — Lore Authenticity Rules

`NpcRelationship.loreOrigin` and `culturalArchetype` exist to make Deep-Lore NPCs feel
grounded rather than generic fantasy filler. That only works if the lore anchor is
specific — a real, describable folklore or cultural tradition — not a vague regional
label standing in for research.

## Be specific, not monolithic

- Avoid treating a continent-scale label (e.g. "African," "Asian," "Middle Eastern")
  as if it were a single culture. A World Bible prompt like "African high fantasy"
  should be interpreted as an invitation to pick and commit to specific traditions
  (a named region, a specific mythological framework, a specific folk-tale
  archetype) rather than blending an undifferentiated pastiche.
- `loreOrigin` should name something concrete enough that a player could look it up
  — a specific spirit/trickster/deity archetype, a specific oral-tradition motif, a
  specific historical or folk practice reimagined for the setting — not just
  "based on African mythology."

## Avoid flattening into stereotype

- Don't default every NPC from a given cultural anchor to the same handful of
  surface traits (the same accent-coded speech pattern, the same "wise elder" or
  "mystic" role) — vary role, disposition, and narrative function the way a real
  cast would, while keeping the folklore anchor genuine.
- Villainy, comic relief, and moral complexity should be distributed across NPCs
  regardless of which cultural tradition they're anchored in — no single lore
  origin should be reserved only for antagonists or only for background color.

## Consistency across a single World Bible

- Once a World Bible commits to a region/tradition, new NPCs generated later in the
  same playthrough should stay coherent with what's already established (same
  pantheon/cosmology rules, same geography implications) rather than each DM call
  inventing an unrelated mythological framework for convenience.

## When generating NPCs via the DM prompt

- Reject (per `state-delta-safety`) any `npcUpdates` entry that introduces a new
  NPC with a generic or missing `loreOrigin` — this is what enforces the rule at
  runtime, not just at prompt-writing time.
- If uncertain whether a generated element is a genuine folklore reference or an
  invented-sounding placeholder, prefer regenerating the NPC over shipping a vague
  one — the whole point of the Deep-Lore system is that it's checkable, not just
  atmospheric.
