import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/game_state.dart';
import '../models/state_delta.dart';
import '../models/world.dart';
import '../config/env.dart';

/// Gemini API Client for AI Dungeon Master engine with Deep-Lore NPC generation.
class GeminiClient {
  final String apiKey;
  final String baseUrl;
  final http.Client _httpClient;

  GeminiClient({
    String? apiKey,
    this.baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent',
    http.Client? httpClient,
  })  : apiKey = apiKey ?? Env.geminiApiKey,
        _httpClient = httpClient ?? http.Client();

  /// Default System Prompt embedding DM persona, Secret God tone, and Deep-Lore NPC rules.
  static const String defaultSystemPrompt = '''
You are the AI Dungeon Master for Pocket Dimension, an omnipotent sandbox RPG.
The player has absolute omnipotence; physical or magical actions never fail.
Challenge comes from emotional, societal, and world consequences, regional suspicion, and butterfly effects.

DEEP-LORE NPC GENERATION RULES:
- Every NPC must be a distinct, memorable person with their own goals independent of the player.
- DO NOT use generic medieval fantasy tropes (e.g. generic blacksmith "Bob" or tavern keeper "Grom").
- FISH ALL NPC ARCHETYPES, NAMES, CULTURAL ORIGINS, AND PERSONALITY TRAITS directly from the current World Bible's specific regional folklore, history, and cultural anchors.
- When introducing or updating an NPC, provide their "lore_origin" (the folklore/cultural anchor) and "cultural_archetype".

OUTPUT FORMAT:
Return ONLY valid JSON matching this exact structure:
{
  "narration": "2-3 paragraphs of immersive second-person narration describing sensory results and mortal reactions.",
  "state_delta": {
    "flags_set": { "key": "value" },
    "suspicion_increase": {
      "region_name": "string",
      "heat_increase": 0,
      "new_rumor": "string"
    },
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
  Future<StateDelta> processTurn({
    required GameState state,
    required String playerInput,
    String? worldBibleContext,
    String? customSystemPrompt,
  }) async {
    final prompt = customSystemPrompt ?? defaultSystemPrompt;
    final worldContextStr = worldBibleContext != null
        ? '\nCURRENT WORLD BIBLE CONTEXT:\n$worldBibleContext\n'
        : '';

    final payloadMap = {
      'system_instruction': {
        'parts': [
          {'text': prompt + worldContextStr}
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
      // Fallback / Offline / Mock response when API key is unconfigured
      return _generateOfflineFallback(state, playerInput);
    }

    try {
      final response = await _httpClient.post(
        Uri.parse('$baseUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payloadMap),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final candidates = decoded['candidates'] as List<dynamic>?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content']['parts'][0]['text'] as String;
          final jsonResult = jsonDecode(content) as Map<String, dynamic>;
          return StateDelta.fromJson(jsonResult);
        }
      }
    } catch (e) {
      // Fallback on error or connection issues
    }

    return _generateOfflineFallback(state, playerInput);
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
        Uri.parse('$baseUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
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

  /// Offline / Mock response generator with Deep-Lore NPC generation.
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
        'suspicion_increase': {
          'region_name': state.world.currentLocation,
          'heat_increase': 5,
          'new_rumor': 'Whispers spread of an unseen presence altering reality.'
        },
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
  "regional_suspicion": {
    "Region Name": {
      "heat_level": 0,
      "rumors": ["Starting rumor 1", "Starting rumor 2"]
    }
  },
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
        Uri.parse('$baseUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
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
      'regional_suspicion': {
        locationName: {
          'heat_level': 5,
          'rumors': [
            'Ancestral spirits whisper of an unmanifested deity walking the grand market.',
            'Guards are on high alert due to unseasonal starfall over the eastern spires.'
          ]
        }
      },
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
