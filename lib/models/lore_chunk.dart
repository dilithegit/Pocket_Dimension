import 'dart:convert';
import 'package:meta/meta.dart';

/// Represents a single ingested lore text chunk with its vector embedding.
@immutable
class LoreChunk {
  final String id;
  final int saveSlotId;
  final String sourceTitle;
  final String sourceUrl;
  final String chunkText;
  final List<double> embedding;
  final int createdTurn;

  const LoreChunk({
    required this.id,
    required this.saveSlotId,
    required this.sourceTitle,
    required this.sourceUrl,
    required this.chunkText,
    required this.embedding,
    this.createdTurn = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'save_slot_id': saveSlotId,
      'source_title': sourceTitle,
      'source_url': sourceUrl,
      'chunk_text': chunkText,
      'embedding': jsonEncode(embedding),
      'created_turn': createdTurn,
    };
  }

  factory LoreChunk.fromMap(Map<String, dynamic> map) {
    List<double> parsedEmbedding = [];
    if (map['embedding'] is String) {
      final decoded = jsonDecode(map['embedding'] as String);
      if (decoded is List) {
        parsedEmbedding = decoded.map((e) => (e as num).toDouble()).toList();
      }
    } else if (map['embedding'] is List) {
      parsedEmbedding = (map['embedding'] as List).map((e) => (e as num).toDouble()).toList();
    }

    return LoreChunk(
      id: map['id'] as String? ?? 'chunk_${DateTime.now().millisecondsSinceEpoch}',
      saveSlotId: (map['save_slot_id'] as num?)?.toInt() ?? 0,
      sourceTitle: map['source_title'] as String? ?? '',
      sourceUrl: map['source_url'] as String? ?? '',
      chunkText: map['chunk_text'] as String? ?? '',
      embedding: parsedEmbedding,
      createdTurn: (map['created_turn'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory LoreChunk.fromJson(Map<String, dynamic> json) => LoreChunk.fromMap(json);

  LoreChunk copyWith({
    String? id,
    int? saveSlotId,
    String? sourceTitle,
    String? sourceUrl,
    String? chunkText,
    List<double>? embedding,
    int? createdTurn,
  }) {
    return LoreChunk(
      id: id ?? this.id,
      saveSlotId: saveSlotId ?? this.saveSlotId,
      sourceTitle: sourceTitle ?? this.sourceTitle,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      chunkText: chunkText ?? this.chunkText,
      embedding: embedding ?? this.embedding,
      createdTurn: createdTurn ?? this.createdTurn,
    );
  }
}
