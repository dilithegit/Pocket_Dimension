import 'package:flutter/foundation.dart';

/// StoryBranch — Represents a single directional choice from a StoryNode.
@immutable
class StoryBranch {
  final String label;
  final List<String> intentKeywords;
  final String targetNodeId;
  final Map<String, dynamic> flagsSet;

  const StoryBranch({
    required this.label,
    required this.intentKeywords,
    required this.targetNodeId,
    this.flagsSet = const {},
  });

  factory StoryBranch.fromJson(Map<String, dynamic> json) {
    return StoryBranch(
      label: json['label'] as String? ?? 'Proceed',
      intentKeywords: (json['intentKeywords'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      targetNodeId: json['targetNodeId'] as String? ?? '',
      flagsSet: (json['flagsSet'] as Map<String, dynamic>?) ?? const {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'intentKeywords': intentKeywords,
      'targetNodeId': targetNodeId,
      'flagsSet': flagsSet,
    };
  }
}

/// StoryNode — Represents a scene or location within an authored story graph.
@immutable
class StoryNode {
  final String id;
  final List<String> narrationVariants;
  final List<StoryBranch> branches;
  final Map<String, dynamic> flagsSetOnEntry;
  final Map<String, dynamic>? requiredFlags;
  final Map<String, dynamic>? consequence;

  const StoryNode({
    required this.id,
    required this.narrationVariants,
    this.branches = const [],
    this.flagsSetOnEntry = const {},
    this.requiredFlags,
    this.consequence,
  });

  factory StoryNode.fromJson(Map<String, dynamic> json) {
    return StoryNode(
      id: json['id'] as String? ?? '',
      narrationVariants: (json['narrationVariants'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      branches: (json['branches'] as List<dynamic>?)
              ?.map((e) => StoryBranch.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      flagsSetOnEntry: (json['flagsSetOnEntry'] as Map<String, dynamic>?) ?? const {},
      requiredFlags: json['requiredFlags'] as Map<String, dynamic>?,
      consequence: json['consequence'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'narrationVariants': narrationVariants,
      'branches': branches.map((b) => b.toJson()).toList(),
      'flagsSetOnEntry': flagsSetOnEntry,
      if (requiredFlags != null) 'requiredFlags': requiredFlags,
      if (consequence != null) 'consequence': consequence,
    };
  }
}
