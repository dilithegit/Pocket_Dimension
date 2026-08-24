# Skill: World Weaver (Grounded World Generation)

## Objective
Let a player describe the world they want to live in — including real-world-inspired
themes like "African high fantasy" — and generate an original, cohesive fantasy world
inspired by real research, not gameplay-time web lookups.

## Rules of Engagement
- **This runs once, at world creation** — not during live play. Live narration
  (the Gemini DM Engine skill) should run entirely against the compiled world bible
  produced here, for speed, cost, and narrative consistency. Never let the DM engine
  make live web calls mid-scene.
- **Step 1 — clarify, don't assume**: if the player's description is broad (e.g. "an
  African themed world"), the agent should ask 1-2 quick follow-up questions to narrow
  it — which region/era/culture cluster resonates most (e.g. West African coastal
  kingdoms, Sahelian empires, Ethiopian highlands, Great Zimbabwe-era south-east
  Africa), and what fantasy elements to blend in (dragons, elemental magic, etc.). This
  produces a far richer, more specific world than a single flattened "African" aesthetic.
- **Step 2 — grounded research**: use real web search (Gemini's search grounding or an
  equivalent tool call) to gather reference material on the chosen culture cluster's
  mythology, architecture, textile/art motifs, social structures, and folklore
  archetypes. Pull from reputable sources (museums, academic/cultural sites, established
  reference works) over generic blogs.
- **Step 3 — synthesize, don't copy**: generate an *original* fantasy world inspired by
  that research — invented kingdom names, invented pantheon, invented geography — using
  real cultural texture (naming conventions, social values, artistic motifs, oral
  storytelling traditions) as flavor, not as a reskin of real history or real living
  cultures/religions. Avoid stereotype shorthand; aim for the same specificity real
  historical fantasy settings (a la a detailed secondary-world) get.
- **Output — the World Bible**: a structured document (`world_bible.json` or `.md`)
  covering: cosmology/magic system flavor, 3-5 major regions/factions, a pantheon or
  belief system, a timeline of 2-3 defining historical events, and a glossary of
  invented proper nouns. This feeds the DM Engine's system prompt for the whole
  playthrough.
- **Player approval gate**: show the drafted World Bible to the player and let them
  edit/regenerate sections before locking it in — this is a one-time setup cost worth
  spending carefully since it shapes every future session.
