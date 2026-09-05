import '../models/game_state.dart';
import '../models/state_delta.dart';
import '../models/consequence_entry.dart';
import 'story_graph.dart';
import 'story_node.dart';

/// Result returned after processing a turn in the offline story engine.
class StoryTurnResult {
  final StateDelta delta;
  final List<String> suggestedActions;
  final String currentNodeId;
  final bool matchedIntent;

  const StoryTurnResult({
    required this.delta,
    this.suggestedActions = const [],
    required this.currentNodeId,
    required this.matchedIntent,
  });
}

/// Offline StoryEngine — Pure local, zero-network story engine driven by JSON story graphs.
class StoryEngine {
  final StoryGraph graph;
  String _currentNodeId;
  final Map<String, int> _nodeVisitCounts = {};
  final Map<String, int> _lastVariantIndices = {};
  final Map<String, dynamic> _activeFlags = {};
  final Set<String> _emittedConsequenceIds = {};

  StoryEngine({
    required this.graph,
    String? startNodeId,
  }) : _currentNodeId = startNodeId ?? graph.startNodeId;

  String get currentNodeId => _currentNodeId;
  Map<String, int> get nodeVisitCounts => Map.unmodifiable(_nodeVisitCounts);
  Map<String, dynamic> get activeFlags => Map.unmodifiable(_activeFlags);

  /// Resets engine to start node or specified node.
  void reset([String? nodeId]) {
    _currentNodeId = nodeId ?? graph.startNodeId;
    _nodeVisitCounts.clear();
    _lastVariantIndices.clear();
    _activeFlags.clear();
    _emittedConsequenceIds.clear();
  }

  /// Score available branches against player input based on keyword overlap.
  StoryBranch? matchIntent(String playerInput, List<StoryBranch> branches) {
    if (playerInput.trim().isEmpty || branches.isEmpty) return null;

    final String inputClean = playerInput.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
    final List<String> inputTokens =
        inputClean.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

    StoryBranch? bestBranch;
    int maxScore = 0;

    for (final branch in branches) {
      int score = 0;
      for (final rawKeyword in branch.intentKeywords) {
        final String keywordClean =
            rawKeyword.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
        if (keywordClean.isEmpty) continue;

        if (inputClean.contains(keywordClean)) {
          score += 3;
        } else {
          final List<String> kwTokens =
              keywordClean.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
          for (final kwToken in kwTokens) {
            if (inputTokens.contains(kwToken)) {
              score += 1;
            }
          }
        }
      }

      if (score > maxScore) {
        maxScore = score;
        bestBranch = branch;
      }
    }

    return maxScore >= 1 ? bestBranch : null;
  }

  /// Process a single turn of player input against the story graph.
  StoryTurnResult processTurn({
    required GameState state,
    required String playerInput,
  }) {
    if (_currentNodeId.isEmpty) {
      _currentNodeId = graph.startNodeId;
    }

    StoryNode? currentNode = graph.getNode(_currentNodeId);
    if (currentNode == null) {
      _currentNodeId = graph.startNodeId;
      currentNode = graph.getNode(_currentNodeId);
    }

    bool matchedIntent = false;
    List<String> suggestedActions = [];

    // Attempt intent matching against current node's available branches
    if (currentNode != null && playerInput.trim().isNotEmpty) {
      final matchedBranch = matchIntent(playerInput, currentNode.branches);
      if (matchedBranch != null) {
        matchedIntent = true;
        _activeFlags.addAll(matchedBranch.flagsSet);
        _currentNodeId = matchedBranch.targetNodeId;
        currentNode = graph.getNode(_currentNodeId) ?? currentNode;
      } else {
        // Fallback: intent match failed to clear threshold
        suggestedActions = currentNode.branches.map((b) => b.label).toList();
      }
    }

    if (currentNode == null) {
      return StoryTurnResult(
        delta: const StateDelta(narration: 'The mists fade into silence.'),
        currentNodeId: _currentNodeId,
        matchedIntent: false,
      );
    }

    // Apply node entry flags
    _activeFlags.addAll(currentNode.flagsSetOnEntry);

    // Track node visit count
    _nodeVisitCounts[currentNode.id] = (_nodeVisitCounts[currentNode.id] ?? 0) + 1;

    // Rotate narration variant to guarantee no two consecutive visits share identical text
    final rawNarration = _selectNarrationVariant(currentNode);
    final narration = _substitutePlaceholders(rawNarration, state);

    // Prepare consequence entry if present
    List<ConsequenceEntry> consequenceUpdates = [];
    final cEntry = _buildConsequence(currentNode);
    if (cEntry != null) {
      consequenceUpdates.add(cEntry);
    }

    final delta = StateDelta(
      narration: narration,
      flagsSet: Map<String, dynamic>.from(_activeFlags),
      consequenceUpdates: consequenceUpdates,
      locationChange: currentNode.id,
    );

    return StoryTurnResult(
      delta: delta,
      suggestedActions: suggestedActions,
      currentNodeId: _currentNodeId,
      matchedIntent: matchedIntent,
    );
  }

  String _selectNarrationVariant(StoryNode node) {
    if (node.narrationVariants.isEmpty) {
      return 'You stand at ${node.id}. The air is still.';
    }

    int prevIdx = _lastVariantIndices[node.id] ?? -1;
    int nextIdx = (prevIdx + 1) % node.narrationVariants.length;
    _lastVariantIndices[node.id] = nextIdx;
    return node.narrationVariants[nextIdx];
  }

  String _substitutePlaceholders(String text, GameState state) {
    String result = text;
    result = result.replaceAll('{characterName}', state.character.name);
    result = result.replaceAll('{origin}', state.character.origin);
    result = result.replaceAll('{location}', state.world.currentLocation);
    _activeFlags.forEach((key, value) {
      result = result.replaceAll('{$key}', value.toString());
    });
    return result;
  }

  ConsequenceEntry? _buildConsequence(StoryNode node) {
    if (node.consequence == null) return null;
    final Map<String, dynamic> cMap = node.consequence!;
    final String id = cMap['id'] as String? ?? 'c_${node.id}';
    if (_emittedConsequenceIds.contains(id)) return null;

    _emittedConsequenceIds.add(id);
    return ConsequenceEntry.fromJson(cMap);
  }
}
