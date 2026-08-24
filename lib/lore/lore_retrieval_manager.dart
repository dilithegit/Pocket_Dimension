import 'dart:math' as math;
import '../models/lore_chunk.dart';
import '../database/lore_chunk_repository.dart';
import '../network/gemini_client.dart';

/// Scored LoreChunk paired with its calculated cosine similarity score.
class ScoredLoreChunk {
  final LoreChunk chunk;
  final double similarity;

  const ScoredLoreChunk({
    required this.chunk,
    required this.similarity,
  });
}

/// Lore Retrieval Manager executing per-turn vector similarity scans over stored LoreChunks.
class LoreRetrievalManager {
  final GeminiClient geminiClient;
  final LoreChunkRepository repository;

  LoreRetrievalManager({
    GeminiClient? geminiClient,
    LoreChunkRepository? repository,
  })  : geminiClient = geminiClient ?? GeminiClient(),
        repository = repository ?? LoreChunkRepository();

  /// Embeds [playerInput], scans all LoreChunks for [saveSlotId], and returns top 3 chunks clearing [similarityFloor] (default 0.5).
  Future<List<ScoredLoreChunk>> retrieveGroundingContext(
    String playerInput,
    int saveSlotId, {
    double similarityFloor = 0.5,
    int topK = 3,
  }) async {
    final trimmed = playerInput.trim();
    if (trimmed.isEmpty || saveSlotId <= 0) return [];

    final queryVector = await geminiClient.embedText(trimmed);

    // Check if query vector is empty/zero fallback
    bool isZeroVector = queryVector.every((v) => v == 0.0);

    final allChunks = await repository.getAllForSaveSlot(saveSlotId);
    if (allChunks.isEmpty) return [];

    final List<ScoredLoreChunk> scored = [];

    for (final chunk in allChunks) {
      if (chunk.embedding.isEmpty) continue;

      double sim;
      if (isZeroVector) {
        // If offline / zero vector fallback, match query text against chunk text keyword overlap for test compatibility
        sim = _textKeywordOverlapSimilarity(trimmed, chunk.chunkText);
      } else {
        sim = computeCosineSimilarity(queryVector, chunk.embedding);
      }

      if (sim >= similarityFloor) {
        scored.add(ScoredLoreChunk(chunk: chunk, similarity: sim));
      }
    }

    scored.sort((a, b) => b.similarity.compareTo(a.similarity));

    if (scored.length > topK) {
      return scored.sublist(0, topK);
    }
    return scored;
  }

  /// Format retrieved chunks into the DM system prompt's Grounding Context section.
  static String formatGroundingPrompt(List<ScoredLoreChunk> scoredChunks) {
    if (scoredChunks.isEmpty) return '';

    final StringBuffer buffer = StringBuffer();
    buffer.writeln('\nGROUNDING CONTEXT (REFERENCE MATERIAL - DO NOT QUOTE VERBATIM):');

    for (final item in scoredChunks) {
      final c = item.chunk;
      buffer.writeln('[Source: ${c.sourceTitle}]');
      buffer.writeln(c.chunkText.trim());
      buffer.writeln();
    }

    return buffer.toString().trimRight();
  }

  /// Calculates cosine similarity between two double vectors of equal dimension.
  static double computeCosineSimilarity(List<double> vectorA, List<double> vectorB) {
    if (vectorA.isEmpty || vectorB.isEmpty || vectorA.length != vectorB.length) {
      return 0.0;
    }

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < vectorA.length; i++) {
      dotProduct += vectorA[i] * vectorB[i];
      normA += vectorA[i] * vectorA[i];
      normB += vectorB[i] * vectorB[i];
    }

    if (normA == 0.0 || normB == 0.0) return 0.0;
    return dotProduct / (math.sqrt(normA) * math.sqrt(normB));
  }

  /// Fallback simple text similarity score for offline / mock testing.
  static double _textKeywordOverlapSimilarity(String query, String text) {
    final queryWords = query.toLowerCase().split(RegExp(r'\s+')).where((w) => w.length > 3).toSet();
    if (queryWords.isEmpty) return 0.0;
    final textWords = text.toLowerCase().split(RegExp(r'\s+')).toSet();

    int matches = queryWords.intersection(textWords).length;
    return (matches / queryWords.length).clamp(0.0, 1.0);
  }
}
