class AppSettings {
  final double targetSleepHours;
  final String targetSleepTime;
  final String targetWakeTime;
  final bool enableSleepReminder;
  final bool enableWakeReminder;
  final bool enableWeeklyReport;
  final bool enableHealthSync;

  AppSettings({
    required this.targetSleepHours,
    required this.targetSleepTime,
    required this.targetWakeTime,
    required this.enableSleepReminder,
    required this.enableWakeReminder,
    required this.enableWeeklyReport,
    required this.enableHealthSync,
  });

  Map<String, dynamic> toMap() {
    return {
      'targetSleepHours': targetSleepHours,
      'targetSleepTime': targetSleepTime,
      'targetWakeTime': targetWakeTime,
      'enableSleepReminder': enableSleepReminder,
      'enableWakeReminder': enableWakeReminder,
      'enableWeeklyReport': enableWeeklyReport,
      'enableHealthSync': enableHealthSync,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      targetSleepHours: map['targetSleepHours'] as double,
      targetSleepTime: map['targetSleepTime'] as String,
      targetWakeTime: map['targetWakeTime'] as String,
      enableSleepReminder: map['enableSleepReminder'] as bool,
      enableWakeReminder: map['enableWakeReminder'] as bool,
      enableWeeklyReport: map['enableWeeklyReport'] as bool,
      enableHealthSync: map['enableHealthSync'] as bool,
    );
  }

  factory AppSettings.defaultSettings() {
    return AppSettings(
      targetSleepHours: 8.0,
      targetSleepTime: '22:30',
      targetWakeTime: '06:30',
      enableSleepReminder: true,
      enableWakeReminder: true,
      enableWeeklyReport: true,
      enableHealthSync: true,
    );
  }
} 