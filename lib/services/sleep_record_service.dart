import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sleep_record.dart';

class SleepRecordService {
  static const String _storageKey = 'sleep_records';
  static final SleepRecordService instance = SleepRecordService._init();

  SleepRecordService._init();

  // 保存睡眠记录
  Future<void> saveSleepRecord(SleepRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await getAllRecords();
    records.add(record);
    
    final jsonList = records.map((r) => r.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  // 获取所有记录
  Future<List<SleepRecord>> getAllRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null) return [];

    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((json) => SleepRecord.fromJson(json)).toList();
  }

  // 获取指定日期范围内的记录
  Future<Map<String, Duration>> getRecordsInRange(DateTime start, DateTime end, String groupBy) async {
    final records = await getAllRecords();
    final Map<String, Duration> durations = {};

    // 根据不同的统计周期创建键
    String getKey(DateTime date) {
      switch (groupBy) {
        case 'day':
          return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        case 'month':
          return '${date.year}-${date.month.toString().padLeft(2, '0')}';
        case 'year':
          return date.year.toString();
        default:
          return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      }
    }

    // 创建日期范围内的所有键
    for (var date = start; date.isBefore(end) || date.isAtSameMomentAs(end);) {
      final key = getKey(date);
      durations[key] = Duration.zero;
      
      switch (groupBy) {
        case 'day':
          date = date.add(const Duration(days: 1));
          break;
        case 'month':
          date = DateTime(date.year, date.month + 1, 1);
          break;
        case 'year':
          date = DateTime(date.year + 1, 1, 1);
          break;
        default:
          date = date.add(const Duration(days: 1));
      }
    }

    // 统计时长
    for (var record in records) {
      final key = getKey(record.startTime); // 使用开始时间的日期作为键
      if (durations.containsKey(key)) {
        durations[key] = durations[key]! + record.duration;
      }
    }

    return durations;
  }

  // 获取最近n天的记录
  Future<Map<String, Duration>> getRecentRecords(int days, String groupBy) async {
    final end = DateTime.now();
    final start = end.subtract(Duration(days: days - 1));
    
    // 获取所有记录
    final records = await getAllRecords();
    
    // 创建日期范围内的所有日期键
    final Map<String, Duration> durations = {};
    for (var date = start; date.isBefore(end) || date.isAtSameMomentAs(end); date = date.add(const Duration(days: 1))) {
      final key = SleepRecord.getDateString(date);
      durations[key] = Duration.zero;
    }

    // 遍历记录，填充数据
    for (var record in records) {
      final recordDate = record.date;
      if (durations.containsKey(recordDate)) {
        durations[recordDate] = record.duration;
      }
    }

    return durations;
  }

  // 清除所有记录
  Future<void> clearAllRecords() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
} 