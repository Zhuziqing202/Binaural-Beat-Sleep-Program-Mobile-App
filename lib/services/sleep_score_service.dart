import 'package:flutter/material.dart';

class SleepScoreService {
  static const int TOTAL_SCORE = 100;
  static const int DURATION_WEIGHT = 40;
  static const int BEDTIME_WEIGHT = 40;
  static const int EFFICIENCY_WEIGHT = 20;

  // 计算睡眠总评分
  static double calculateSleepScore({
    required DateTime sleepStart,
    required DateTime sleepEnd,
    required double efficiency,
  }) {
    final durationScore = _calculateDurationScore(sleepStart, sleepEnd);
    final bedtimeScore = _calculateBedtimeScore(sleepStart);
    final efficiencyScore = _calculateEfficiencyScore(efficiency);

    return durationScore + bedtimeScore + efficiencyScore;
  }

  // 计算睡眠时长得分 (40分)
  static double _calculateDurationScore(
      DateTime sleepStart, DateTime sleepEnd) {
    final Duration sleepDuration = sleepEnd.difference(sleepStart);
    final double hours = sleepDuration.inMinutes / 60.0;

    // 睡眠时长评分规则:
    // < 4小时: 0-10分
    // 4-6小时: 10-20分
    // 6-7小时: 20-30分
    // 7-9小时: 30-40分
    // > 9小时: 25-35分 (过长睡眠也不够健康)

    if (hours < 4) {
      return (hours / 4) * 10;
    } else if (hours < 6) {
      return 10 + ((hours - 4) / 2) * 10;
    } else if (hours < 7) {
      return 20 + (hours - 6) * 10;
    } else if (hours <= 9) {
      return 30 + ((hours - 7) / 2) * 10;
    } else {
      return 35 - ((hours - 9) / 2) * 10;
    }
  }

  // 计算入睡时间得分 (40分)
  static double _calculateBedtimeScore(DateTime sleepStart) {
    final int hour = sleepStart.hour;
    final int minute = sleepStart.minute;
    final double timeInHours = hour + (minute / 60.0);

    // 入睡时间评分规则:
    // 21:00-22:00: 35-40分
    // 22:00-23:00: 30-35分
    // 23:00-00:00: 25-30分
    // 00:00-02:00: 15-25分
    // 02:00-04:00: 5-15分
    // 04:00-06:00: 0-5分
    // 其他时间: 相应递减

    if (timeInHours >= 21 && timeInHours < 22) {
      return 35 + ((22 - timeInHours) * 5);
    } else if (timeInHours >= 22 && timeInHours < 23) {
      return 30 + ((23 - timeInHours) * 5);
    } else if (timeInHours >= 23 && timeInHours < 24) {
      return 25 + ((24 - timeInHours) * 5);
    } else if (timeInHours >= 0 && timeInHours < 2) {
      return 25 - (timeInHours * 5);
    } else if (timeInHours >= 2 && timeInHours < 4) {
      return 15 - ((timeInHours - 2) * 5);
    } else if (timeInHours >= 4 && timeInHours < 6) {
      return 5 - ((timeInHours - 4) * 2.5);
    } else {
      return 0;
    }
  }

  // 计算睡眠效率得分 (20分)
  static double _calculateEfficiencyScore(double efficiency) {
    // 睡眠效率评分规则:
    // 90-100%: 16-20分
    // 80-90%: 12-16分
    // 70-80%: 8-12分
    // 60-70%: 4-8分
    // <60%: 0-4分

    if (efficiency >= 0.9) {
      return 16 + ((efficiency - 0.9) * 40);
    } else if (efficiency >= 0.8) {
      return 12 + ((efficiency - 0.8) * 40);
    } else if (efficiency >= 0.7) {
      return 8 + ((efficiency - 0.7) * 40);
    } else if (efficiency >= 0.6) {
      return 4 + ((efficiency - 0.6) * 40);
    } else {
      return efficiency * 6.67; // 0-4分
    }
  }

  // 获取评分等级
  static String getScoreGrade(double score) {
    if (score >= 90) {
      return 'S';
    } else if (score >= 80) {
      return 'A';
    } else if (score >= 70) {
      return 'B';
    } else if (score >= 60) {
      return 'C';
    } else {
      return 'D';
    }
  }

  // 获取评分建议
  static String getScoreSuggestion(double score) {
    if (score >= 90) {
      return '完美的睡眠！继续保持这样的作息习惯。';
    } else if (score >= 80) {
      return '不错的睡眠质量，建议保持规律的作息时间。';
    } else if (score >= 70) {
      return '睡眠质量尚可，可以考虑调整入睡时间来提升质量。';
    } else if (score >= 60) {
      return '睡眠质量一般，建议增加睡眠时长并保持规律作息。';
    } else {
      return '睡眠质量需要改善，建议避免熬夜并保证充足的睡眠时间。';
    }
  }
}
