import 'package:sqflite/sqflite.dart';
import '../models/lore_chunk.dart';
import 'database_helper.dart';

/// Repository handling persistent storage, retrieval, and scan of LoreChunks in SQLite.
class LoreChunkRepository {
  final DatabaseHelper dbHelper;

  LoreChunkRepository({DatabaseHelper? dbHelper})
      : dbHelper = dbHelper ?? DatabaseHelper();

  /// Retrieve all lore chunks for a specific save slot for per-turn vector retrieval scan.
  Future<List<LoreChunk>> getAllForSaveSlot(int saveSlotId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'lore_chunks',
      where: 'save_slot_id = ?',
      whereArgs: [saveSlotId],
      orderBy: 'created_turn ASC',
    );

    return List.generate(maps.length, (i) => LoreChunk.fromMap(maps[i]));
  }

  /// Retrieve a specific lore chunk by ID.
  Future<LoreChunk?> getLoreChunkById(String id) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'lore_chunks',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return LoreChunk.fromMap(maps.first);
  }

  /// Insert a single lore chunk.
  Future<void> insertLoreChunk(LoreChunk chunk) async {
    final db = await dbHelper.database;
    await db.insert(
      'lore_chunks',
      chunk.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Insert a list of lore chunks in a single transaction.
  Future<void> insertLoreChunks(List<LoreChunk> chunks) async {
    if (chunks.isEmpty) return;
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final chunk in chunks) {
        batch.insert(
          'lore_chunks',
          chunk.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// Delete a lore chunk by ID.
  Future<int> deleteLoreChunk(String id) async {
    final db = await dbHelper.database;
    return await db.delete(
      'lore_chunks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete all lore chunks for a save slot.
  Future<int> deleteAllForSaveSlot(int saveSlotId) async {
    final db = await dbHelper.database;
    return await db.delete(
      'lore_chunks',
      where: 'save_slot_id = ?',
      whereArgs: [saveSlotId],
    );
  }
}
