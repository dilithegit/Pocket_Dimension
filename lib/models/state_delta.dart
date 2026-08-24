import 'package:meta/meta.dart';
import 'character.dart';
import 'consequence_entry.dart';
import 'world.dart';
import 'json_helpers.dart';

/// Represents validated state deltas proposed by the AI DM Engine.
@immutable
class StateDelta {
  final String narration;
  final Map<String, dynamic> flagsSet;
  final List<ConsequenceEntry> consequenceUpdates;
  final List<NpcRelationship> npcUpdates;
  final List<String> inventoryAdd;
  final List<String> inventoryRemove;
  final String? locationChange;

  const StateDelta({
    required this.narration,
    this.flagsSet = const {},
    this.consequenceUpdates = const [],
    this.npcUpdates = const [],
    this.inventoryAdd = const [],
    this.inventoryRemove = const [],
    this.locationChange,
  });

  factory StateDelta.fromJson(Map<String, dynamic> json) {
    String narration = json['narration'] as String? ?? 'The world turns silently.';
    Map<String, dynamic> rawDelta = json['state_delta'] is Map
        ? asStringKeyedMap(json['state_delta'])
        : (json['delta'] is Map ? asStringKeyedMap(json['delta']) : json);

    Map<String, dynamic> flags = rawDelta['flags_set'] is Map
        ? asStringKeyedMap(rawDelta['flags_set'])
        : const {};

    List<ConsequenceEntry> consequences = [];
    if (rawDelta['consequence_updates'] is List) {
      for (var item in (rawDelta['consequence_updates'] as List)) {
        if (item is Map) {
          consequences.add(ConsequenceEntry.fromJson(asStringKeyedMap(item)));
        }
      }
    }

    List<NpcRelationship> npcs = [];
    if (rawDelta['npc_updates'] is List) {
      for (var item in (rawDelta['npc_updates'] as List)) {
        if (item is Map) {
          final itemMap = asStringKeyedMap(item);
          String id = itemMap['id'] as String? ?? 'npc_${DateTime.now().millisecondsSinceEpoch}';
          npcs.add(NpcRelationship.fromJson(id, itemMap));
        }
      }
    }

    List<String> invAdd = [];
    if (rawDelta['inventory_add'] is List) {
      for (var item in (rawDelta['inventory_add'] as List)) {
        if (item is Map) {
          final m = asStringKeyedMap(item);
          String name = (m['name'] ?? m['id'] ?? '').toString();
          if (name.isNotEmpty) invAdd.add(name);
        } else if (item != null) {
          invAdd.add(item.toString());
        }
      }
    }

    List<String> invRem = [];
    if (rawDelta['inventory_remove'] is List) {
      for (var item in (rawDelta['inventory_remove'] as List)) {
        if (item is Map) {
          final m = asStringKeyedMap(item);
          String name = (m['name'] ?? m['id'] ?? '').toString();
          if (name.isNotEmpty) invRem.add(name);
        } else if (item != null) {
          invRem.add(item.toString());
        }
      }
    }

    String? loc = rawDelta['location_change'] as String?;

    return StateDelta(
      narration: narration,
      flagsSet: flags,
      consequenceUpdates: consequences,
      npcUpdates: npcs,
      inventoryAdd: invAdd,
      inventoryRemove: invRem,
      locationChange: loc,
    );
  }
}
