import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/dream_record.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('dreams.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE dreams(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        mood INTEGER NOT NULL,
        clarity INTEGER NOT NULL,
        date TEXT NOT NULL
      )
    ''');
  }

  Future<DreamRecord> createDream(DreamRecord dream) async {
    final db = await instance.database;
    await db.insert('dreams', dream.toMap());
    return dream;
  }

  Future<DreamRecord?> readDream(String id) async {
    final db = await instance.database;
    final maps = await db.query(
      'dreams',
      columns: ['id', 'title', 'content', 'mood', 'clarity', 'date'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return DreamRecord.fromMap(maps.first);
    }
    return null;
  }

  Future<List<DreamRecord>> readAllDreams() async {
    final db = await instance.database;
    final result = await db.query('dreams', orderBy: 'date DESC');
    return result.map((json) => DreamRecord.fromMap(json)).toList();
  }

  Future<int> updateDream(DreamRecord dream) async {
    final db = await instance.database;
    return db.update(
      'dreams',
      dream.toMap(),
      where: 'id = ?',
      whereArgs: [dream.id],
    );
  }

  Future<int> deleteDream(String id) async {
    final db = await instance.database;
    return await db.delete(
      'dreams',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
} 