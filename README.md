# 📜 Pocket Dimension — Omnipotent God-Mode AI RPG Engine (v1.0.0)

> *"As an omnipotent deity, your physical or magical intent never fails. Stakes come from mortal reactions, relationships, and societal consequence webs."*

**Pocket Dimension** is a state-of-the-art Flutter roleplaying game engine driven by live AI narrative generation and persistent local state. Unlike traditional RPGs bound by hit points, mana limits, or dice-roll failures, Pocket Dimension places the player in the guise of an unmanifested deity whose actions strictly succeed, shifting gameplay stakes entirely to **Living NPC Relationships**, **Societal Consequence Webs**, and **RAG-Grounded World Bibles**.

---

## 🌟 Key Features

### 1. ⚡ God-Mode Narrative Engine
- **Zero Fail States**: No hit points, no mana bars, and no combat-failure dice rolls.
- **Consequence Web**: Divine actions create persistent consequence entries (`secret` -> `rumored` -> `known` -> `legendary`) that evolve dynamically (`dormant` -> `brewing` -> `active` -> `resolved`).
- **Opening World Briefing**: Atmospheric initial narrative establishing starting location and character origin.

### 2. 🌍 Dynamic World Weaver & Deep-Lore NPCs
- **Grounded Worldbuilding**: Synthesizes custom World Bibles based on player prompts (e.g. *"Sahelian High Empire"* or *"Coastal Steampunk Citadel"*).
- **Deep-Lore Characters**: Every inhabitant contains a specific `lore_origin` (folklore, mythic, or historical anchor) and `cultural_archetype`, rejecting generic fantasy tropes.

### 3. 📚 RAG Lore Grounding (Retrieval-Augmented Generation)
- **Wikipedia Public Fetch**: Automatically extracts reference text for world topics upon World Bible creation.
- **768-Dim Vector Embeddings**: Chunks text (~200 words with ~20 word overlap) and embeds via `gemini-embedding-001`.
- **Cosine Similarity Scan**: Scans player input against stored lore chunks, injecting top 3 relevant grounding contexts into the DM system prompt in real-time.

### 4. 🌊 SSE Token Streaming & Word-by-Word Narration
- **Server-Sent Events (SSE)**: Streams `streamGenerateContent` text deltas via `x-goog-api-key` header authorization.
- **Incremental Prose Reveal**: Narration renders word-by-word on-screen with smooth auto-scroll.

### 5. 🛡️ Offline Fallback Mode
- Toggleable offline engine generating fallback narrative turns, RAG embeddings, and World Bibles without requiring network access or API key configuration.

---

## 🤖 Authored Agent Skills (`.agent/skills/`)

The core design and execution rules of Pocket Dimension are governed by authored skill definitions:

- **[`gemini-dm-prompting`](.agent/skills/gemini-dm-prompting.md)**: Standardized AI DM system instructions, God-Mode stakes, consequence web mechanics, and RAG grounding injection.
- **[`lore-rag-retrieval`](.agent/skills/lore-rag-retrieval.md)**: Wikipedia extract fetching, overlap chunking, 768-dim `gemini-embedding-001` storage, and cosine similarity RAG retrieval.
- **[`lore-authenticity`](.agent/skills/lore-authenticity.md)**: Directives for deep cultural anchoring and non-generic medieval fantasy NPC generation.
- **[`post-fix-workflow`](.agent/skills/post-fix-workflow/SKILL.md)**: Execution sequence (analyze & test -> build & install to physical hardware -> commit & push).
- **[`secrets-hygiene`](.agent/skills/secrets-hygiene.md)**: Header-based `x-goog-api-key` security, build-time `--dart-define-from-file` integration, zero-log credentials, and `.gitignore` hygiene.
- **[`state-delta-safety`](.agent/skills/state-delta-safety.md)**: Schema Version 2 canonical state validation, single-step status/spread escalation clamping, and fallback response safety.

---

## 🛠️ Tech Stack & Architecture

- **Framework**: Flutter 3.47.1 / Dart 3.13.1 (Android Platform)
- **State Management**: Provider (`GameStateManager extends ChangeNotifier`)
- **Database**: SQLite (`sqflite`, `path_provider`)
- **Network Layer**: `GeminiClient` (`gemini-3.6-flash` via SSE streaming & `gemini-embedding-001` RAG) with header-based authorization (`x-goog-api-key`).
- **Release Signing**: Custom release keystore referenced via git-ignored `android/key.properties`.

---

## 🚀 Getting Started

### 1. Prerequisites
- Flutter SDK (`>=3.0.0`)
- Android SDK (API 35 target)

### 2. Installation & Secrets Configuration
Create a `secrets.json` file at project root (git-ignored):
```json
{
  "GEMINI_API_KEY": "YOUR_GEMINI_API_KEY"
}
```

### 3. Run on Device
```bash
flutter run -d <device_id> --dart-define-from-file=secrets.json
```

### 4. Build Release APK
```bash
flutter build apk --release
```

---

## 📌 Known Limitations & Roadmap

- **Play Store Listing**: Google Play Console store listing graphics and privacy policy URL hosting pending for public app store release.
- **Multi-Slot Lore Isolation**: Future optimization to prune background SQLite lore chunks when save slots are deleted.

---

## 📄 License

Distributed under the **MIT License**. See `LICENSE` for details.
