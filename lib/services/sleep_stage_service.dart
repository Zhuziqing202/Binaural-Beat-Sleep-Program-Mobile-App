import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

enum SleepStage {
  awake,   // 清醒
  core,    // 核心睡眠
  deep,    // 深度睡眠
  rem      // 快速眼动
}

class SleepStageData {
  final DateTime timestamp;
  final SleepStage stage;
  final double activityLevel;

  SleepStageData({
    required this.timestamp,
    required this.stage,
    required this.activityLevel,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'stage': stage.toString(),
    'activityLevel': activityLevel,
  };

  factory SleepStageData.fromJson(Map<String, dynamic> json) => SleepStageData(
    timestamp: DateTime.parse(json['timestamp']),
    stage: SleepStage.values.firstWhere(
      (e) => e.toString() == json['stage'],
    ),
    activityLevel: json['activityLevel'],
  );
}

class SleepStageService {
  static final SleepStageService instance = SleepStageService._init();
  
  StreamSubscription? _accelerometerSubscription;
  Timer? _analysisTimer;
  final List<double> _activityBuffer = [];
  final List<SleepStageData> _stageData = [];
  bool _isMonitoring = false;
  
  // 配置参数
  static const int _windowSize = 60; // 1分钟的活动窗口
  static const int _analysisInterval = 300; // 每5分钟进行一次阶段分析
  static const double _awakeThreshold = 0.3;
  static const double _deepThreshold = 0.05;
  static const double _remThreshold = 0.15;

  SleepStageService._init();

  bool get isMonitoring => _isMonitoring;
  List<SleepStageData> get stageData => List.unmodifiable(_stageData);

  void startMonitoring() {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    _stageData.clear();
    _activityBuffer.clear();

    // 订阅加速度传感器数据
    _accelerometerSubscription = accelerometerEvents.listen((event) {
      final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      _activityBuffer.add(magnitude);
      
      // 保持缓冲区大小
      if (_activityBuffer.length > _windowSize) {
        _activityBuffer.removeAt(0);
      }
    });

    // 定期分析睡眠阶段
    _analysisTimer = Timer.periodic(
      const Duration(seconds: _analysisInterval),
      (_) => _analyzeSleepStage(),
    );
  }

  void stopMonitoring() {
    _isMonitoring = false;
    _accelerometerSubscription?.cancel();
    _analysisTimer?.cancel();
  }

  void _analyzeSleepStage() {
    if (_activityBuffer.isEmpty) return;

    // 计算活动水平
    final activityLevel = _calculateActivityLevel();
    
    // 确定睡眠阶段
    final stage = _determineSleepStage(activityLevel);
    
    // 记录数据
    _stageData.add(SleepStageData(
      timestamp: DateTime.now(),
      stage: stage,
      activityLevel: activityLevel,
    ));
  }

  double _calculateActivityLevel() {
    if (_activityBuffer.isEmpty) return 0.0;
    
    // 计算活动水平的标准差
    final mean = _activityBuffer.reduce((a, b) => a + b) / _activityBuffer.length;
    final variance = _activityBuffer.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / _activityBuffer.length;
    return sqrt(variance);
  }

  SleepStage _determineSleepStage(double activityLevel) {
    // 基于活动水平确定睡眠阶段
    if (activityLevel >= _awakeThreshold) {
      return SleepStage.awake;
    } else if (activityLevel <= _deepThreshold) {
      return SleepStage.deep;
    } else if (activityLevel <= _remThreshold) {
      // REM睡眠通常在深度睡眠后出现，且活动水平略高
      final lastStages = _getLastStages(3);
      if (lastStages.contains(SleepStage.deep)) {
        return SleepStage.rem;
      }
    }
    return SleepStage.core;
  }

  List<SleepStage> _getLastStages(int count) {
    return _stageData
        .reversed
        .take(count)
        .map((data) => data.stage)
        .toList();
  }

  Map<SleepStage, Duration> getStagesDuration() {
    final Map<SleepStage, Duration> durations = {
      for (var stage in SleepStage.values) stage: Duration.zero
    };
    
    if (_stageData.isEmpty) return durations;

    for (int i = 0; i < _stageData.length - 1; i++) {
      final stage = _stageData[i].stage;
      final duration = _stageData[i + 1].timestamp.difference(_stageData[i].timestamp);
      durations[stage] = durations[stage]! + duration;
    }

    return durations;
  }

  Map<String, dynamic> getSleepQualityMetrics() {
    final durations = getStagesDuration();
    final totalDuration = durations.values.reduce((a, b) => a + b);
    
    if (totalDuration.inMinutes == 0) return {};

    return {
      'deepSleepRatio': durations[SleepStage.deep]!.inMinutes / totalDuration.inMinutes,
      'remSleepRatio': durations[SleepStage.rem]!.inMinutes / totalDuration.inMinutes,
      'awakeRatio': durations[SleepStage.awake]!.inMinutes / totalDuration.inMinutes,
      'sleepEfficiency': 1 - (durations[SleepStage.awake]!.inMinutes / totalDuration.inMinutes),
    };
  }
} 