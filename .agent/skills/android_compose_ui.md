# Skill: Android Compose RPG UI

## Objective
Build the Android front end: a chat-style narration stream, character sheet, and light
animations, backed by the Game State Schema and the Gemini DM Engine skills.

## Rules of Engagement
- **Architecture**: MVVM. One `GameViewModel` per active session, exposing a
  `StateFlow<GameUiState>`. Composables are stateless where possible; hoist state up.
- **Core screens to build, in this order**:
  1. Character Creation — freeform name/backstory entry + stat point allocation (not a
     locked class picker; supports "be anything").
  2. Main Narration Screen — scrolling chat-style log (DM narration as one bubble style,
     player input as another), text input field, and a compact always-visible HP/level bar.
  3. Character Sheet (modal or side panel) — stats, inventory, abilities, quest log.
  4. Save/Load screen — list of save slots backed by Room.
- **Animations, kept light**: use Lottie for discrete moments (level up, critical
  success/failure on a check, entering a new location) — not continuous ambient motion.
  Trigger animations from one-shot events in the ViewModel (`SharedFlow<GameEvent>`),
  never from state changes directly, to avoid replaying them on recomposition.
- **Persistence**: Room database, one table for save slots storing the serialized
  Game State Schema JSON blob plus metadata (slot name, last-played timestamp,
  thumbnail/location string for the save-list UI).
- **Offline behavior**: queue player input if the API call fails due to connectivity;
  show a clear "waiting to reconnect" state rather than losing the input.
- **Testing**: every Composable screen gets a preview with sample `GameUiState`; the
  ViewModel's state-reduction logic gets unit tests independent of the Gemini call
  (mock the DM engine response).
# Skill: Android UI Architecture (Flutter/Compose)

## Objective
Build the Android front-end focusing on the narration stream, world memory, and fluid UI[cite: 1].

## Rules of Engagement
- **Main Narration Screen**: A scrolling chat-style log (DM narration as one bubble style, player input as another), and a text input field[cite: 1]. 
- **World/Suspicion UI**: Instead of an HP bar, implement a "Masquerade" or "Regional Heat" indicator that visualizes the `world.regional_suspicion` integer for the current location.
- **Character/World Sheet**: A side panel displaying the player's inventory, current active regional rumors, and known named NPCs in the area[cite: 1].
- **Animations**: Use Lottie for discrete moments[cite: 1]. Trigger animations from the ViewModel on specific state deltas (e.g., a screen shake when a massive suspicion spike occurs)[cite: 1].
- **Offline behavior**: Queue player input if the AI API call fails due to connectivity; show a clear "waiting to reconnect" state[cite: 1].