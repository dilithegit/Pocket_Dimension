import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_dimension/models/character.dart';
import 'package:pocket_dimension/models/consequence_entry.dart';
import 'package:pocket_dimension/models/world.dart';
import 'package:pocket_dimension/models/game_state.dart';
import 'package:pocket_dimension/models/state_delta.dart';
import 'package:pocket_dimension/network/gemini_client.dart';
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

  group('ConsequenceEntry & Web Model Tests', () {
    test('ConsequenceEntry serializes enums and fields correctly', () {
      const entry = ConsequenceEntry(
        id: 'c_starfire_1',
        summary: 'Starfire revealed in the grand market plaza',
        involvedNpcIds: ['npc_1', 'npc_2'],
        location: 'Sun-Spire Citadel',
        originTurn: 1,
        spreadLevel: ConsequenceSpreadLevel.rumored,
        status: ConsequenceStatus.brewing,
        triggerHint: 'Mortals are whispering about unchanneled magic',
      );

      final jsonMap = entry.toJson();
      expect(jsonMap['spread_level'], equals('rumored'));
      expect(jsonMap['status'], equals('brewing'));

      final parsed = ConsequenceEntry.fromJson(jsonMap);
      expect(parsed.id, equals('c_starfire_1'));
      expect(parsed.spreadLevel, equals(ConsequenceSpreadLevel.rumored));
      expect(parsed.status, equals(ConsequenceStatus.brewing));
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

    test('applyDelta correctly merges valid consequenceUpdates, deep-lore NPCs, and inventory', () {
      bool listenerNotified = false;
      manager.addListener(() {
        listenerNotified = true;
      });

      final delta = StateDelta.fromJson({
        'narration': 'The sky cracks open with golden lightning.',
        'state_delta': {
          'flags_set': {'sky_cracked': true},
          'consequence_updates': [
            {
              'id': 'c_sky_cracked',
              'summary': 'Sky cracked open with golden lightning above ruins',
              'involved_npc_ids': ['npc_guard'],
              'location': 'Old Empire Ruins',
              'origin_turn': 1,
              'spread_level': 'rumored',
              'status': 'brewing',
              'trigger_hint': 'Guards are investigating the sky rupture'
            }
          ],
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

      expect(manager.state.world.consequenceWeb.length, equals(1));
      final consequence = manager.state.world.consequenceWeb.first;
      expect(consequence.summary, contains('Sky cracked open'));
      expect(consequence.spreadLevel, equals(ConsequenceSpreadLevel.rumored));
      expect(consequence.status, equals(ConsequenceStatus.brewing));

      expect(manager.state.world.npcRelationships.containsKey('npc_guard'), isTrue);
      final npc = manager.state.world.npcRelationships['npc_guard'];
      expect(npc?.loreOrigin, equals('Coastal Fortress Guardians'));
      expect(npc?.culturalArchetype, equals('Veteran Defender'));

      expect(manager.state.character.inventory.length, equals(1));
      expect(manager.state.character.inventory.first.name, equals('Orb of Dawn'));
    });

    test('consequenceUpdates drops empty summary and clamps extra new entries to 2 per turn', () {
      final delta = StateDelta.fromJson({
        'narration': 'Multiple rumors ignite.',
        'state_delta': {
          'consequence_updates': [
            {'id': 'c_1', 'summary': '', 'status': 'brewing'}, // Empty summary: dropped
            {'id': 'c_2', 'summary': 'Summary 2', 'status': 'dormant'},
            {'id': 'c_3', 'summary': 'Summary 3', 'status': 'dormant'},
            {'id': 'c_4', 'summary': 'Summary 4', 'status': 'dormant'}, // Exceeds 2 new: clamped
          ]
        }
      });

      manager.applyDelta(delta);

      final web = manager.state.world.consequenceWeb;
      expect(web.length, equals(2));
      expect(web.map((e) => e.id), containsAll(['c_2', 'c_3']));
      expect(web.map((e) => e.id), isNot(contains('c_1')));
      expect(web.map((e) => e.id), isNot(contains('c_4')));
    });

    test('consequenceUpdates clamps multi-step status and spreadLevel jumps to single step', () {
      // Step 1: Add initial dormant/secret entry
      final initialDelta = StateDelta.fromJson({
        'narration': 'Initial whisper.',
        'state_delta': {
          'consequence_updates': [
            {
              'id': 'c_jump',
              'summary': 'A secret myth begins',
              'spread_level': 'secret', // index 0
              'status': 'dormant', // index 0
            }
          ]
        }
      });
      manager.applyDelta(initialDelta);

      // Step 2: Proposed jump dormant (0) -> active (2) and secret (0) -> legendary (3)
      final jumpDelta = StateDelta.fromJson({
        'narration': 'A wild leap in awareness.',
        'state_delta': {
          'consequence_updates': [
            {
              'id': 'c_jump',
              'summary': 'A secret myth begins',
              'spread_level': 'legendary', // jump index 0 -> 3
              'status': 'active', // jump index 0 -> 2
            }
          ]
        }
      });
      manager.applyDelta(jumpDelta);

      final entry = manager.state.world.consequenceWeb.firstWhere((e) => e.id == 'c_jump');
      // Should be clamped to 1 step forward: dormant (0) -> brewing (1), secret (0) -> rumored (1)
      expect(entry.status, equals(ConsequenceStatus.brewing));
      expect(entry.spreadLevel, equals(ConsequenceSpreadLevel.rumored));
    });

    test('npcUpdates drops new NPC if loreOrigin or culturalArchetype is missing', () {
      final delta = StateDelta.fromJson({
        'narration': 'A mysterious stranger appears.',
        'state_delta': {
          'npc_updates': [
            {
              'id': 'npc_generic',
              'name': 'Bob the Blacksmith',
              'lore_origin': '', // Empty: violates lore requirement for new NPC
              'cultural_archetype': 'Generic Blacksmith',
            }
          ]
        }
      });

      manager.applyDelta(delta);

      expect(manager.state.world.npcRelationships.containsKey('npc_generic'), isFalse);
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

  group('GeminiClient Prompt & Payload Tests', () {
    test('processTurn offline fallback generates valid consequenceUpdates', () async {
      final client = GeminiClient(apiKey: '');
      final state = GameState.initial(
        name: 'Omnipotent Weaver',
        origin: 'Starlight Deity',
        startingLocation: 'Sun-Spire Citadel',
      );

      final delta = await client.processTurn(state: state, playerInput: 'I summon starfire');

      expect(delta.narration, contains('summon starfire'));
      expect(delta.consequenceUpdates.isNotEmpty, isTrue);
      expect(delta.consequenceUpdates.first.summary, contains('Subtle ether currents'));
      expect(delta.consequenceUpdates.first.spreadLevel, equals(ConsequenceSpreadLevel.secret));
      expect(delta.consequenceUpdates.first.status, equals(ConsequenceStatus.dormant));
    });
  });
}
