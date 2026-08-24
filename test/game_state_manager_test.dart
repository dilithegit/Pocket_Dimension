import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_dimension/models/character.dart';
import 'package:pocket_dimension/models/world.dart';
import 'package:pocket_dimension/models/game_state.dart';
import 'package:pocket_dimension/models/state_delta.dart';
import 'package:pocket_dimension/state/game_state_manager.dart';

void main() {
  group('Schema Version 2 & God-Mode Character Model Tests', () {
    test('Character model contains name, origin, inventory and no HP/Mana', () {
      const char = Character(
        name: 'The Unbound Architect',
        origin: 'Starlight Weaver',
        inventory: [InventoryItem(id: 'item_1', name: 'Aether Prism', qty: 1)],
      );

      final jsonMap = char.toJson();

      expect(jsonMap['name'], equals('The Unbound Architect'));
      expect(jsonMap['origin'], equals('Starlight Weaver'));
      expect(jsonMap.containsKey('hp'), isFalse);
      expect(jsonMap.containsKey('mana'), isFalse);
      expect(jsonMap.containsKey('level'), isFalse);

      final deserialized = Character.fromJson(jsonMap);
      expect(deserialized.name, equals('The Unbound Architect'));
      expect(deserialized.inventory.length, equals(1));
    });

    test('GameState canonical serialization follows Schema Version 2 shape', () {
      final state = GameState.initial(
        name: 'Omnipotent Weaver',
        origin: 'Celestial Entity',
        startingLocation: 'Solar Throne',
      );

      final jsonMap = state.toJson();

      expect(jsonMap['schema_version'], equals(2));
      expect(jsonMap['character']['name'], equals('Omnipotent Weaver'));
      expect(jsonMap['world']['current_location'], equals('Solar Throne'));
      expect(jsonMap['narrative_memory']['recent_turns'], isA<List>());

      final reloadedState = GameState.fromJson(jsonMap);
      expect(reloadedState.schemaVersion, equals(2));
      expect(reloadedState.character.name, equals('Omnipotent Weaver'));
    });
  });

  group('Deep-Lore NPC Generation Model Tests', () {
    test('NpcRelationship includes cultural archetype and lore origin', () {
      const npc = NpcRelationship(
        id: 'npc_1',
        name: 'Tariq the Oasis Scholar',
        role: 'Astronomer of the Sun Guild',
        loreOrigin: 'Sahelian Star-Lore',
        culturalArchetype: 'Celestial Astrologer',
        personalityTags: ['analytical', 'cautious'],
        goal: 'Map the unseen constellations',
        trust: 10,
        disposition: 'friendly',
      );

      final jsonMap = npc.toJson();

      expect(jsonMap['lore_origin'], equals('Sahelian Star-Lore'));
      expect(jsonMap['cultural_archetype'], equals('Celestial Astrologer'));

      final parsed = NpcRelationship.fromJson('npc_1', jsonMap);
      expect(parsed.loreOrigin, equals('Sahelian Star-Lore'));
      expect(parsed.culturalArchetype, equals('Celestial Astrologer'));
    });
  });

  group('GameStateManager Mutation & Notification Tests', () {
    late GameStateManager manager;

    setUp(() {
      manager = GameStateManager(
        initialState: GameState.initial(
          name: 'The Omnipotent',
          origin: 'Void Guise',
          startingLocation: 'Old Empire Ruins',
        ),
      );
    });

    test('applyDelta correctly updates flags, suspicion, deep-lore NPCs, and inventory', () {
      bool listenerNotified = false;
      manager.addListener(() {
        listenerNotified = true;
      });

      final delta = StateDelta.fromJson({
        'narration': 'The sky cracks open with golden lightning.',
        'state_delta': {
          'flags_set': {'sky_cracked': true},
          'suspicion_increase': {
            'region_name': 'Old Empire Ruins',
            'heat_increase': 20,
            'new_rumor': 'Gods walk the ruins.'
          },
          'npc_updates': [
            {
              'id': 'npc_guard',
              'name': 'Captain Amina',
              'role': 'Empire Citadel Guard',
              'lore_origin': 'Coastal Fortress Guardians',
              'cultural_archetype': 'Veteran Defender',
              'personality_tags': ['stern', 'vigilant'],
              'goal': 'Protect the citadel',
              'trust': -5,
              'disposition': 'wary',
              'known_facts': ['Saw the sky turn gold.']
            }
          ],
          'inventory_add': [
            {'id': 'item_divine_orb', 'name': 'Orb of Dawn', 'qty': 1}
          ],
        }
      });

      manager.applyDelta(delta, playerInput: 'I rend the sky open');

      expect(listenerNotified, isTrue);
      expect(manager.state.world.flags['sky_cracked'], isTrue);

      final suspicion = manager.state.world.regionalSuspicion['Old Empire Ruins'];
      expect(suspicion?.heatLevel, equals(20));
      expect(suspicion?.rumors, contains('Gods walk the ruins.'));

      expect(manager.state.world.npcRelationships.containsKey('npc_guard'), isTrue);
      final npc = manager.state.world.npcRelationships['npc_guard'];
      expect(npc?.loreOrigin, equals('Coastal Fortress Guardians'));
      expect(npc?.culturalArchetype, equals('Veteran Defender'));

      expect(manager.state.character.inventory.length, equals(1));
      expect(manager.state.character.inventory.first.name, equals('Orb of Dawn'));
    });

    test('shouldSummarize returns true when recent turns reach 10', () {
      expect(manager.shouldSummarize(), isFalse);

      for (int i = 0; i < 5; i++) {
        final delta = StateDelta.fromJson({
          'narration': 'Exchange $i',
        });
        manager.applyDelta(delta, playerInput: 'Input $i');
      }

      // 5 turns = 10 messages (Player: Input X, DM: Exchange X)
      expect(manager.state.narrativeMemory.recentTurns.length, equals(10));
      expect(manager.shouldSummarize(), isTrue);
    });

    test('setOfflineMode toggles offline engine status reactively', () {
      expect(manager.isOfflineMode, isFalse);

      bool notified = false;
      manager.addListener(() => notified = true);

      manager.setOfflineMode(true);
      expect(manager.isOfflineMode, isTrue);
      expect(notified, isTrue);
    });

    test('malformed or fallback StateDelta applies safely without state corruption', () {
      final initialLocation = manager.state.world.currentLocation;
      const fallbackMsg = 'The mists of reality swirl, clouding your vision. Try again.';

      final delta = StateDelta.fromJson({'invalid_field': 12345});
      manager.applyDelta(delta, playerInput: 'Trigger invalid parse');

      expect(manager.state.world.currentLocation, equals(initialLocation));
      expect(manager.state.narrativeMemory.recentTurns.last, contains('The world turns silently.'));

      const errorDelta = StateDelta(narration: fallbackMsg);
      manager.applyDelta(errorDelta);
      expect(manager.state.narrativeMemory.recentTurns.last, contains(fallbackMsg));
    });
  });
}
