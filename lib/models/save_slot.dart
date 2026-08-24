import 'dart:convert';
import 'package:meta/meta.dart';
import 'game_state.dart';
import 'json_helpers.dart';

/// Database entity representing a Save Slot record in SQLite.
@immutable
class SaveSlot {
  final int? id;
  final String slotName;
  final DateTime lastPlayed;
  final String currentLocation;
  final int schemaVersion;
  final String stateJson;

  const SaveSlot({
    this.id,
    required this.slotName,
    required this.lastPlayed,
    required this.currentLocation,
    required this.schemaVersion,
    required this.stateJson,
  });

  /// Factory helper to build a SaveSlot from a GameState object.
  factory SaveSlot.fromGameState({
    int? id,
    required String slotName,
    required GameState state,
  }) {
    return SaveSlot(
      id: id,
      slotName: slotName,
      lastPlayed: DateTime.now(),
      currentLocation: state.world.currentLocation,
      schemaVersion: state.schemaVersion,
      stateJson: jsonEncode(state.toJson()),
    );
  }

  /// Parses the stored raw JSON string back into a GameState instance.
  GameState toGameState() {
    Map<String, dynamic> parsed = asStringKeyedMap(jsonDecode(stateJson));
    return GameState.fromJson(parsed);
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'slot_name': slotName,
      'last_played': lastPlayed.millisecondsSinceEpoch,
      'current_location': currentLocation,
      'schema_version': schemaVersion,
      'state_json': stateJson,
    };
  }

  factory SaveSlot.fromMap(Map<String, dynamic> map) {
    return SaveSlot(
      id: map['id'] as int?,
      slotName: map['slot_name'] as String? ?? 'Untitled Save',
      lastPlayed: DateTime.fromMillisecondsSinceEpoch(
        map['last_played'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
      currentLocation: map['current_location'] as String? ?? 'Unknown Location',
      schemaVersion: map['schema_version'] as int? ?? 2,
      stateJson: map['state_json'] as String? ?? '{}',
    );
  }

  SaveSlot copyWith({
    int? id,
    String? slotName,
    DateTime? lastPlayed,
    String? currentLocation,
    int? schemaVersion,
    String? stateJson,
  }) {
    return SaveSlot(
      id: id ?? this.id,
      slotName: slotName ?? this.slotName,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      currentLocation: currentLocation ?? this.currentLocation,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      stateJson: stateJson ?? this.stateJson,
    );
  }
}
