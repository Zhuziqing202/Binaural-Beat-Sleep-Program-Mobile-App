import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

class HealthService {
  static final HealthService instance = HealthService._init();
  final HealthFactory _health = HealthFactory();

  HealthService._init();

  Future<bool> requestPermissions() async {
    // 请求健康数据权限
    final permissionStatus = await Permission.activityRecognition.request();
    if (permissionStatus.isDenied) return false;

    // 请求 HealthKit 权限
    final types = [
      HealthDataType.SLEEP_ASLEEP,
      HealthDataType.SLEEP_AWAKE,
      HealthDataType.SLEEP_IN_BED,
      HealthDataType.HEART_RATE,
      HealthDataType.RESPIRATORY_RATE,
    ];

    final granted = await _health.requestAuthorization(types);
    return granted;
  }

  Future<Map<String, dynamic>> getSleepData(DateTime date) async {
    try {
      final midnight = DateTime(date.year, date.month, date.day);
      final nextMidnight = midnight.add(const Duration(days: 1));

      // 获取睡眠数据
      final sleepData = await _health.getHealthDataFromTypes(
        midnight,
        nextMidnight,
        [
          HealthDataType.SLEEP_ASLEEP,
          HealthDataType.SLEEP_AWAKE,
          HealthDataType.SLEEP_IN_BED,
        ],
      );

      // 计算各项指标
      double totalSleepTime = 0;
      double deepSleepTime = 0;
      double lightSleepTime = 0;
      double awakeTime = 0;

      for (var data in sleepData) {
        final duration = data.dateTo.difference(data.dateFrom).inMinutes;
        
        switch (data.type) {
          case HealthDataType.SLEEP_ASLEEP:
            totalSleepTime += duration;
            if (data.sourceId.contains('deep')) {
              deepSleepTime += duration;
            } else {
              lightSleepTime += duration;
            }
            break;
          case HealthDataType.SLEEP_AWAKE:
            awakeTime += duration;
            break;
          default:
            break;
        }
      }

      // 获取心率数据
      final heartRateData = await _health.getHealthDataFromTypes(
        midnight,
        nextMidnight,
        [HealthDataType.HEART_RATE],
      );

      double averageHeartRate = 0;
      if (heartRateData.isNotEmpty) {
        final sum = heartRateData.fold(0.0, (sum, data) => sum + double.parse(data.value.toString()));
        averageHeartRate = sum / heartRateData.length;
      }

      // 获取呼吸频率数据
      final respiratoryData = await _health.getHealthDataFromTypes(
        midnight,
        nextMidnight,
        [HealthDataType.RESPIRATORY_RATE],
      );

      double averageRespiratoryRate = 0;
      if (respiratoryData.isNotEmpty) {
        final sum = respiratoryData.fold(0.0, (sum, data) => sum + double.parse(data.value.toString()));
        averageRespiratoryRate = sum / respiratoryData.length;
      }

      return {
        'totalSleepTime': totalSleepTime,
        'deepSleepTime': deepSleepTime,
        'lightSleepTime': lightSleepTime,
        'awakeTime': awakeTime,
        'averageHeartRate': averageHeartRate,
        'averageRespiratoryRate': averageRespiratoryRate,
        'sleepQuality': _calculateSleepQuality(
          totalSleepTime,
          deepSleepTime,
          awakeTime,
        ),
      };
    } catch (e) {
      print('Error getting sleep data: $e');
      return {};
    }
  }

  double _calculateSleepQuality(double totalSleep, double deepSleep, double awake) {
    if (totalSleep == 0) return 0;

    // 计算睡眠质量得分 (0-100)
    final deepSleepRatio = deepSleep / totalSleep; // 深睡比例
    final awakeRatio = awake / totalSleep; // 清醒比例
    final idealSleepTime = 480.0; // 理想睡眠时间（8小时）

    // 权重设置
    const deepSleepWeight = 0.4;
    const totalSleepWeight = 0.4;
    const awakeWeight = 0.2;

    // 计算各项得分
    final deepSleepScore = (deepSleepRatio * 100).clamp(0.0, 100.0) * deepSleepWeight;
    final totalSleepScore = ((totalSleep / idealSleepTime) * 100).clamp(0.0, 100.0) * totalSleepWeight;
    final awakeScore = ((1 - awakeRatio) * 100).clamp(0.0, 100.0) * awakeWeight;

    return (deepSleepScore + totalSleepScore + awakeScore).clamp(0.0, 100.0);
  }

  Future<bool> hasHealthData() async {
    try {
      final types = [
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.HEART_RATE,
        HealthDataType.RESPIRATORY_RATE,
      ];

      return await _health.hasPermissions(types) ?? false;
    } catch (e) {
      print('Error checking health data availability: $e');
      return false;
    }
  }
} 