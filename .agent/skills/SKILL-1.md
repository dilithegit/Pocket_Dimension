---
name: flutter-ui-conventions
description: Use whenever building, modifying, or reviewing any Flutter widget, screen, or theme file in Pocket Dimension. Covers color palette, typography, spacing, component style, and motion rules. Trigger on tasks like "build a screen," "create a widget," "style this," or any file under lib/screens/, lib/widgets/, or lib/theme/.
---

# Pocket Dimension — UI Conventions

Pocket Dimension is a text-driven AI-DM RPG with a parchment/illustrated-lore aesthetic
(same visual family as hand-drawn fantasy factbooks: warm paper tones, ink-line
detailing, restrained ornamentation). Every screen must read as "an illustrated
storybook with a pulse," not a generic Material dark-mode app.

## Non-negotiable rule

Never invent a new color, font, spacing value, or corner radius inline in a widget.
If `lib/theme/` doesn't already define the token you need, add it there first, then
consume it. Drift between screens (different accents, different radii) is a bug, not
a style choice — flag it and fix it rather than adding a new one-off value.

## Design tokens (define these in `lib/theme/` if not already present)

**Color roles** — not literal hex values, define semantically:
- `background` — warm parchment base, not pure black or pure white
- `surface` — card/panel background, slightly lifted from background
- `ink` — primary text color, near-black with warmth, not pure #000
- `accent` — one accent color per active World Bible (derived from world mood/theme),
  used sparingly: primary action, active state, narration highlight
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

- **Save slot cards**: illustrated, not plain list rows — show a mood-color swatch or
  small icon derived from the world's `culturalArchetype`/theme, world name, last-played
  timestamp, character name
- **Chat/narration bubbles**: DM narration in the serif display face, player input in
  the UI sans face — visually distinct voices
- **Buttons**: primary action uses `accent`, secondary/destructive actions stay muted —
  don't let every button compete for attention
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
- Screen transitions: consistent single transition style project-wide (e.g. fade +
  slight slide) — don't let different screens get different transition styles
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

- Text/background contrast must pass WCAG AA even with the warm parchment palette —
  check this explicitly, warm-toned palettes are easy to under-contrast
- Minimum 44x44 logical-pixel tap targets on all interactive elements
- Don't encode suspicion state in color alone — pair the ambient tint with a small
  textual/iconographic cue for colorblind accessibility

## When extending this skill

If you add a new screen type (e.g. a settings screen, a codex/lore browser), add its
component conventions to this file rather than letting the building session improvise
— this file is the single source of truth for "what Pocket Dimension looks like."
