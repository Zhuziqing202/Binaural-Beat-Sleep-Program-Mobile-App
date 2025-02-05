class DreamRecord {
  final String id;
  final DateTime date;
  final String title;
  final String content;
  final int mood; // 情绪值 -100 到 100
  final int clarity; // 清晰度 1-5

  DreamRecord({
    required this.id,
    required this.date,
    required this.title,
    required this.content,
    required this.mood,
    required this.clarity,
  });

  factory DreamRecord.fromJson(Map<String, dynamic> json) {
    return DreamRecord(
      id: json['id'],
      date: DateTime.parse(json['date']),
      title: json['title'],
      content: json['content'],
      mood: json['mood'],
      clarity: json['clarity'] is String ? int.parse(json['clarity']) : json['clarity'],
    );
  }

  // 为数据库操作添加 fromMap 方法
  factory DreamRecord.fromMap(Map<String, dynamic> map) => DreamRecord.fromJson(map);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'title': title,
      'content': content,
      'mood': mood,
      'clarity': clarity,
    };
  }

  // 为数据库操作添加 toMap 方法
  Map<String, dynamic> toMap() => toJson();
} 