import 'package:meta/meta.dart';
import 'character.dart';
import 'consequence_entry.dart';
import 'world.dart';

/// Represents validated state deltas proposed by the AI DM Engine.
@immutable
class StateDelta {
  final String narration;
  final Map<String, dynamic> flagsSet;
  final List<ConsequenceEntry> consequenceUpdates;
  final List<NpcRelationship> npcUpdates;
  final List<InventoryItem> inventoryAdd;
  final List<InventoryItem> inventoryRemove;
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
    Map<String, dynamic> rawDelta = json['state_delta'] is Map<String, dynamic>
        ? json['state_delta'] as Map<String, dynamic>
        : (json['delta'] is Map<String, dynamic> ? json['delta'] as Map<String, dynamic> : json);

    Map<String, dynamic> flags = rawDelta['flags_set'] is Map
        ? Map<String, dynamic>.from(rawDelta['flags_set'] as Map)
        : const {};

    List<ConsequenceEntry> consequences = [];
    if (rawDelta['consequence_updates'] is List) {
      for (var item in (rawDelta['consequence_updates'] as List)) {
        if (item is Map<String, dynamic>) {
          consequences.add(ConsequenceEntry.fromJson(item));
        }
      }
    }

    List<NpcRelationship> npcs = [];
    if (rawDelta['npc_updates'] is List) {
      for (var item in (rawDelta['npc_updates'] as List)) {
        if (item is Map<String, dynamic>) {
          String id = item['id'] as String? ?? 'npc_${DateTime.now().millisecondsSinceEpoch}';
          npcs.add(NpcRelationship.fromJson(id, item));
        }
      }
    }

    List<InventoryItem> invAdd = [];
    if (rawDelta['inventory_add'] is List) {
      for (var item in (rawDelta['inventory_add'] as List)) {
        if (item is Map<String, dynamic>) {
          invAdd.add(InventoryItem.fromJson(item));
        }
      }
    }

    List<InventoryItem> invRem = [];
    if (rawDelta['inventory_remove'] is List) {
      for (var item in (rawDelta['inventory_remove'] as List)) {
        if (item is Map<String, dynamic>) {
          invRem.add(InventoryItem.fromJson(item));
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
