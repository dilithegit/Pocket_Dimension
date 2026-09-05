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

    Map<String, dynamic> flags = (rawDelta['flags_set'] ?? rawDelta['flagsSet']) is Map
        ? asStringKeyedMap(rawDelta['flags_set'] ?? rawDelta['flagsSet'])
        : const {};

    List<ConsequenceEntry> consequences = [];
    final rawConsequences = rawDelta['consequence_updates'] ?? rawDelta['consequenceUpdates'];
    if (rawConsequences is List) {
      for (var item in rawConsequences) {
        if (item is Map) {
          consequences.add(ConsequenceEntry.fromJson(asStringKeyedMap(item)));
        }
      }
    }

    List<NpcRelationship> npcs = [];
    final rawNpcs = rawDelta['npc_updates'] ?? rawDelta['npcUpdates'];
    if (rawNpcs is List) {
      for (var item in rawNpcs) {
        if (item is Map) {
          final itemMap = asStringKeyedMap(item);
          String id = itemMap['id'] as String? ?? 'npc_${DateTime.now().millisecondsSinceEpoch}';
          npcs.add(NpcRelationship.fromJson(id, itemMap));
        }
      }
    }

    List<String> invAdd = [];
    final rawInvAdd = rawDelta['inventory_add'] ?? rawDelta['inventoryAdd'];
    if (rawInvAdd is List) {
      for (var item in rawInvAdd) {
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
    final rawInvRem = rawDelta['inventory_remove'] ?? rawDelta['inventoryRemove'];
    if (rawInvRem is List) {
      for (var item in rawInvRem) {
        if (item is Map) {
          final m = asStringKeyedMap(item);
          String name = (m['name'] ?? m['id'] ?? '').toString();
          if (name.isNotEmpty) invRem.add(name);
        } else if (item != null) {
          invRem.add(item.toString());
        }
      }
    }

    String? loc = (rawDelta['location_change'] ?? rawDelta['locationChange']) as String?;

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
