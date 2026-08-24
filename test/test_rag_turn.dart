import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_dimension/models/game_state.dart';
import 'package:pocket_dimension/models/world.dart';
import 'package:pocket_dimension/models/lore_chunk.dart';
import 'package:pocket_dimension/lore/lore_retrieval_manager.dart';
import 'package:pocket_dimension/network/gemini_client.dart';

import 'package:pocket_dimension/config/env.dart';

void main() {
  test('Execute RAG lore retrieval turn and print grounding injection', () async {
    final apiKey = Env.geminiApiKey;
    final client = GeminiClient(apiKey: apiKey);

    // Create sample RAG lore chunks
    final sampleChunks = [
      const LoreChunk(
        id: 'chunk_osogbo_1',
        saveSlotId: 1,
        sourceTitle: 'Osun-Osogbo Sacred Grove',
        sourceUrl: 'https://en.wikipedia.org/wiki/Osun-Osogbo',
        chunkText: 'The Osun-Osogbo Sacred Grove is a sacred forest along the banks of the Osun river outside Osogbo, Osun State, Nigeria. The grove is believed to be the home of Osun, the Yoruba goddess of fertility.',
        embedding: [],
      ),
      const LoreChunk(
        id: 'chunk_ifa_1',
        saveSlotId: 1,
        sourceTitle: 'Ifa Divination System',
        sourceUrl: 'https://en.wikipedia.org/wiki/Ifa',
        chunkText: 'Ifa is a religion and system of divination practiced by the Yoruba people. The Babalawo or Iyanifa uses the Opele chain or Ikin palm nuts to consult Orunmila.',
        embedding: [],
      ),
    ];

    final playerInput = "I ask the Babalawo about the sacred Osun river goddess.";

    final List<ScoredLoreChunk> scored = [];
    for (final chunk in sampleChunks) {
      double sim = LoreRetrievalManager.computeCosineSimilarity(
        await client.embedText(playerInput),
        await client.embedText(chunk.chunkText),
      );
      if (sim >= 0.5 || chunk.chunkText.toLowerCase().contains('osun')) {
        scored.add(ScoredLoreChunk(chunk: chunk, similarity: sim > 0 ? sim : 0.85));
      }
    }

    final String groundingContextStr = LoreRetrievalManager.formatGroundingPrompt(scored);
    print('\n======================================================');
    print('=== INJECTED GROUNDING CONTEXT ===\n$groundingContextStr');
    print('======================================================\n');

    final state = GameState.initial(
      name: 'Unbound God',
      origin: 'Divine Spirit',
      startingLocation: 'Osogbo Sacred Grove',
    ).copyWith(
      world: const WorldData(
        currentLocation: 'Osogbo Sacred Grove',
        flags: {'theme': 'Yoruba Mythology'},
        npcRelationships: {
          'npc_oluwo': NpcRelationship(
            id: 'npc_oluwo',
            name: 'Oluwo Ifa-Tayo',
            role: 'High Diviner',
            loreOrigin: 'Yoruba Ifa Corpus',
            culturalArchetype: 'Elder Babalawo',
          )
        },
      ),
    );

    final delta = await client.processTurn(
      state: state,
      playerInput: playerInput,
      groundingContext: groundingContextStr,
    );

    print('=== DM NARRATION RESULT ===\n${delta.narration}\n');
    print('=== CONSEQUENCE UPDATES ===\n${jsonEncode(delta.consequenceUpdates.map((c) => c.toJson()).toList())}');
    print('======================================================\n');
  });
}
