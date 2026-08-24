import 'package:flutter/foundation.dart';
import '../models/world.dart';
import '../models/lore_chunk.dart';
import '../database/lore_chunk_repository.dart';
import '../network/gemini_client.dart';
import 'wikipedia_client.dart';

/// Lore Ingestion Manager executing background ingestion of Wikipedia lore chunks.
class LoreIngestionManager {
  final WikipediaClient wikipediaClient;
  final GeminiClient geminiClient;
  final LoreChunkRepository repository;

  LoreIngestionManager({
    WikipediaClient? wikipediaClient,
    GeminiClient? geminiClient,
    LoreChunkRepository? repository,
  })  : wikipediaClient = wikipediaClient ?? WikipediaClient(),
        geminiClient = geminiClient ?? GeminiClient(),
        repository = repository ?? LoreChunkRepository();

  /// Extracts 3-6 topics from [world], fetches extracts from Wikipedia,
  /// chunks them (~200 words with ~20 word overlap), embeds them via Gemini 768-dim embeddings,
  /// and stores them in SQLite under [saveSlotId].
  Future<int> runLoreIngestion(WorldData world, int saveSlotId) async {
    final List<String> topics = _extractTopics(world);
    final List<LoreChunk> allChunks = [];

    int chunkCounter = 0;

    for (final topic in topics) {
      final article = await wikipediaClient.fetchExtractForTopic(topic);
      if (article == null || article.extract.trim().isEmpty) continue;

      final textChunks = WikipediaClient.chunkText(
        article.extract,
        targetChunkWords: 200,
        overlapWords: 20,
      );

      for (final chunkText in textChunks) {
        chunkCounter++;
        final embedding = await geminiClient.embedText(chunkText);
        final chunk = LoreChunk(
          id: 'chunk_${saveSlotId}_${chunkCounter}_${DateTime.now().millisecondsSinceEpoch}',
          saveSlotId: saveSlotId,
          sourceTitle: article.title,
          sourceUrl: article.url,
          chunkText: chunkText,
          embedding: embedding,
          createdTurn: 0,
        );
        allChunks.add(chunk);
      }
    }

    if (allChunks.isNotEmpty) {
      await repository.insertLoreChunks(allChunks);
    }

    debugPrint('[LoreIngestionManager] Ingested ${allChunks.length} lore chunks across ${topics.length} topics for save slot $saveSlotId.');
    return allChunks.length;
  }

  /// Helper extracting 3-6 clean search topics from WorldData.
  List<String> _extractTopics(WorldData world) {
    final Set<String> topicSet = {};

    if (world.currentLocation.isNotEmpty) {
      topicSet.add(world.currentLocation);
    }

    if (world.flags['world_concept'] is String &&
        (world.flags['world_concept'] as String).trim().isNotEmpty) {
      topicSet.add((world.flags['world_concept'] as String).trim());
    }
    if (world.flags['theme'] is String &&
        (world.flags['theme'] as String).trim().isNotEmpty) {
      topicSet.add((world.flags['theme'] as String).trim());
    }

    for (final npc in world.npcRelationships.values) {
      if (npc.loreOrigin.isNotEmpty) {
        topicSet.add(npc.loreOrigin);
      }
      if (npc.culturalArchetype.isNotEmpty) {
        topicSet.add(npc.culturalArchetype);
      }
    }

    final List<String> rawList = topicSet.where((t) => t.trim().isNotEmpty).toList();
    if (rawList.length > 6) {
      return rawList.sublist(0, 6);
    }
    return rawList;
  }
}
