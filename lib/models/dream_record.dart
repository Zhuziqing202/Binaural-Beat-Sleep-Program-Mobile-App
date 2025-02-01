class DreamRecord {
  final int? id;
  final String title;
  final String content;
  final String type;
  final String mood;
  final List<String> tags;
  final DateTime recordTime;
  final double sleepQuality;

  DreamRecord({
    this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.mood,
    required this.tags,
    required this.recordTime,
    required this.sleepQuality,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'type': type,
      'mood': mood,
      'tags': tags.join(','),
      'recordTime': recordTime.toIso8601String(),
      'sleepQuality': sleepQuality,
    };
  }

  factory DreamRecord.fromMap(Map<String, dynamic> map) {
    return DreamRecord(
      id: map['id'] as int?,
      title: map['title'] as String,
      content: map['content'] as String,
      type: map['type'] as String,
      mood: map['mood'] as String,
      tags: (map['tags'] as String).split(','),
      recordTime: DateTime.parse(map['recordTime'] as String),
      sleepQuality: map['sleepQuality'] as double,
    );
  }
} 