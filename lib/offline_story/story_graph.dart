import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'story_node.dart';

/// StoryGraph — Encapsulates an entire authored storyline asset.
class StoryGraph {
  final String storyId;
  final String title;
  final String description;
  final String startNodeId;
  final Map<String, StoryNode> nodes;

  const StoryGraph({
    required this.storyId,
    required this.title,
    required this.description,
    required this.startNodeId,
    required this.nodes,
  });

  factory StoryGraph.fromJson(Map<String, dynamic> json) {
    final nodesList = (json['nodes'] as List<dynamic>?) ?? [];
    final Map<String, StoryNode> nodeMap = {};

    for (final item in nodesList) {
      if (item is Map<String, dynamic>) {
        final node = StoryNode.fromJson(item);
        nodeMap[node.id] = node;
      }
    }

    return StoryGraph(
      storyId: json['storyId'] as String? ?? 'unknown_story',
      title: json['title'] as String? ?? 'Authored Story',
      description: json['description'] as String? ?? '',
      startNodeId: json['startNodeId'] as String? ?? '',
      nodes: nodeMap,
    );
  }

  factory StoryGraph.fromJsonString(String jsonStr) {
    final Map<String, dynamic> decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
    return StoryGraph.fromJson(decoded);
  }

  StoryNode? getNode(String id) => nodes[id];
}

/// Utility for loading story graphs from Flutter app assets.
class StoryGraphLoader {
  static Future<StoryGraph> loadFromAsset(String assetPath) async {
    final jsonStr = await rootBundle.loadString(assetPath);
    return StoryGraph.fromJsonString(jsonStr);
  }
}
