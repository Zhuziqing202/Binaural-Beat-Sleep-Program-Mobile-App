class AppSettings {
  final double targetSleepHours;
  final String targetWakeTime;
  final bool enableSleepReminder;
  final bool enableWakeReminder;
  final bool enableWeeklyReport;

  AppSettings({
    required this.targetSleepHours,
    required this.targetWakeTime,
    this.enableSleepReminder = true,
    this.enableWakeReminder = true,
    this.enableWeeklyReport = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'targetSleepHours': targetSleepHours,
      'targetWakeTime': targetWakeTime,
      'enableSleepReminder': enableSleepReminder,
      'enableWakeReminder': enableWakeReminder,
      'enableWeeklyReport': enableWeeklyReport,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      targetSleepHours: map['targetSleepHours'] as double,
      targetWakeTime: map['targetWakeTime'] as String,
      enableSleepReminder: map['enableSleepReminder'] as bool,
      enableWakeReminder: map['enableWakeReminder'] as bool,
      enableWeeklyReport: map['enableWeeklyReport'] as bool,
    );
  }

  factory AppSettings.defaultSettings() {
    return AppSettings(
      targetSleepHours: 8.0,
      targetWakeTime: '06:30',
    );
  }
} 