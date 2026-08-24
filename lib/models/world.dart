import 'package:meta/meta.dart';
import 'consequence_entry.dart';

/// NpcRelationship model accommodating Deep-Lore NPC Generation.
/// Holds lore origin anchors, cultural archetypes, independent goals, and memory of player actions.
@immutable
class NpcRelationship {
  final String id;
  final String name;
  final String role;
  final String loreOrigin;
  final String culturalArchetype;
  final List<String> personalityTags;
  final String goal;
  final String? secret;
  final int trust;
  final String disposition;
  final List<String> knownFacts;
  final int lastSeenTurn;

  const NpcRelationship({
    required this.id,
    required this.name,
    this.role = 'Local Inhabitant',
    this.loreOrigin = 'World Folk',
    this.culturalArchetype = 'Resident',
    this.personalityTags = const [],
    this.goal = 'Survive and prosper',
    this.secret,
    this.trust = 0,
    this.disposition = 'neutral',
    this.knownFacts = const [],
    this.lastSeenTurn = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'lore_origin': loreOrigin,
      'cultural_archetype': culturalArchetype,
      'personality_tags': personalityTags,
      'goal': goal,
      'secret': secret,
      'trust': trust,
      'disposition': disposition,
      'known_facts': knownFacts,
      'last_seen_turn': lastSeenTurn,
    };
  }

  factory NpcRelationship.fromJson(String npcId, Map<String, dynamic> json) {
    return NpcRelationship(
      id: json['id'] as String? ?? npcId,
      name: json['name'] as String? ?? 'Unknown Stranger',
      role: json['role'] as String? ?? 'Wanderer',
      loreOrigin: json['lore_origin'] as String? ?? 'Regional Folk',
      culturalArchetype: json['cultural_archetype'] as String? ?? 'Local',
      personalityTags: (json['personality_tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      goal: json['goal'] as String? ?? 'Seeking opportunity',
      secret: json['secret'] as String?,
      trust: (json['trust'] as num?)?.toInt() ?? 0,
      disposition: json['disposition'] as String? ?? 'neutral',
      knownFacts: (json['known_facts'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      lastSeenTurn: (json['last_seen_turn'] as num?)?.toInt() ?? 0,
    );
  }

  NpcRelationship copyWith({
    String? id,
    String? name,
    String? role,
    String? loreOrigin,
    String? culturalArchetype,
    List<String>? personalityTags,
    String? goal,
    String? secret,
    int? trust,
    String? disposition,
    List<String>? knownFacts,
    int? lastSeenTurn,
  }) {
    return NpcRelationship(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      loreOrigin: loreOrigin ?? this.loreOrigin,
      culturalArchetype: culturalArchetype ?? this.culturalArchetype,
      personalityTags: personalityTags ?? this.personalityTags,
      goal: goal ?? this.goal,
      secret: secret ?? this.secret,
      trust: trust ?? this.trust,
      disposition: disposition ?? this.disposition,
      knownFacts: knownFacts ?? this.knownFacts,
      lastSeenTurn: lastSeenTurn ?? this.lastSeenTurn,
    );
  }
}

/// WorldData model holding world state, Consequence Web, flags, and living NPCs.
@immutable
class WorldData {
  final String currentLocation;
  final List<ConsequenceEntry> consequenceWeb;
  final Map<String, dynamic> flags;
  final Map<String, NpcRelationship> npcRelationships;

  const WorldData({
    required this.currentLocation,
    this.consequenceWeb = const [],
    this.flags = const {},
    this.npcRelationships = const {},
  });

  Map<String, dynamic> toJson() {
    Map<String, dynamic> npcJson = {};
    npcRelationships.forEach((key, value) {
      npcJson[key] = value.toJson();
    });

    return {
      'current_location': currentLocation,
      'consequence_web': consequenceWeb.map((e) => e.toJson()).toList(),
      'flags': flags,
      'npc_relationships': npcJson,
    };
  }

  factory WorldData.fromJson(Map<String, dynamic> json) {
    String location = json['current_location'] as String? ?? 'Unknown Realm';

    List<ConsequenceEntry> parsedConsequences = [];
    if (json['consequence_web'] is List) {
      parsedConsequences = (json['consequence_web'] as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map((e) => ConsequenceEntry.fromJson(e))
          .toList();
    }

    Map<String, dynamic> parsedFlags = {};
    if (json['flags'] is Map) {
      parsedFlags = Map<String, dynamic>.from(json['flags'] as Map);
    }

    Map<String, NpcRelationship> parsedNpcs = {};
    if (json['npc_relationships'] is Map) {
      (json['npc_relationships'] as Map<String, dynamic>).forEach((k, v) {
        if (v is Map<String, dynamic>) {
          parsedNpcs[k] = NpcRelationship.fromJson(k, v);
        }
      });
    }

    return WorldData(
      currentLocation: location,
      consequenceWeb: parsedConsequences,
      flags: parsedFlags,
      npcRelationships: parsedNpcs,
    );
  }

  WorldData copyWith({
    String? currentLocation,
    List<ConsequenceEntry>? consequenceWeb,
    Map<String, dynamic>? flags,
    Map<String, NpcRelationship>? npcRelationships,
  }) {
    return WorldData(
      currentLocation: currentLocation ?? this.currentLocation,
      consequenceWeb: consequenceWeb ?? this.consequenceWeb,
      flags: flags ?? this.flags,
      npcRelationships: npcRelationships ?? this.npcRelationships,
    );
  }
}
