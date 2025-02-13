import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

class AudioService {
  static final AudioService instance = AudioService._init();
  AudioPlayer? _presetPlayer; // 用于播放计划音频
  AudioPlayer? _customPlayer; // 用于播放自定义音频
  bool _isPresetPlaying = false;
  bool _isCustomPlaying = false;
  String? _currentPresetSound;
  String? _currentCustomSound;
  double _presetVolume = 0.5;
  double _customVolume = 0.5;
  Timer? _cycleTimer;
  Timer? _fadeTimer;
  bool _isPresetMode = false;
  bool _isCustomMode = false;
  DateTime? _sleepStartTime;
  bool _isInitialized = false;
  DateTime? _pauseTime;

  AudioService._init();

  Future<void> initializePlayer() async {
    if (_isInitialized) return;

    try {
      // 确保之前的实例被正确释放
      await dispose();
      
      // 创建新的播放器实例
      _presetPlayer = AudioPlayer();
      _customPlayer = AudioPlayer();

      // 设置预设播放器参数
      await Future.wait([
        _presetPlayer?.setReleaseMode(ReleaseMode.loop) ?? Future.value(),
        _customPlayer?.setReleaseMode(ReleaseMode.loop) ?? Future.value(),
        _presetPlayer?.setPlayerMode(PlayerMode.lowLatency) ?? Future.value(),
        _customPlayer?.setPlayerMode(PlayerMode.lowLatency) ?? Future.value(),
      ]);

      // 监听预设播放器完成
      _presetPlayer?.onPlayerComplete.listen((_) async {
        try {
          await _presetPlayer?.seek(Duration.zero);
          await _presetPlayer?.resume();
        } catch (e) {
          debugPrint('预设播放器循环失败: $e');
        }
      });

      // 监听自定义播放器完成
      _customPlayer?.onPlayerComplete.listen((_) async {
        try {
          await _customPlayer?.seek(Duration.zero);
          await _customPlayer?.resume();
        } catch (e) {
          debugPrint('自定义播放器循环失败: $e');
        }
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('播放器初始化失败: $e');
      _isInitialized = false;
      await dispose();
      rethrow;
    }
  }

  bool get isPresetPlaying => _isPresetPlaying;
  bool get isCustomPlaying => _isCustomPlaying;
  String? get currentPresetSound => _currentPresetSound;
  String? get currentCustomSound => _currentCustomSound;
  double get presetVolume => _presetVolume;
  double get customVolume => _customVolume;
  bool get isPresetMode => _isPresetMode;
  bool get isCustomMode => _isCustomMode;

  void setSleepStartTime(DateTime startTime) {
    _sleepStartTime = startTime;
  }

  Future<void> startPresetCycle() async {
    if (_isPresetMode) {
      return;
    }

    try {
      _isPresetMode = true;
      if (_sleepStartTime == null) {
        _sleepStartTime = DateTime.now();
      } else if (_pauseTime != null) {
        // 如果是从暂停恢复，调整开始时间以保持进度
        final pauseDuration = DateTime.now().difference(_pauseTime!);
        _sleepStartTime = _sleepStartTime!.add(pauseDuration);
      }

      // 先播放15分钟的助眠音频
      await playPresetSound('pink_noise_falling_asleep.mp3');

      // 设置15分钟后开始睡眠周期
      _cycleTimer?.cancel();
      _cycleTimer = Timer(const Duration(minutes: 15), () {
        _playSleepPhase();
      });
    } catch (e) {
      debugPrint('启动预设循环失败: $e');
      _isPresetMode = false;
      rethrow;
    }
  }

  Future<void> playPresetSound(String soundName) async {
    try {
      if (_isPresetPlaying) {
        await _presetPlayer?.stop();
      }

      // 设置音频源
      final source = AssetSource('audio/$soundName');
      debugPrint('正在加载音频文件: audio/$soundName');
      
      try {
        await _presetPlayer?.setSource(source);
      } catch (e) {
        debugPrint('加载音频文件失败: $e');
        rethrow;
      }

      // 为n1-n3音频设置3倍音量
      if (soundName.contains('pink_noise_n')) {
        await _presetPlayer?.setVolume(_presetVolume * 3.0);
      } else {
        await _presetPlayer?.setVolume(_presetVolume);
      }

      // 开始播放
      await _presetPlayer?.resume();
      _currentPresetSound = soundName;
      _isPresetPlaying = true;
    } catch (e) {
      debugPrint('播放预设音频失败: $e');
      rethrow;
    }
  }

  Future<void> playCustomSound(String soundName) async {
    try {
      _isCustomMode = true;

      if (_isCustomPlaying && _currentCustomSound == soundName) {
        await stopCustomSound();
        return;
      }

      if (_isCustomPlaying) {
        await _customPlayer?.stop();
      }

      // 设置音频源
      final source = AssetSource('audio/$soundName');
      debugPrint('正在加载音频文件: audio/$soundName');
      
      try {
        await _customPlayer?.setSource(source);
      } catch (e) {
        debugPrint('加载音频文件失败: $e');
        rethrow;
      }
      
      await _customPlayer?.setVolume(_customVolume);

      // 开始播放
      await _customPlayer?.resume();
      _currentCustomSound = soundName;
      _isCustomPlaying = true;
    } catch (e) {
      debugPrint('播放自定义音频失败: $e');
      _isCustomMode = false;
      _isCustomPlaying = false;
      _currentCustomSound = null;
      rethrow;
    }
  }

  Future<void> _playSleepPhase() async {
    if (!_isPresetMode) return;

    try {
      String? soundFile;
      final now = DateTime.now();
      var elapsedMinutes = now.difference(_sleepStartTime!).inMinutes - 15;

      // 如果有暂停记录，调整已经过时间
      if (_pauseTime != null) {
        final pauseDuration = now.difference(_pauseTime!);
        elapsedMinutes -= pauseDuration.inMinutes;
      }

      if (elapsedMinutes < 0) {
        return;
      }

      final currentCycle = (elapsedMinutes ~/ 90);
      final phaseInCycle = ((elapsedMinutes % 90) ~/ 22.5).toInt();

      switch (phaseInCycle) {
        case 0:
          soundFile = 'pink_noise_n1.mp3';
          break;
        case 1:
          soundFile = 'pink_noise_n2.mp3';
          break;
        case 2:
          soundFile = 'pink_noise_n3.mp3';
          break;
        case 3:
          await stopPresetSound();
          break;
      }

      if (soundFile != null) {
        await playPresetSound(soundFile);
      }

      final nextPhaseStart = _sleepStartTime!.add(
        Duration(
          minutes:
              15 + (currentCycle * 90) + ((phaseInCycle + 1) * 22.5).toInt(),
        ),
      );
      final delayToNextPhase = nextPhaseStart.difference(now);

      _cycleTimer?.cancel();
      _cycleTimer = Timer(delayToNextPhase, () {
        _playSleepPhase();
      });
    } catch (e) {
      debugPrint('播放睡眠阶段失败: $e');
      await stopPresetSound();
      rethrow;
    }
  }

  Future<void> pausePresetSound() async {
    if (!_isPresetPlaying) return;
    try {
      await _presetPlayer?.pause();
      _isPresetPlaying = false;
    } catch (e) {
      debugPrint('暂停预设音频失败: $e');
      rethrow;
    }
  }

  Future<void> pauseCustomSound() async {
    if (!_isCustomPlaying) return;
    try {
      await _customPlayer?.pause();
      _isCustomPlaying = false;
    } catch (e) {
      debugPrint('暂停自定义音频失败: $e');
      rethrow;
    }
  }

  Future<void> stopPresetSound() async {
    try {
      _pauseTime = DateTime.now();
      _cycleTimer?.cancel();
      _fadeTimer?.cancel();
      _cycleTimer = null;
      _fadeTimer = null;
      _isPresetMode = false;

      if (_isPresetPlaying) {
        await _presetPlayer?.stop();
        _isPresetPlaying = false;
        _currentPresetSound = null;
      }
    } catch (e) {
      debugPrint('停止预设音频失败: $e');
      _isPresetPlaying = false;
      _currentPresetSound = null;
      rethrow;
    }
  }

  Future<void> stopCustomSound() async {
    try {
      if (_isCustomPlaying) {
        await _customPlayer?.stop();
        _isCustomPlaying = false;
        _currentCustomSound = null;
        _isCustomMode = false;
      }
    } catch (e) {
      debugPrint('停止自定义音频失败: $e');
      _isCustomPlaying = false;
      _currentCustomSound = null;
      rethrow;
    }
  }

  Future<void> setPresetVolume(double volume) async {
    try {
      _presetVolume = volume.clamp(0.0, 1.0);
      if (_isPresetPlaying) {
        if (_currentPresetSound != null &&
            _currentPresetSound!.contains('pink_noise_n')) {
          await _presetPlayer?.setVolume(_presetVolume * 3.0);
        } else {
          await _presetPlayer?.setVolume(_presetVolume);
        }
      }
    } catch (e) {
      debugPrint('设置预设音量失败: $e');
      rethrow;
    }
  }

  Future<void> setCustomVolume(double volume) async {
    try {
      _customVolume = volume.clamp(0.0, 1.0);
      if (_isCustomPlaying) {
        await _customPlayer?.setVolume(_customVolume);
      }
    } catch (e) {
      debugPrint('设置自定义音量失败: $e');
      rethrow;
    }
  }

  Future<void> dispose() async {
    try {
      _cycleTimer?.cancel();
      _fadeTimer?.cancel();
      _cycleTimer = null;
      _fadeTimer = null;
      
      await stopPresetSound();
      await stopCustomSound();
      
      if (_presetPlayer != null) {
        await _presetPlayer?.dispose();
        _presetPlayer = null;
      }
      if (_customPlayer != null) {
        await _customPlayer?.dispose();
        _customPlayer = null;
      }
      _isInitialized = false;
    } catch (e) {
      debugPrint('释放音频服务资源失败: $e');
      // 不要抛出异常，以确保清理过程继续
    }
  }
}
