import 'package:meta/meta.dart';

/// Item stored in the character's inventory.
@immutable
class InventoryItem {
  final String id;
  final String name;
  final int qty;

  const InventoryItem({
    required this.id,
    required this.name,
    this.qty = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'qty': qty,
    };
  }

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      qty: (json['qty'] as num?)?.toInt() ?? 1,
    );
  }

  InventoryItem copyWith({
    String? id,
    String? name,
    int? qty,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      qty: qty ?? this.qty,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InventoryItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          qty == other.qty;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ qty.hashCode;
}

/// Character model strictly following Schema Version 2 (game_state_schema.md).
/// The player possesses God-Mode omnipotence; HP, Mana, and traditional failure
/// metrics are deliberately omitted.
@immutable
class Character {
  final String name;
  final String origin;
  final List<InventoryItem> inventory;

  const Character({
    required this.name,
    required this.origin,
    this.inventory = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'origin': origin,
      'inventory': inventory.map((item) => item.toJson()).toList(),
    };
  }

  factory Character.fromJson(Map<String, dynamic> json) {
    var rawInventory = json['inventory'] as List<dynamic>? ?? [];
    List<InventoryItem> parsedInventory = rawInventory
        .map((item) => InventoryItem.fromJson(item as Map<String, dynamic>))
        .toList();

    return Character(
      name: json['name'] as String? ?? 'Nameless Deity',
      origin: json['origin'] as String? ?? 'Unmapped Guise',
      inventory: parsedInventory,
    );
  }

  Character copyWith({
    String? name,
    String? origin,
    List<InventoryItem>? inventory,
  }) {
    return Character(
      name: name ?? this.name,
      origin: origin ?? this.origin,
      inventory: inventory ?? this.inventory,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Character &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          origin == other.origin;

  @override
  int get hashCode => name.hashCode ^ origin.hashCode;
}
