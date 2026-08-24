import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_dimension/network/gemini_client.dart';
import 'package:pocket_dimension/models/world.dart';

void main() {
  test('Diagnose WorldWeaver generateWorldBible 3 consecutive Reweave calls', () async {
    final client = GeminiClient();
    const concept = 'African high fantasy';

    for (int i = 1; i <= 3; i++) {
      debugPrint('\n======================================================');
      debugPrint('=== [REWEAVE CALL #$i] Concept: "$concept" ===');
      final world = await client.generateWorldBible(worldConceptPrompt: concept);
      debugPrint('Location #$i: ${world.currentLocation}');
      debugPrint('NPCs #$i: ${world.npcRelationships.values.map((n) => "${n.name} (${n.culturalArchetype})").toList()}');
      debugPrint('======================================================\n');
    }
  }, timeout: const Timeout(Duration(minutes: 3)));
}
