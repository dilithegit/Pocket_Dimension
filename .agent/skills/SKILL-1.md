---
name: flutter-ui-conventions
description: Use whenever building, modifying, or reviewing any Flutter widget, screen, or theme file in Pocket Dimension. Covers color palette, typography, spacing, component style, and motion rules. Trigger on tasks like "build a screen," "create a widget," "style this," or any file under lib/screens/, lib/widgets/, or lib/theme/.
---

# Pocket Dimension — UI Conventions

Pocket Dimension is a text-driven AI-DM RPG with a **dark illuminated-manuscript
aesthetic**: deep indigo/void backgrounds with warm gold accents, like a
grimoire read by candlelight rather than a paper factbook in daylight. This
direction was confirmed deliberately (not a default Material fallback) —
every screen must read as "an illuminated manuscript with a pulse," built from
custom-shaped components, not default Material widgets with colors swapped in.

**Known open item**: the app icon concept (oxblood leather, warm parchment
background, brass clasp) predates this direction and currently clashes with
it — revisit the icon to match the dark indigo/gold palette once the in-app
polish pass below is done, so the two aren't fighting each other.

## Non-negotiable rule

Never invent a new color, font, spacing value, or corner radius inline in a widget.
If `lib/theme/` doesn't already define the token you need, add it there first, then
consume it. Drift between screens (different accents, different radii) is a bug, not
a style choice — flag it and fix it rather than adding a new one-off value.

## Design tokens (define these in `lib/theme/` if not already present)

**Color roles** — not literal hex values, define semantically:
- `background` — deep indigo/blue-black void, not pure #000
- `surface` — card/panel background, a lifted dark indigo, distinct from background
- `ink` — primary text color, light lavender-white, not pure #FFF
- `accent` — warm parchment-gold, used sparingly: primary action, active state,
  narration highlight, illuminated borders/flourishes
- `memoryDormant / memoryBrewing / memoryActive / memoryResolved` — a small color
  family for tagging consequence-entry status in the World Memory panel (subtle,
  informational — not an alarm gradient; this system has no threat meter)

**Typography**
- Display/narration face: a serif with character, used for DM narration text and
  world/NPC names — this is the "storybook" voice
- UI face: a clean, highly legible sans for buttons, labels, input fields, HUD text
- Never mix a third typeface in without adding it to the type scale first

**Spacing & shape**
- Use a single spacing scale (e.g. 4/8/12/16/24/32) — no arbitrary padding values
- One corner-radius value for cards, a smaller one for chips/buttons — pick once, reuse

## Component conventions

**Custom, not default Material.** This is the actual fix for "feels cheap" —
the audit found real `AppBar`, `ActionChip`, and `Card` primitives with colors
reskinned on top, which reads as a themed default app, not a bespoke one.
Every component below should be a custom-shaped/custom-painted widget, not a
Material primitive with a `color:` property changed:

- **Save slot cards**: illustrated, not a `Card` with a border — custom shape
  with an illuminated gold corner flourish or filigree line, a mood-color
  swatch or small icon derived from the world's `culturalArchetype`/theme,
  world name, last-played timestamp, character name
- **Chat/narration bubbles**: DM narration in the serif display face, player
  input in the UI sans face — visually distinct voices. Player input should be
  a custom-shaped bubble (not a default `Container` with `BorderRadius`), with
  a subtle gold-outline treatment consistent with the illuminated-manuscript
  direction
- **Buttons**: custom-shaped, not stock `ElevatedButton`/`IconButton.filled` —
  primary action uses `accent` with a subtle glow/illuminated edge, secondary/
  destructive actions stay muted — don't let every button compete for attention
- **Quick-reply/suggestion chips** (used by both the online DM and the
  offline story engine's fallback suggestions): custom shape with a thin gold
  outline, not stock `ActionChip`
- **App bar / top chrome**: consider whether a default `AppBar` fits an
  illuminated-manuscript feel at all, or whether a custom top treatment
  (an illuminated title banner, no hard Material elevation shadow) reads
  better — don't default to `AppBar` just because it's the Flutter default
- **World Memory panel**: lives in the existing end-drawer (replacing the old
  "Regional Rumors" tab) as a scrollable list of consequence entries — summary,
  involved NPCs, and a small status tag using the `memory*` color family. This is
  reference material the player can check, not a persistent HUD element; there's
  no ambient meter for this system, since there's no threat level to visualize
  continuously.
- **Consequence notifications**: when a new consequence entry is created or an
  existing one activates, surface it through the existing top-anchored
  `GameNotificationOverlay` toast (the same mechanism used for new Deep-Lore NPCs)
  rather than inventing a second notification pattern — one punctual "something
  changed" moment, not a running gauge.

## Motion

- Text reveal for DM narration should feel like it's being written, not dumped
- Screen transitions: consistent single **bespoke** transition project-wide
  (not Flutter's default route transition) — e.g. a slow fade through the
  indigo void with a brief gold flicker, distinct enough to feel authored
  rather than default. Every screen must use the same one.
- Consider a small illuminated flourish (a glowing drop-cap, a gold underline
  animation) on the first letter of an Opening World Briefing or major story
  beat — small, not gratuitous, but this is the kind of detail that separates
  "themed" from "designed"
- No gratuitous particle/confetti effects — motion should support the reading pace,
  not compete with it

## Navigation & back button (custom router)

Pocket Dimension uses a custom state-based screen router rather than named
`Navigator` routes — the router swaps which screen widget is displayed based on
app state (SaveSlots ↔ WorldWeaver ↔ CharacterCreation ↔ Chat) instead of pushing
onto the `Navigator` stack. This means the system back button has no route history
to pop by default, and will exit the app instead of going to the previous screen
unless explicitly handled.

**Required:** the router must maintain its own explicit back-stack (a list of the
screens visited, appended only on genuine forward navigation, not on rebuilds),
and the root widget must intercept the system back gesture (`PopScope`, not the
deprecated `WillPopScope`, since this targets SDK 34) to pop that stack and
re-render the previous screen. Only let the system back button actually exit the
app when the stack is down to its single root entry (SaveSlotsScreen). Any new
screen added to the router must be wired into this same back-stack — don't let a
screen bypass it by navigating directly.

## Accessibility

- Text/background contrast must pass WCAG AA on the dark indigo/gold palette —
  check this explicitly, gold-on-dark-indigo can under-contrast at lower
  opacities even though it looks fine at full brightness
- Minimum 44x44 logical-pixel tap targets on all interactive elements
- Don't encode suspicion state in color alone — pair the ambient tint with a small
  textual/iconographic cue for colorblind accessibility

## When extending this skill

If you add a new screen type (e.g. a settings screen, a codex/lore browser), add its
component conventions to this file rather than letting the building session improvise
— this file is the single source of truth for "what Pocket Dimension looks like."