import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_dimension/models/json_helpers.dart';
import 'package:pocket_dimension/models/world.dart';

void main() {
  group('JSON Helpers & Type-Cast Safety Tests', () {
    test('asStringKeyedMap converts dynamic-keyed maps safely', () {
      final rawDynamicMap = <dynamic, dynamic>{
        'key1': 'val1',
        123: 'val2',
        'key3': <dynamic, dynamic>{'nested': 'val3'},
      };

      final safeMap = asStringKeyedMap(rawDynamicMap);
      expect(safeMap, isA<Map<String, dynamic>>());
      expect(safeMap['key1'], equals('val1'));
      expect(safeMap['123'], equals('val2'));
      expect(safeMap['key3'], isA<Map<dynamic, dynamic>>());
    });

    test('WorldData.fromJson parses nested _Map<dynamic, Map<String, dynamic>> without subtype cast crash', () {
      // Constructs the exact untyped nested map structure that previously caused the cast exception
      final Map<dynamic, dynamic> rawWorldMap = {
        'current_location': 'Gbara-Kuru',
        'consequence_web': <dynamic>[
          {
            'id': 'c_1',
            'summary': 'Ancestral rumor',
            'involved_npc_ids': ['npc_1'],
            'location': 'Gbara-Kuru',
            'origin_turn': 0,
            'spread_level': 'secret',
            'status': 'dormant',
            'trigger_hint': 'Ether shift'
          }
        ],
        'flags': <dynamic, dynamic>{
          'world_concept': 'African High Fantasy',
        },
        'npc_relationships': {
          for (var i = 1; i <= 2; i++)
            'npc_$i': <String, dynamic>{
              'id': 'npc_$i',
              'name': 'Griot $i',
              'role': 'Chronicler',
              'lore_origin': 'Sahelian Oral Tradition',
              'cultural_archetype': 'Elder Memory Keeper',
              'personality_tags': ['shrewd'],
              'goal': 'Record sacred truth',
              'secret': 'Carries sunstone',
              'trust': 1,
              'disposition': 'neutral',
              'known_facts': ['Observed shift'],
              'last_seen_turn': 0,
            }
        }
      };

      // Before fix: This threw "_Map<dynamic, Map<String, dynamic>> is not a subtype of Map<String, dynamic>"
      // After fix: Parses cleanly without exception
      final safeWorldMap = asStringKeyedMap(rawWorldMap);
      final world = WorldData.fromJson(safeWorldMap);

      expect(world.currentLocation, equals('Gbara-Kuru'));
      expect(world.npcRelationships.length, equals(2));
      expect(world.npcRelationships['npc_1']!.name, equals('Griot 1'));
    });
  });
}
