class SleepRecord {
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;
  final String date; // 用于分组统计，格式：yyyy-MM-dd
  final Map<String, int> stageDurations; // 各阶段时长（秒）
  final double sleepEfficiency; // 睡眠效率 0-1

  SleepRecord({
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.date,
    required this.stageDurations,
    required this.sleepEfficiency,
  });

  // 从JSON转换为对象
  factory SleepRecord.fromJson(Map<String, dynamic> json) {
    return SleepRecord(
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      duration: Duration(milliseconds: json['duration']),
      date: json['date'],
      stageDurations: Map<String, int>.from(json['stageDurations'] ?? {}),
      sleepEfficiency: json['sleepEfficiency'] ?? 0.0,
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'duration': duration.inMilliseconds,
      'date': date,
      'stageDurations': stageDurations,
      'sleepEfficiency': sleepEfficiency,
    };
  }

  // 判断记录是否属于同一天
  static String getDateString(DateTime time) {
    // 如果时间在凌晨0点到中午12点之间，算作前一天的睡眠
    if (time.hour < 12) {
      time = time.subtract(const Duration(days: 1));
    }
    return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}';
  }
} 