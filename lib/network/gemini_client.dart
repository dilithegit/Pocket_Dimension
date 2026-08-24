import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/game_state.dart';
import '../models/state_delta.dart';
import '../models/world.dart';
import '../config/env.dart';

/// Gemini API Client for AI Dungeon Master engine with Deep-Lore NPC generation and Consequence Web memory.
class GeminiClient {
  /// Default Gemini Flash model string for generation endpoints.
  /// MIGRATION NOTE (2026-08-24): Migrated from deprecated `gemini-2.5-flash` to `gemini-3.6-flash`.
  /// REMINDER: Check Google's Gemini API model deprecation notices regularly before assuming a
  /// hardcoded model string will keep working long-term (second forced model deprecation migration).
  static const String defaultModelName = 'gemini-3.6-flash';
  static const String defaultBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$defaultModelName:generateContent';

  final String apiKey;
  final String baseUrl;
  final http.Client _httpClient;

  GeminiClient({
    String? apiKey,
    this.baseUrl = defaultBaseUrl,
    http.Client? httpClient,
  })  : apiKey = apiKey ?? Env.geminiApiKey,
        _httpClient = httpClient ?? http.Client() {
    _initSanityCheck();
  }

  void _initSanityCheck() {
    final isPresent = apiKey.isNotEmpty;
    debugPrint('[GeminiClient] x-goog-api-key header set: $isPresent, length: ${apiKey.length}');
  }

  /// Verification helper throwing clear error if GEMINI_API_KEY is not configured.
  static void verifyApiKeyConfigured() {
    if (Env.geminiApiKey.isEmpty) {
      throw StateError('GEMINI_API_KEY not found — check secrets.json and --dart-define-from-file');
    }
  }

  /// Centralized HTTP request header builder attaching x-goog-api-key without exposing it in URLs.
  Map<String, String> _buildHeaders() {
    final isPresent = apiKey.isNotEmpty;
    debugPrint('[GeminiClient] x-goog-api-key header set: $isPresent, length: ${apiKey.length}');
    return {
      'Content-Type': 'application/json',
      if (isPresent) 'x-goog-api-key': apiKey,
    };
  }

  /// Embeds [text] using gemini-embedding-001 with output_dimensionality: 768.
  Future<List<double>> embedText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return List.filled(768, 0.0);

    const embedUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-embedding-001:embedContent';

    final body = {
      'model': 'models/gemini-embedding-001',
      'content': {
        'parts': [
          {'text': trimmed}
        ]
      },
      'outputDimensionality': 768,
    };

    try {
      final response = await _httpClient.post(
        Uri.parse(embedUrl),
        headers: _buildHeaders(),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final embeddingObj = data['embedding'] as Map<String, dynamic>?;
        final values = embeddingObj?['values'] as List<dynamic>?;

        if (values != null && values.isNotEmpty) {
          return values.map((v) => (v as num).toDouble()).toList();
        }
      }
    } catch (_) {}

    // Fallback: return 768-dim vector if API key is missing or offline
    return List.filled(768, 0.0);
  }

  /// Default System Prompt embedding DM persona, Secret God tone, World Memory directives, and Deep-Lore NPC rules.
  static const String defaultSystemPrompt = '''
You are the AI Dungeon Master for Pocket Dimension, an omnipotent sandbox RPG.
The player character is an unmanifested deity in human guise with absolute omnipotence; physical or magical actions NEVER fail. There are NO hit points, NO mana, and NO mechanical fail states.

DM PERSONA & STAKES:
- You are an evocative narrator, not a game master rolling dice against the player.
- Never use combat-failure or game-over language.
- Stakes come strictly from the World Memory consequence web, relationships, societal butterfly effects, and emotional weight.

WORLD MEMORY DIRECTIVE (CONSEQUENCE WEB):
- Pocket Dimension has NO suspicion or exposure meter.
- The world retains memory of divine actions through a network of consequences (`consequence_web`).
- (a) CREATE a new consequence entry (`consequence_updates`) when the player performs a narratively significant act. Set a concise one-line `summary`, list `involved_npc_ids`, current `location`, `spread_level` (default "secret"), `status` (default "dormant" or "brewing"), and a `trigger_hint`.
- (b) REFERENCE existing entries in `consequence_web` through NPC dialogue, subtle rumors, or environmental changes rather than treating turns as a blank slate.
- (c) ESCALATE an entry's `spread_level` ("secret" -> "rumored" -> "known" -> "legendary") when the player revisits related NPCs or locations where news would naturally travel.
- (d) EVOLVE an entry's `status` ("dormant" -> "brewing" -> "active" -> "resolved") when consequences erupt into active narrative events.
- Cap new consequence entries at 1 or 2 per turn to keep the consequence web meaningful.

DEEP-LORE NPC GENERATION RULES:
- Every newly introduced NPC MUST include a `lore_origin` (a real, specific folklore, historical, or mythic cultural anchor) and a `cultural_archetype`.
- DO NOT use generic medieval fantasy tropes (e.g., generic blacksmith "Bob" or tavern keeper "Grom").
- Fish all NPC archetypes, names, lore origins, and personality traits directly from the reference World Bible culture.

REACTIVITY & NARRATIVE VARIETY:
- Your FIRST sentence in `narration` MUST directly reference the literal content of the player's last input (`player_input`).
- Avoid repeating metaphors, sentence openers, or phrasing used in `recent_turns`.
- Write 2-3 paragraphs of immersive, sensory second-person narration ("You...").

OUTPUT FORMAT:
Return ONLY valid JSON matching this exact structure:
{
  "narration": "2-3 paragraphs of immersive second-person narration reacting to the player's action.",
  "state_delta": {
    "flags_set": { "key": "value" },
    "consequence_updates": [
      {
        "id": "string (new ID or existing ID to update)",
        "summary": "string",
        "involved_npc_ids": ["string"],
        "location": "string",
        "origin_turn": 1,
        "spread_level": "secret|rumored|known|legendary",
        "status": "dormant|brewing|active|resolved",
        "trigger_hint": "string or null"
      }
    ],
    "npc_updates": [
      {
        "id": "string",
        "name": "string",
        "role": "string",
        "lore_origin": "string",
        "cultural_archetype": "string",
        "personality_tags": ["string"],
        "goal": "string",
        "secret": "string or null",
        "trust": 0,
        "disposition": "friendly|neutral|wary|hostile",
        "known_facts": ["string"]
      }
    ],
    "inventory_add": [ { "id": "string", "name": "string", "qty": 1 } ],
    "inventory_remove": [ { "id": "string", "name": "string", "qty": 1 } ],
    "location_change": null
  }
}
''';

  /// Generates the next turn narration and state delta based on current state and player input.
  /// Generates the next turn narration and state delta based on current state and player input.
  /// Subscribes to SSE stream via streamGenerateContent and emits incremental text deltas via [onTextDelta].
  Future<StateDelta> processTurn({
    required GameState state,
    required String playerInput,
    String? worldBibleContext,
    String? groundingContext,
    String? customSystemPrompt,
    void Function(String textDelta)? onTextDelta,
  }) async {
    final prompt = customSystemPrompt ?? defaultSystemPrompt;
    final worldContextStr = worldBibleContext != null
        ? '\nCURRENT WORLD BIBLE CONTEXT:\n$worldBibleContext\n'
        : '';
    final groundingStr = (groundingContext != null && groundingContext.isNotEmpty)
        ? '\n$groundingContext\n'
        : '';

    final payloadMap = {
      'system_instruction': {
        'parts': [
          {'text': prompt + worldContextStr + groundingStr}
        ]
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {
              'text': jsonEncode({
                'rolling_summary': state.narrativeMemory.rollingSummary,
                'recent_turns': state.narrativeMemory.recentTurns,
                'character': state.character.toJson(),
                'world': state.world.toJson(),
                'player_input': playerInput,
              })
            }
          ]
        }
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
      }
    };

    if (apiKey.isEmpty) {
      final offlineDelta = _generateOfflineFallback(state, playerInput);
      onTextDelta?.call(offlineDelta.narration);
      return offlineDelta;
    }

    try {
      final jsonBody = jsonEncode(payloadMap);
      debugPrint('=== [GEMINI SSE STREAMING REQUEST] ===');

      final streamUrl = baseUrl.replaceAll(':generateContent', ':streamGenerateContent') + '?alt=sse';
      final request = http.Request('POST', Uri.parse(streamUrl));
      final headers = _buildHeaders();
      headers.forEach((key, val) => request.headers[key] = val);
      request.body = jsonBody;

      final response = await _httpClient.send(request);
      debugPrint('=== [GEMINI STREAM STATUS]: ${response.statusCode} ===');

      if (response.statusCode == 200) {
        final StringBuffer fullContentBuffer = StringBuffer();
        final StringBuffer sseLineBuffer = StringBuffer();
        String lastEmittedNarration = '';

        await for (final chunk in response.stream.transform(utf8.decoder)) {
          sseLineBuffer.write(chunk);
          final lines = sseLineBuffer.toString().split('\n');
          sseLineBuffer.clear();
          if (!chunk.endsWith('\n') && lines.isNotEmpty) {
            sseLineBuffer.write(lines.removeLast());
          }

          for (final rawLine in lines) {
            final line = rawLine.trim();
            if (line.startsWith('data: ')) {
              final jsonStr = line.substring(6).trim();
              if (jsonStr.isEmpty || jsonStr == '[DONE]') continue;

              try {
                final Map<String, dynamic> data = jsonDecode(jsonStr);
                final candidates = data['candidates'] as List<dynamic>?;
                if (candidates != null && candidates.isNotEmpty) {
                  final parts = candidates[0]['content']?['parts'] as List<dynamic>?;
                  if (parts != null && parts.isNotEmpty) {
                    final textPart = parts[0]['text'] as String?;
                    if (textPart != null && textPart.isNotEmpty) {
                      fullContentBuffer.write(textPart);

                      // Extract and notify narration text deltas in real-time
                      final currentFull = fullContentBuffer.toString();
                      final match = RegExp(r'"narration"\s*:\s*"(.*?)"', dotAll: true).firstMatch(currentFull);
                      if (match != null) {
                        final extractedNarration = (match.group(1) ?? '')
                            .replaceAll(r'\"', '"')
                            .replaceAll(r'\n', '\n')
                            .replaceAll(r'\\', '\\');
                        if (extractedNarration.length > lastEmittedNarration.length) {
                          final delta = extractedNarration.substring(lastEmittedNarration.length);
                          lastEmittedNarration = extractedNarration;
                          onTextDelta?.call(delta);
                        }
                      }
                    }
                  }
                }
              } catch (_) {
                // Ignore partial JSON parse errors on SSE chunks
              }
            }
          }
        }

        final fullContent = fullContentBuffer.toString().trim();
        debugPrint('=== [GEMINI FULL STREAMED RESPONSE] ===\n$fullContent\n==================================');

        if (fullContent.isNotEmpty) {
          try {
            final jsonResult = jsonDecode(fullContent) as Map<String, dynamic>;
            return StateDelta.fromJson(jsonResult);
          } catch (e) {
            debugPrint('[GeminiClient] Assembled JSON parse failed: $e');
          }
        }
      }
    } catch (e, stackTrace) {
      debugPrint('=== [GEMINI STREAM ERROR]: $e ===\n$stackTrace');
    }

    final fallback = _generateOfflineFallback(state, playerInput);
    onTextDelta?.call(fallback.narration);
    return fallback;
  }

  /// Summarize narrative memory when turns exceed the threshold (~10 turns).
  Future<String> summarizeMemory({
    required String currentSummary,
    required List<String> turnsToSummarize,
  }) async {
    if (apiKey.isEmpty) {
      return '$currentSummary\n[Further events unfolded: ${turnsToSummarize.take(3).join('; ')}]';
    }

    try {
      final prompt = 'Summarize the following RPG exchanges into a concise memory log (~500 tokens max), updating the existing summary:\nExisting Summary: $currentSummary\nNew Exchanges:\n${turnsToSummarize.join('\n')}';

      final response = await _httpClient.post(
        Uri.parse(baseUrl),
        headers: _buildHeaders(),
        body: jsonEncode({
          'contents': [
            {
              'parts': [{'text': prompt}]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final candidates = decoded['candidates'] as List<dynamic>?;
        if (candidates != null && candidates.isNotEmpty) {
          return candidates[0]['content']['parts'][0]['text'] as String;
        }
      }
    } catch (_) {}

    return '$currentSummary\n[Summarized ${turnsToSummarize.length} turns]';
  }

  /// Offline / Mock response generator with Deep-Lore NPC generation and Consequence Web memory.
  StateDelta _generateOfflineFallback(GameState state, String input) {
    String lowerInput = input.toLowerCase();
    bool involvesNpc = lowerInput.contains('talk') ||
        lowerInput.contains('speak') ||
        lowerInput.contains('meet') ||
        lowerInput.contains('look');

    List<Map<String, dynamic>> npcUpdates = [];
    if (involvesNpc) {
      npcUpdates.add({
        'id': 'npc_kofi_elder',
        'name': 'Kofi the Memory Weaver',
        'role': 'Lore Keeper of the High Coast',
        'lore_origin': 'West African High Fantasy Storytelling Traditions',
        'cultural_archetype': 'Griot of the Secret Grove',
        'personality_tags': ['watchful', 'erudite', 'reverent'],
        'goal': 'Preserve the sacred songs of creation before mortals forget them',
        'secret': 'Knows that an unremembered god walks the earth',
        'trust': 2,
        'disposition': 'wary',
        'known_facts': ['Observed a strange shift in the weave of reality'],
      });
    }

    return StateDelta.fromJson({
      'narration':
          'You manifest your divine intent: "$input". The ambient ether pulses in response as mortals around you witness the subtle ripple of your presence.',
      'state_delta': {
        'flags_set': {'last_action': input},
        'consequence_updates': [
          {
            'id': 'c_offline_ripple',
            'summary': 'Subtle ether currents rippled through the realm',
            'involved_npc_ids': involvesNpc ? ['npc_kofi_elder'] : [],
            'location': state.world.currentLocation,
            'origin_turn': 1,
            'spread_level': 'secret',
            'status': 'dormant',
            'trigger_hint': 'Sensitives felt a subtle ripple'
          }
        ],
        'npc_updates': npcUpdates,
        'inventory_add': [],
        'inventory_remove': [],
        'location_change': null
      }
    });
  }

  /// Generates initial World Bible (WorldData) JSON based on player's prompt.
  Future<WorldData> generateWorldBible({required String worldConceptPrompt}) async {
    if (apiKey.isEmpty) {
      return _generateFallbackWorldBible(worldConceptPrompt);
    }

    const systemPrompt = '''
You are the World Weaver AI for Pocket Dimension.
Given a player's world concept prompt (e.g., "African High Fantasy" or "Steampunk Coastal Empire"), generate an original, cohesive fantasy world bible matching this exact JSON shape:
{
  "current_location": "Name of the starting capital city or prominent region",
  "consequence_web": [
    {
      "id": "c_init_1",
      "summary": "Starting world echo or ancient secret",
      "involved_npc_ids": ["npc_1"],
      "location": "Starting location name",
      "origin_turn": 0,
      "spread_level": "secret",
      "status": "dormant",
      "trigger_hint": "Ancient rumors persist in secret"
    }
  ],
  "flags": {
    "world_theme": "Concept summary",
    "world_creation_date": "Timestamp"
  },
  "npc_relationships": {
    "npc_1": {
      "id": "npc_1",
      "name": "Full Name",
      "role": "Social or Military Role",
      "lore_origin": "Specific folklore or historical cultural anchor",
      "cultural_archetype": "Specific archetype from the reference culture",
      "personality_tags": ["tag1", "tag2"],
      "goal": "Private goal independent of player",
      "secret": "Deep secret or null",
      "trust": 0,
      "disposition": "neutral",
      "known_facts": ["Starting knowledge"],
      "last_seen_turn": 0
    }
  }
}
Return ONLY valid JSON.
''';

    final payloadMap = {
      'system_instruction': {
        'parts': [{'text': systemPrompt}]
      },
      'contents': [
        {
          'role': 'user',
          'parts': [{'text': 'Generate a World Bible for concept: $worldConceptPrompt'}]
        }
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
      }
    };

    try {
      final response = await _httpClient.post(
        Uri.parse(baseUrl),
        headers: _buildHeaders(),
        body: jsonEncode(payloadMap),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final candidates = decoded['candidates'] as List<dynamic>?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content']['parts'][0]['text'] as String;
          final jsonResult = jsonDecode(content) as Map<String, dynamic>;
          return WorldData.fromJson(jsonResult);
        }
      }
    } catch (_) {}

    return _generateFallbackWorldBible(worldConceptPrompt);
  }

  WorldData _generateFallbackWorldBible(String conceptPrompt) {
    String locationName = conceptPrompt.toLowerCase().contains('african')
        ? 'Sun-Citadel of Kemet-Asili'
        : 'Sovereign Haven of $conceptPrompt';

    return WorldData.fromJson({
      'current_location': locationName,
      'consequence_web': [
        {
          'id': 'c_init_sunfire',
          'summary': 'Ancestral spirits whisper of an unmanifested deity walking the grand market',
          'involved_npc_ids': ['npc_kofi_weaver'],
          'location': locationName,
          'origin_turn': 0,
          'spread_level': 'secret',
          'status': 'dormant',
          'trigger_hint': 'Griots detect ether fluctuations over the eastern spires'
        }
      ],
      'flags': {
        'world_concept': conceptPrompt,
        'pantheon_status': 'Dormant deities watching in secret',
      },
      'npc_relationships': {
        'npc_kofi_weaver': {
          'id': 'npc_kofi_weaver',
          'name': 'Kofi the Griot',
          'role': 'Keeper of oral traditions',
          'lore_origin': 'Sahelian High Empire Epic Songs',
          'cultural_archetype': 'Elder Memory Keeper',
          'personality_tags': ['reverent', 'observant', 'shrewd'],
          'goal': 'Protect the sacred lineage songs from royal censors',
          'secret': 'Carries a shard of the original sunstone',
          'trust': 2,
          'disposition': 'neutral',
          'known_facts': ['Knows the market alleys better than the royal guards'],
          'last_seen_turn': 0,
        },
        'npc_zoya_captain': {
          'id': 'npc_zoya_captain',
          'name': 'Commander Zoya',
          'role': 'Citadel Gate Warden',
          'lore_origin': 'Swahili Coastal City-State Navy',
          'cultural_archetype': 'Disciplined Fortress Guard',
          'personality_tags': ['tactical', 'unyielding'],
          'goal': 'Expose corrupt merchants smuggling forbidden reliquaries',
          'secret': 'Owes a blood debt to an unknown benefactor',
          'trust': 0,
          'disposition': 'wary',
          'known_facts': ['Noticed unusual ether fluctuations at midnight'],
          'last_seen_turn': 0,
        }
      }
    });
  }
}
