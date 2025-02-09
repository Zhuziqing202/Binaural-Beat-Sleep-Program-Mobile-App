import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../models/dream_record.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 1);

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        _database = await _initDB('dreams.db');
        return _database!;
      } catch (e) {
        debugPrint('数据库初始化失败 (尝试 $attempt/$_maxRetries): $e');
        if (attempt == _maxRetries) rethrow;
        await Future.delayed(_retryDelay);
      }
    }

    throw Exception('数据库初始化失败，已达到最大重试次数');
  }

  Future<Database> _initDB(String filePath) async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, filePath);

      // 确保目录存在
      await Directory(dbPath).create(recursive: true);

      return await openDatabase(
        path,
        version: 1,
        onCreate: _createDB,
        onUpgrade: _onUpgrade,
        onDowngrade: onDatabaseDowngradeDelete,
      );
    } catch (e) {
      debugPrint('数据库初始化错误: $e');
      rethrow;
    }
  }

  Future<void> _createDB(Database db, int version) async {
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS dreams(
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          content TEXT NOT NULL,
          mood INTEGER NOT NULL,
          clarity INTEGER NOT NULL,
          date TEXT NOT NULL
        )
      ''');
    } catch (e) {
      debugPrint('创建数据库表失败: $e');
      rethrow;
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 未来版本升级时使用
  }

  Future<DreamRecord> createDream(DreamRecord dream) async {
    try {
      final db = await instance.database;
      await db.insert('dreams', dream.toMap());
      return dream;
    } catch (e) {
      debugPrint('创建梦境记录失败: $e');
      rethrow;
    }
  }

  Future<DreamRecord?> readDream(String id) async {
    try {
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
    } catch (e) {
      debugPrint('读取梦境记录失败: $e');
      rethrow;
    }
  }

  Future<List<DreamRecord>> readAllDreams() async {
    try {
      final db = await instance.database;
      final result = await db.query('dreams', orderBy: 'date DESC');
      return result.map((json) => DreamRecord.fromMap(json)).toList();
    } catch (e) {
      debugPrint('读取所有梦境记录失败: $e');
      rethrow;
    }
  }

  Future<int> updateDream(DreamRecord dream) async {
    try {
      final db = await instance.database;
      return db.update(
        'dreams',
        dream.toMap(),
        where: 'id = ?',
        whereArgs: [dream.id],
      );
    } catch (e) {
      debugPrint('更新梦境记录失败: $e');
      rethrow;
    }
  }

  Future<int> deleteDream(String id) async {
    try {
      final db = await instance.database;
      return await db.delete(
        'dreams',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('删除梦境记录失败: $e');
      rethrow;
    }
  }

  Future<void> close() async {
    try {
      final db = await instance.database;
      await db.close();
      _database = null;
    } catch (e) {
      debugPrint('关闭数据库失败: $e');
      rethrow;
    }
  }
}
