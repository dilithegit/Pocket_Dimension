# 📜 Pocket Dimension — Omnipotent God-Mode AI RPG Engine

> *"As an omnipotent deity, your physical or magical intent never fails. Stakes come from mortal reactions, suspicion, and societal consequences."*

**Pocket Dimension** is a state-of-the-art Flutter roleplaying game engine driven by live AI narrative generation and persistent local state. Unlike traditional fantasy games bound by hit points and mana limits, Pocket Dimension places the player in the guise of an unmanifested deity whose actions strictly succeed, shifting gameplay stakes entirely to **Regional Suspicion**, **Living NPC Relationships**, and **Deep-Lore World Bible Consequences**.

---

## 🌟 Key Features

### 1. 📖 Schema Version 2 & God-Mode Rules
- **Zero HP, Zero Mana**: Player attributes focus strictly on Mortal Name, Guise/Origin, and Relics.
- **Canonical Schema Version 2**: State structure enforces atomic mutations across `character`, `world`, and `narrative_memory`.

### 2. 🌍 Dynamic World Weaver Engine
- **Live Concept Synthesis**: Generates rich, culturally grounded World Bibles containing regions, suspicion heat baselines, starting rumors, and deep-lore living NPCs.
- **Offline Nigerian Mythology Engine**: Toggleable local engine providing a pre-woven realm (*Mythical Surulere — Sun-Spire Citadel*) featuring Yoruba Ifa keepers (*Oluwo Ifa-Tayo*), Ife heroines (*Moremi of the Sun Gate*), and Benin coral oracles (*Priestess Akenzua*).

### 3. 💬 Book-Style Narrative Feed & Streaming DM
- **Prose Aesthetic**: DM narration rendered in Georgia serif display face on parchment background without chat bubbles, creating a book-reading experience.
- **Live Text-Reveal Stream**: DM prose streams live on-screen to simulate a live-typing Game Master.
- **Safety Fallback**: Intercepts network timeouts and parsing failures with in-world narration (*"The mists of reality swirl, clouding your vision. Try again."*).

### 4. 👁️ Suspicion & Masquerade HUD
- **Ambient Vignette Tint**: Non-blocking screen-edge tint interpolates smoothly (1.5s transition) through low, mid, and high suspicion color stops.
- **Dynamic Input Glow**: Soft glow on the prompt bar reacts to regional heat levels.
- **Peripheral Readout**: Compact eye icon + numeric readout (`Heat: X/100`) ensures full accessibility without relying on color alone.

### 5. 📇 Living World Sheet & Slide-out Drawer
- **Non-blocking End Drawer**: Access Living NPCs (roles, lore origins, goals, secrets), Regional Rumors, and Character Relics during gameplay.
- **Non-intrusive Toasts**: 3-second animated top overlay banners alert on suspicion spikes (>=10%) and newly encountered inhabitants.

### 6. 🗃️ SQLite Persistence & Illustrated Save Cards
- Save slots displayed as illustrated cards featuring world names, character guises, formatted timestamps, and mood-color swatches (`Amber Gold`, `Coastal Teal`, `Crimson Oxblood`, `Deep Indigo`).

---

## 🎨 Design System & Aesthetics

- **Color Palette**: Oxblood Leather (`#2D1418`), Warm Parchment (`#F4EAD5`), Antique Gold (`#D4AF37`), Dark Surface (`#120B0D`).
- **Typography Scale**: Georgia (Serif) for narrative prose, names, and lore titles; Roboto (Sans) for UI chrome, inputs, and status labels.
- **Icons & Splash**: Native oxblood leather adaptive launcher icons (66% safe zone constraint) and custom parchment splash screen.

---

## 🛠️ Tech Stack & Architecture

- **Framework**: Flutter 3.47.1 / Dart 3.13.1
- **State Management**: Provider (`GameStateManager extends ChangeNotifier`)
- **Database**: SQLite (`sqflite`, `path_provider`)
- **Network Layer**: `GeminiClient` (`gemini-3.6-flash` via SSE streaming & `gemini-embedding-001` RAG) with payload assembly, error retry logic, and memory summarization thresholding.
- **License**: MIT License

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>= 3.0.0)
- Android SDK (for Android APK builds)

### Installation & Run

1. Clone the repository:
```bash
git clone https://github.com/<your-username>/pocket-dimension.git
cd pocket-dimension
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app with your Gemini API key:
```bash
flutter run --dart-define=GEMINI_API_KEY="YOUR_GEMINI_API_KEY"
```

*(Note: You can also switch to Offline Mode in **Grimoire Configurations** to play without an API key!)*

4. Build release APK:
```bash
flutter build apk --release
```

---

## 📄 License

Distributed under the **MIT License**. See `LICENSE` for more information.
