import 'package:meta/meta.dart';
import 'character.dart';
import 'world.dart';
import 'narrative_memory.dart';

/// Root GameState implementing Schema Version 2 canonical shape.
/// Single source of truth for the player's god-mode game state.
@immutable
class GameState {
  final int schemaVersion;
  final Character character;
  final WorldData world;
  final NarrativeMemory narrativeMemory;

  const GameState({
    this.schemaVersion = 2,
    required this.character,
    required this.world,
    required this.narrativeMemory,
  });

  Map<String, dynamic> toJson() {
    return {
      'schema_version': schemaVersion,
      'character': character.toJson(),
      'world': world.toJson(),
      'narrative_memory': narrativeMemory.toJson(),
    };
  }

  factory GameState.fromJson(Map<String, dynamic> json) {
    int version = (json['schema_version'] as num?)?.toInt() ?? 2;
    Map<String, dynamic> charJson = json['character'] is Map<String, dynamic>
        ? json['character'] as Map<String, dynamic>
        : {};
    Map<String, dynamic> worldJson = json['world'] is Map<String, dynamic>
        ? json['world'] as Map<String, dynamic>
        : {};
    Map<String, dynamic> memoryJson =
        json['narrative_memory'] is Map<String, dynamic>
            ? json['narrative_memory'] as Map<String, dynamic>
            : {};

    return GameState(
      schemaVersion: version,
      character: Character.fromJson(charJson),
      world: WorldData.fromJson(worldJson),
      narrativeMemory: NarrativeMemory.fromJson(memoryJson),
    );
  }

  /// Helper factory for fresh game creation.
  factory GameState.initial({
    required String name,
    required String origin,
    String startingLocation = 'Nexus of Worlds',
  }) {
    return GameState(
      schemaVersion: 2,
      character: Character(
        name: name,
        origin: origin,
        inventory: const [],
      ),
      world: WorldData(
        currentLocation: startingLocation,
        regionalSuspicion: {
          startingLocation: const RegionalSuspicion(heatLevel: 0, rumors: []),
        },
        flags: const {},
        npcRelationships: const {},
      ),
      narrativeMemory: const NarrativeMemory(
        recentTurns: [],
        rollingSummary: 'The journey begins as an omnipotent entity walks among mortals in secret.',
      ),
    );
  }

  GameState copyWith({
    int? schemaVersion,
    Character? character,
    WorldData? world,
    NarrativeMemory? narrativeMemory,
  }) {
    return GameState(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      character: character ?? this.character,
      world: world ?? this.world,
      narrativeMemory: narrativeMemory ?? this.narrativeMemory,
    );
  }
}
