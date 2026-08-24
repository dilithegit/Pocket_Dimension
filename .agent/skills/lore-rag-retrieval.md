---
name: lore-rag-retrieval
description: Use whenever building, modifying, or debugging the lore ingestion pipeline (Wikipedia fetching, chunking, embedding) or the per-turn retrieval/grounding step that injects source material into the DM prompt. Trigger on tasks like "add lore grounding," "fix the retrieval," "update the ingestion pipeline," or any file under lib/lore/ or lib/network/embedding*.
---

# Pocket Dimension — Lore RAG Retrieval

This is not a training pipeline. No model is being trained. This is retrieval:
pull real reference material once per world, store it locally, and hand the most
relevant pieces to Gemini as grounding context on each turn. Gemini remains the
only generative model in the system.

## Ingestion (runs once per world, not per turn)

- **Trigger**: immediately after the World Weaver screen generates the World
  Bible, before the player reaches character creation. Show a lightweight
  loading indicator ("Gathering lore...") — this can happen in parallel with
  character creation rather than blocking it, since the corpus is only needed
  once the player reaches the chat screen.
- **Topic extraction**: pull 3–6 search topics from the generated World Bible —
  the overall theme, each initial NPC's `loreOrigin`/`culturalArchetype`, and any
  named region. Don't over-fetch: 3–6 topics keeps ingestion fast and keeps the
  embedding call count (and cost) modest.
- **Source**: Wikipedia's public search + extract API
  (`https://en.wikipedia.org/w/api.php`, `action=query`, `prop=extracts`) — no
  API key required. Pull the plain-text extract, not the full wikitext markup.
- **Chunking**: split each extract into ~200-word chunks with roughly 20-word
  overlap between consecutive chunks, so retrieval doesn't cut a relevant fact in
  half at a chunk boundary.
- **Embedding**: use `gemini-embedding-001` via the `embedContent` endpoint, with
  `output_dimensionality: 768` — full 3072-dim vectors are unnecessary for a
  per-world corpus this small and just bloat local storage.
- **Storage**: a new `lore_chunks` SQLite table — `id`, `saveSlotId`,
  `sourceTitle`, `sourceUrl`, `chunkText`, `embedding` (stored as a JSON-encoded
  array of doubles), `createdTurn`. Scoped per save slot — corpora don't need to
  be shared across different worlds.
- **Attribution**: store `sourceUrl` alongside each chunk. It's not shown in
  narration (the DM paraphrases/generates from it, never quotes it verbatim to
  the player), but keep it available for a future "sources" or "codex" view —
  Wikipedia content is CC BY-SA and citing it is good practice even when it's
  only feeding generation rather than being displayed directly.

## Retrieval (runs every turn)

- Embed the player's current input using the same `gemini-embedding-001` model
  and dimensionality — mismatched dimensionality between stored and query
  vectors breaks cosine similarity, so this must stay in sync with ingestion.
- Compute cosine similarity against all `lore_chunks` rows for the current save
  slot. A linear scan is fine at this scale (expect low hundreds of rows per
  world, not thousands) — don't add a vector database dependency for this.
- Take the top 3 chunks by similarity. If the best match's similarity is below a
  reasonable relevance floor (tune empirically — start around 0.5), don't inject
  anything rather than forcing in a weak, off-topic match.
- Inject the selected chunks into the DM system prompt as a clearly labeled
  **Grounding Context** section, separate from the World Bible / consequence web
  context, so the model can distinguish "established world state" from
  "reference material it may draw on."

## What this does and doesn't fix

- It should measurably reduce generic looping narration (see the Reactivity &
  variety section of `gemini-dm-prompting`) — genuinely specific retrieved facts
  are harder for the model to loop on than open-ended improvisation.
- It does not replace the reactivity fixes already in place (referencing the
  player's literal input, avoiding phrase reuse from `recentTurns`) — this skill
  adds grounding on top of those, it doesn't substitute for them.
- It is not a path to a smaller/custom model. If a distilled model is built later
  from collected play logs (see the fine-tuning note in `gemini-dm-prompting`),
  that's a separate, later project — this skill only covers retrieval.

## Cost awareness

- Ingestion costs one embedding call per chunk, once per world — keep chunk
  counts modest (roughly 20-40 chunks per world is plenty).
- Retrieval costs one embedding call per player turn (for the query) — this is
  small and worth it, but don't add extra embedding calls beyond the one
  query-per-turn without a clear reason.
