import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// SQLite Database Helper managing initialization and schema creation.
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String dbPath = await getDatabasesPath();
    String path = join(dbPath, 'pocket_dimension.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  FutureOr<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE save_slots (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        slot_name TEXT NOT NULL,
        last_played INTEGER NOT NULL,
        current_location TEXT NOT NULL,
        schema_version INTEGER NOT NULL,
        state_json TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE lore_chunks (
        id TEXT PRIMARY KEY,
        save_slot_id INTEGER NOT NULL,
        source_title TEXT NOT NULL,
        source_url TEXT NOT NULL,
        chunk_text TEXT NOT NULL,
        embedding TEXT NOT NULL,
        created_turn INTEGER NOT NULL
      )
    ''');
  }

  FutureOr<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS lore_chunks (
          id TEXT PRIMARY KEY,
          save_slot_id INTEGER NOT NULL,
          source_title TEXT NOT NULL,
          source_url TEXT NOT NULL,
          chunk_text TEXT NOT NULL,
          embedding TEXT NOT NULL,
          created_turn INTEGER NOT NULL
        )
      ''');
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
