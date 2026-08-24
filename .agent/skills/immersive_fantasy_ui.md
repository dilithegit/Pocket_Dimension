# Skill: Immersive Fantasy UI (Pocket Dimension)

## Objective
Give Pocket Dimension a visual identity that feels like a portal into a specific world,
not a generic chat-app skin. Every UI decision should be derived from the player's
current World Bible (from the World Weaver skill) — the app should look different for
a player in a frost-giant saga than one in a sun-scorched desert empire.

## Rules of Engagement
- **Derive the token system from the World Bible, not defaults.** For each world,
  generate a small design token set:
  - **Color**: 4-6 named hex values pulled from the world's actual imagery (a coastal
    kingdom's palette differs from a volcanic wasteland's). Never default to generic
    "fantasy purple + gold."
  - **Type**: a characterful display face for headers/narration titles + a highly
    readable body face for the narration stream itself (readability wins for the main
    text feed — this is a text-heavy app first).
  - **Signature element**: one unique visual motif per world (an ornamental border
    style, an icon language for stats, a particular divider glyph) drawn from that
    world's culture/aesthetic — the one thing that makes a screenshot instantly
    recognizable as *this* world.
- **The narration stream is the hero, not a chat bubble list.** Avoid making it look
  like a generic messaging app. Consider: a manuscript/journal feel, illuminated
  drop-caps on scene changes, subtle parchment or void-and-starlight backgrounds
  depending on world tone — but keep it performant and readable at small sizes.
- **Motion is earned, not ambient.** Reserve animation for real narrative beats: level
  up, a critical spell success/failure, entering a new region for the first time. Avoid
  decorative idle animation — it reads as generic and burns battery on Android.
- **One risk, then restraint.** Pick a single bold, world-specific signature element per
  world and keep everything else (spacing, secondary buttons, system chrome) quiet and
  disciplined around it. Don't stack multiple "big ideas" in one screen.
- **Respect accessibility and reduced-motion.** Every world skin still needs readable
  contrast ratios for body text, visible focus states, and to respect the system
  reduced-motion setting even when a world's aesthetic leans dramatic.
- **Copy matches the world's voice.** Button labels, empty states, and error messages
  should be written in-world where it fits ("The mists are unclear — try again" instead
  of a raw network error) without sacrificing clarity about what actually happened.
- **Before finalizing any new world's skin, self-critique it**: would this token set be
  mistaken for a different world's? If yes, it's still generic — go back to the World
  Bible and pull something more specific.
