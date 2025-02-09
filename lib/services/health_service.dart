class HealthService {
  static final HealthService instance = HealthService._init();

  HealthService._init();

  Future<bool> requestPermissions() async {
    // Android 平台暂不支持健康数据
    return false;
  }

  Future<Map<String, dynamic>> getSleepData(DateTime date) async {
    // Android 平台返回空数据
    return {
      'totalSleepTime': 0,
      'deepSleepTime': 0,
      'lightSleepTime': 0,
      'awakeTime': 0,
      'averageHeartRate': 0,
      'sleepQuality': 0,
    };
  }

  Future<bool> hasHealthData() async {
    // Android 平台返回 false
    return false;
  }
}
