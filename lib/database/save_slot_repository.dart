import 'package:sqflite/sqflite.dart';
import '../models/save_slot.dart';
import 'database_helper.dart';

/// Repository handling persistent storage and retrieval of save slots in SQLite.
class SaveSlotRepository {
  final DatabaseHelper dbHelper;

  SaveSlotRepository({DatabaseHelper? dbHelper})
      : dbHelper = dbHelper ?? DatabaseHelper();

  /// Retrieve all save slots sorted by last played timestamp descending.
  Future<List<SaveSlot>> getAllSaveSlots() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'save_slots',
      orderBy: 'last_played DESC',
    );

    return List.generate(maps.length, (i) => SaveSlot.fromMap(maps[i]));
  }

  /// Retrieve a specific save slot by ID.
  Future<SaveSlot?> getSaveSlotById(int id) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'save_slots',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return SaveSlot.fromMap(maps.first);
  }

  /// Insert a new save slot into SQLite. Returns the generated row ID.
  Future<int> insertSaveSlot(SaveSlot slot) async {
    final db = await dbHelper.database;
    return await db.insert(
      'save_slots',
      slot.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update an existing save slot.
  Future<int> updateSaveSlot(SaveSlot slot) async {
    final db = await dbHelper.database;
    if (slot.id == null) {
      throw ArgumentError('Cannot update save slot without an ID');
    }

    return await db.update(
      'save_slots',
      slot.toMap(),
      where: 'id = ?',
      whereArgs: [slot.id],
    );
  }

  /// Delete a save slot by ID.
  Future<int> deleteSaveSlot(int id) async {
    final db = await dbHelper.database;
    return await db.delete(
      'save_slots',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete all save slots from SQLite.
  Future<int> deleteAllSaveSlots() async {
    final db = await dbHelper.database;
    return await db.delete('save_slots');
  }
}
