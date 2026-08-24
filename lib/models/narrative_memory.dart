import 'package:meta/meta.dart';

/// Narrative memory tracking recent raw exchange turns and a compressed rolling summary.
@immutable
class NarrativeMemory {
  final List<String> recentTurns;
  final String rollingSummary;

  const NarrativeMemory({
    this.recentTurns = const [],
    this.rollingSummary = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'recent_turns': recentTurns,
      'rolling_summary': rollingSummary,
    };
  }

  factory NarrativeMemory.fromJson(Map<String, dynamic> json) {
    List<String> turns = (json['recent_turns'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [];
    String summary = json['rolling_summary'] as String? ?? '';

    return NarrativeMemory(
      recentTurns: turns,
      rollingSummary: summary,
    );
  }

  NarrativeMemory copyWith({
    List<String>? recentTurns,
    String? rollingSummary,
  }) {
    return NarrativeMemory(
      recentTurns: recentTurns ?? this.recentTurns,
      rollingSummary: rollingSummary ?? this.rollingSummary,
    );
  }
}
