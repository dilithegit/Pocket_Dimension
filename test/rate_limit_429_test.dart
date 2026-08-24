import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pocket_dimension/network/gemini_client.dart';
import 'package:pocket_dimension/models/game_state.dart';
import 'package:pocket_dimension/models/character.dart';

void main() {
  group('HTTP 429 Rate Limit Handling & Retry Tests', () {
    setUp(() {
      GeminiClient.resetRateLimitCounter();
    });

    test('parseRetryDelaySeconds extracts delay from error message or defaults to 15s', () {
      expect(GeminiClient.parseRetryDelaySeconds('Resource exhausted. Please retry in 12 seconds.'), equals(12));
      expect(GeminiClient.parseRetryDelaySeconds('Quota limit reached. Please retry in 5.5 sec.'), equals(6));
      expect(GeminiClient.parseRetryDelaySeconds('Unknown error message without retry hint.'), equals(15));
    });

    test('processTurn retries on 429 up to maxRetries with backoff and falls back when exhausted', () async {
      int requestCount = 0;
      final recordedDelays = <Duration>[];

      final mockClient = MockClient((request) async {
        requestCount++;
        return http.Response(
          jsonEncode({
            'error': {
              'code': 429,
              'message': 'Resource exhausted. Please retry in 10 seconds.',
              'status': 'RESOURCE_EXHAUSTED'
            }
          }),
          429,
        );
      });

      final client = GeminiClient(
        apiKey: 'test_key',
        httpClient: mockClient,
        delayHandler: (duration) async {
          recordedDelays.add(duration);
        },
      );

      final state = GameState.initial(name: 'TestGod', origin: 'Cosmic');
      final textDeltas = <String>[];

      final delta = await client.processTurn(
        state: state,
        playerInput: 'I summon stars',
        onTextDelta: (deltaText) => textDeltas.add(deltaText),
      );

      // 3 total attempts (attempt 0, attempt 1, attempt 2)
      expect(requestCount, equals(3));
      expect(GeminiClient.rateLimit429Count, equals(3));

      // 2 delays between the 3 attempts: 10s then 20s (exponential backoff)
      expect(recordedDelays.length, equals(2));
      expect(recordedDelays[0], equals(const Duration(seconds: 10)));
      expect(recordedDelays[1], equals(const Duration(seconds: 20)));

      // In-app waiting message surfaced via text delta
      expect(textDeltas.any((t) => t.contains('The threads of fate are tangled')), isTrue);

      // Exhausted retries fell back safely
      expect(delta.narration, isNotEmpty);
    });

    test('generateWorldBible retries on 429 and falls back to procedural world', () async {
      int requestCount = 0;
      final recordedDelays = <Duration>[];

      final mockClient = MockClient((request) async {
        requestCount++;
        return http.Response(
          jsonEncode({
            'error': {
              'code': 429,
              'message': 'Rate limit hit. Retry in 5 sec.',
              'status': 'RESOURCE_EXHAUSTED'
            }
          }),
          429,
        );
      });

      final client = GeminiClient(
        apiKey: 'test_key',
        httpClient: mockClient,
        delayHandler: (duration) async {
          recordedDelays.add(duration);
        },
      );

      final world = await client.generateWorldBible(worldConceptPrompt: 'Eldritch Cyberpunk');

      expect(requestCount, equals(3));
      expect(recordedDelays.length, equals(2));
      expect(recordedDelays[0], equals(const Duration(seconds: 5)));
      expect(recordedDelays[1], equals(const Duration(seconds: 10)));

      // Offline procedural fallback generated safely
      expect(world.currentLocation, isNotEmpty);
      expect(world.npcRelationships, isNotEmpty);
    });
  });
}
