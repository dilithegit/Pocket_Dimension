import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_dimension/models/game_state.dart';
import 'package:pocket_dimension/models/character.dart';
import 'package:pocket_dimension/offline_story/story_graph.dart';
import 'package:pocket_dimension/offline_story/story_node.dart';
import 'package:pocket_dimension/offline_story/story_engine.dart';

void main() {
  const sampleJson = '''
  {
    "storyId": "test_story",
    "title": "Test Story",
    "description": "A test story graph",
    "startNodeId": "node_start",
    "nodes": [
      {
        "id": "node_start",
        "narrationVariants": [
          "Variant 1: Welcome {characterName} of the {origin} to the Shrine.",
          "Variant 2: Welcome back {characterName} to the ancient Shrine."
        ],
        "branches": [
          {
            "label": "Approach Oracle",
            "intentKeywords": ["approach", "oracle", "speak"],
            "targetNodeId": "node_oracle",
            "flagsSet": {"spoke_oracle": true}
          },
          {
            "label": "Inspect Sundial",
            "intentKeywords": ["inspect", "sundial", "sun"],
            "targetNodeId": "node_sundial",
            "flagsSet": {"found_sundial": true}
          }
        ]
      },
      {
        "id": "node_oracle",
        "narrationVariants": [
          "The Pythia speaks in riddle to {characterName}.",
          "fragrant lotus smoke coils as the Pythia looks up."
        ],
        "flagsSetOnEntry": {
          "met_pythia": true
        },
        "consequence": {
          "id": "c_pythia_blessing",
          "summary": "Received Pythia's divine blessing",
          "involvedNpcIds": ["npc_pythia"],
          "location": "Sanctuary",
          "originTurn": 1,
          "spreadLevel": "localized",
          "status": "active",
          "triggerHint": "The Pythia revealed ancient omens"
        },
        "branches": [
          {
            "label": "Return to Start",
            "intentKeywords": ["return", "back", "start"],
            "targetNodeId": "node_start",
            "flagsSet": {}
          }
        ]
      },
      {
        "id": "node_sundial",
        "narrationVariants": [
          "The bronze sundial casts a shadow on Nok ciphers."
        ],
        "branches": []
      }
    ]
  }
  ''';

  final gameState = GameState.initial(
    name: 'Aurelius',
    origin: 'Sun-Blessed Sovereign',
  );

  group('StoryGraph & StoryNode parsing', () {
    test('parses story graph JSON string correctly', () {
      final graph = StoryGraph.fromJsonString(sampleJson);
      expect(graph.storyId, equals('test_story'));
      expect(graph.startNodeId, equals('node_start'));
      expect(graph.nodes.length, equals(3));

      final startNode = graph.getNode('node_start');
      expect(startNode, isNotNull);
      expect(startNode!.narrationVariants.length, equals(2));
      expect(startNode.branches.length, equals(2));
    });
  });

  group('StoryEngine Turn Execution & Matching', () {
    late StoryEngine engine;

    setUp(() {
      final graph = StoryGraph.fromJsonString(sampleJson);
      engine = StoryEngine(graph: graph);
    });

    test('processTurn handles initial turn and placeholder substitution', () {
      final result = engine.processTurn(state: gameState, playerInput: '');
      expect(result.currentNodeId, equals('node_start'));
      expect(result.delta.narration, contains('Aurelius'));
      expect(result.delta.narration, contains('Sun-Blessed Sovereign'));
    });

    test('matchIntent scores branches and transitions nodes correctly', () {
      final result = engine.processTurn(
        state: gameState,
        playerInput: 'I want to speak with the oracle',
      );

      expect(result.matchedIntent, isTrue);
      expect(result.currentNodeId, equals('node_oracle'));
      expect(engine.activeFlags['spoke_oracle'], isTrue);
      expect(engine.activeFlags['met_pythia'], isTrue);
      expect(result.delta.consequenceUpdates.length, equals(1));
      expect(result.delta.consequenceUpdates.first.id, equals('c_pythia_blessing'));
    });

    test('intent match failure surfaces fallback suggested actions', () {
      final result = engine.processTurn(
        state: gameState,
        playerInput: 'unrelated random input string',
      );

      expect(result.matchedIntent, isFalse);
      expect(result.suggestedActions, contains('Approach Oracle'));
      expect(result.suggestedActions, contains('Inspect Sundial'));
    });

    test('consecutive visits to the same node alternate narration variants', () {
      // First turn at node_start
      final res1 = engine.processTurn(state: gameState, playerInput: '');
      final text1 = res1.delta.narration;

      // Move to node_oracle
      engine.processTurn(state: gameState, playerInput: 'approach oracle');

      // Move back to node_start
      final res2 = engine.processTurn(state: gameState, playerInput: 'return back to start');
      final text2 = res2.delta.narration;

      expect(text1, contains('Variant 1'));
      expect(text2, contains('Variant 2'));
      expect(text1, isNot(equals(text2)));
    });
  });
}
