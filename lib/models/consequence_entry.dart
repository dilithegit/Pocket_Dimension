import 'package:meta/meta.dart';

/// Level of public awareness or narrative spread of a consequence.
enum ConsequenceSpreadLevel {
  secret,
  rumored,
  known,
  legendary,
}

/// Operational state of a consequence entry in the World Memory.
enum ConsequenceStatus {
  dormant,
  brewing,
  active,
  resolved,
}

/// Represents an entry in the World Memory / Consequence Web.
@immutable
class ConsequenceEntry {
  final String id;
  final String summary;
  final List<String> involvedNpcIds;
  final String location;
  final int originTurn;
  final ConsequenceSpreadLevel spreadLevel;
  final ConsequenceStatus status;
  final String? triggerHint;

  const ConsequenceEntry({
    required this.id,
    required this.summary,
    this.involvedNpcIds = const [],
    required this.location,
    this.originTurn = 1,
    this.spreadLevel = ConsequenceSpreadLevel.secret,
    this.status = ConsequenceStatus.dormant,
    this.triggerHint,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'summary': summary,
      'involved_npc_ids': involvedNpcIds,
      'location': location,
      'origin_turn': originTurn,
      'spread_level': spreadLevel.name,
      'status': status.name,
      'trigger_hint': triggerHint,
    };
  }

  factory ConsequenceEntry.fromJson(Map<String, dynamic> json) {
    ConsequenceSpreadLevel parseSpread(dynamic raw) {
      if (raw == null) return ConsequenceSpreadLevel.secret;
      return ConsequenceSpreadLevel.values.firstWhere(
        (e) => e.name == raw.toString().toLowerCase(),
        orElse: () => ConsequenceSpreadLevel.secret,
      );
    }

    ConsequenceStatus parseStatus(dynamic raw) {
      if (raw == null) return ConsequenceStatus.dormant;
      return ConsequenceStatus.values.firstWhere(
        (e) => e.name == raw.toString().toLowerCase(),
        orElse: () => ConsequenceStatus.dormant,
      );
    }

    return ConsequenceEntry(
      id: json['id'] as String? ?? 'consequence_${DateTime.now().millisecondsSinceEpoch}',
      summary: json['summary'] as String? ?? '',
      involvedNpcIds: (json['involved_npc_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      location: json['location'] as String? ?? 'Unknown Location',
      originTurn: (json['origin_turn'] as num?)?.toInt() ?? 1,
      spreadLevel: parseSpread(json['spread_level']),
      status: parseStatus(json['status']),
      triggerHint: json['trigger_hint'] as String?,
    );
  }

  ConsequenceEntry copyWith({
    String? id,
    String? summary,
    List<String>? involvedNpcIds,
    String? location,
    int? originTurn,
    ConsequenceSpreadLevel? spreadLevel,
    ConsequenceStatus? status,
    String? triggerHint,
  }) {
    return ConsequenceEntry(
      id: id ?? this.id,
      summary: summary ?? this.summary,
      involvedNpcIds: involvedNpcIds ?? this.involvedNpcIds,
      location: location ?? this.location,
      originTurn: originTurn ?? this.originTurn,
      spreadLevel: spreadLevel ?? this.spreadLevel,
      status: status ?? this.status,
      triggerHint: triggerHint ?? this.triggerHint,
    );
  }
}
