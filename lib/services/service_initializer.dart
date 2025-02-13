import 'package:flutter/foundation.dart';
import 'settings_service.dart';
import 'database_service.dart';
import 'audio_service.dart';

class ServiceInitializer {
  static bool _isInitialized = false;

  static Future<void> initializeServices() async {
    if (_isInitialized) return;

    try {
      // 1. 初始化设置服务
      try {
        await SettingsService.instance.init();
      } catch (e) {
        debugPrint('设置服务初始化失败，将使用默认设置: $e');
      }

      // 2. 初始化数据库服务
      try {
        await DatabaseService.instance.database;
      } catch (e) {
        debugPrint('数据库服务初始化失败: $e');
        rethrow;
      }

      // 3. 初始化音频服务
      try {
        await AudioService.instance.initializePlayer();
      } catch (e) {
        debugPrint('音频服务初始化失败: $e');
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('服务初始化失败: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  static bool get isInitialized => _isInitialized;
}
