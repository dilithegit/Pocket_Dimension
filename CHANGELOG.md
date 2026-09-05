# Pocket Dimension — v2.5 Release Notes

## Major features
- **World Memory / Consequence Web** replaces the old suspicion/exposure meter entirely — no numeric threat gauge; the world remembers discrete events (secret → rumored → known → legendary spread, dormant → brewing → active → resolved status), surfaced via a drawer panel and one-off notifications.
- **Opening World Briefing** — a scene-setting arrival narration generated automatically after character creation, naming a specific location and reflecting the character's guise, before the player types anything.
- **Lore RAG grounding** — the DM now grounds narration in real Wikipedia material: 3-6 topics pulled from each World Bible, chunked and embedded once per world, retrieved by similarity per turn, and woven into narration without being quoted verbatim.
- **Offline Story Engine** — a fully authored, zero-network story mode (branching nodes, keyword intent matching, narration variant rotation, and quick-reply fallbacks) with a Greek-African-mixed-fantasy tale, alongside the existing pre-woven Nigerian sandbox. Grimoire Settings is now a 3-way realm picker: Online AI DM, Nigerian Sandbox, Greek-African Mythic Tale.

## Fixes
- Back button no longer exits the app from any screen — the custom router now maintains an explicit back-stack with `PopScope`.
- Fixed the root cause of repetitive/generic DM narration: migrated off the shut-down `gemini-1.5-flash` (currently `gemini-3.5-flash-lite`), added reactivity rules so narration reacts to the player's literal input, and added exponential-backoff handling for 429 rate limits with in-world waiting narration instead of a raw error.
- Fixed a schema mismatch between the documented `StateDelta` contract and the actual live API response shape (nested `state_delta`, snake_case keys) — the parser now handles both shapes with field-level fallback.
- Fixed a toast-notification bug where new/escalated consequence entries were compared against state already mutated by the same turn, so they never registered as new.
- Fixed `WorldData` nested map sub-type casting crash on World Weaver re-weaving using `asStringKeyedMap` helper.
- Injected prompt variance seed and procedural fallback diversity to prevent repetitive World Weaver initial world outputs.

## Security & Build Tooling
- API key moved out of source entirely — loaded via `--dart-define-from-file=secrets.json`, which is git-ignored. Any previously exposed key should be treated as rotated.
- Added canonical PowerShell build scripts (`build.ps1` and `build-release.ps1`) enforcing strict `secrets.json` pre-checks before compiling.

## Performance & polish
- Confirmed release builds are meaningfully faster than debug builds (cold start ~3.8s → ~1.2s) — performance should always be judged on release builds going forward.
- Resolved all `prefer_const_literals_to_create_immutables` warnings, which were causing real GC pressure during streaming/typing on budget hardware.
- Moved from default Material primitives (`AppBar`, `ActionChip`, `Card`) to custom-shaped components, in the confirmed **dark indigo/gold illuminated-manuscript** direction — deep indigo/void backgrounds, warm gold accents, illuminated flourishes, a single bespoke screen transition.

## Known open items
- App icon still reflects the earlier oxblood/parchment concept and needs a pass to match the current dark indigo/gold direction.
- Full launch-readiness audit (functional + non-functional checklist) not yet re-run against this version.
