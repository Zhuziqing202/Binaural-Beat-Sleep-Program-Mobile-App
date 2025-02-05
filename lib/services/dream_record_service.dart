import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dream_record.dart';

class DreamRecordService {
  static const String _storageKey = 'dream_records';
  static final DreamRecordService instance = DreamRecordService._init();

  DreamRecordService._init();

  // 保存梦境记录
  Future<void> saveDreamRecord(DreamRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await getAllRecords();
    
    // 查找是否存在相同ID的记录
    final index = records.indexWhere((r) => r.id == record.id);
    if (index != -1) {
      // 更新现有记录
      records[index] = record;
    } else {
      // 添加新记录
      records.add(record);
    }
    
    final jsonList = records.map((r) => r.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  // 获取所有记录
  Future<List<DreamRecord>> getAllRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null) return [];

    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((json) => DreamRecord.fromJson(json)).toList();
  }

  // 获取指定记录
  Future<DreamRecord?> getRecord(String id) async {
    final records = await getAllRecords();
    try {
      return records.firstWhere((record) => record.id == id);
    } catch (e) {
      return null;
    }
  }

  // 删除记录
  Future<void> deleteRecord(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await getAllRecords();
    records.removeWhere((record) => record.id == id);
    
    final jsonList = records.map((r) => r.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  // 清除所有记录
  Future<void> clearAllRecords() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
} 