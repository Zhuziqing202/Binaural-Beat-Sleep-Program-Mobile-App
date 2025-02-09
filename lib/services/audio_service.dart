import 'package:just_audio/just_audio.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

class AudioService {
  static final AudioService instance = AudioService._init();
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  String? _currentSound;
  double _volume = 0.5;
  Timer? _cycleTimer;
  Timer? _fadeTimer;
  bool _isPresetMode = false;
  bool _isCustomMode = false;
  DateTime? _sleepStartTime;
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _playerErrorSubscription;
  bool _isInitialized = false;

  AudioService._init() {
    initializePlayer();
  }

  Future<void> initializePlayer() async {
    if (_isInitialized) return;

    try {
      // 监听播放器状态
      _playerStateSubscription = _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _player.seek(Duration.zero);
          _player.play();
        }
      }, onError: (error) {
        debugPrint('播放器状态监听错误: $error');
        _handlePlaybackError();
      });

      // 监听播放器错误
      _playerErrorSubscription = _player.playbackEventStream.listen(
        null,
        onError: (error) {
          debugPrint('播放器事件错误: $error');
          _handlePlaybackError();
        },
      );

      _isInitialized = true;
    } catch (e) {
      debugPrint('播放器初始化失败: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  void _handlePlaybackError() {
    _isPlaying = false;
    _currentSound = null;
  }

  bool get isPlaying => _isPlaying;
  String? get currentSound => _currentSound;
  double get volume => _volume;
  bool get isPresetMode => _isPresetMode;
  bool get isCustomMode => _isCustomMode;

  void setSleepStartTime(DateTime startTime) {
    _sleepStartTime = startTime;
  }

  Future<void> startPresetCycle() async {
    if (_isPresetMode) {
      await stopSound();
      return;
    }

    try {
      _isPresetMode = true;
      _isCustomMode = false;
      _sleepStartTime = DateTime.now();
      await _playSleepPhase();
    } catch (e) {
      debugPrint('启动预设循环失败: $e');
      _isPresetMode = false;
      rethrow;
    }
  }

  Future<void> startCustomMode(String soundName) async {
    if (_currentSound == soundName && _isPlaying) {
      await stopSound();
      return;
    }

    try {
      _isCustomMode = true;
      _isPresetMode = false;

      if (_isPlaying) {
        await _player.stop();
      }

      // 设置音频源
      await _player.setAsset('assets/audio/$soundName');
      await _player.setVolume(_volume);
      await _player.setLoopMode(LoopMode.all);

      // 开始播放
      await _player.play();
      _currentSound = soundName;
      _isPlaying = true;
    } catch (e) {
      debugPrint('启动自定义模式失败: $e');
      _isCustomMode = false;
      _isPlaying = false;
      _currentSound = null;
      rethrow;
    }
  }

  Future<void> _playSleepPhase() async {
    if (!_isPresetMode) return;

    try {
      String? soundFile;
      final now = DateTime.now();
      final elapsedMinutes = now.difference(_sleepStartTime!).inMinutes;
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
          await stopSound();
          break;
      }

      if (soundFile != null) {
        await startCustomMode(soundFile);
      }

      final nextPhaseStart = _sleepStartTime!.add(
        Duration(
          minutes: (currentCycle * 90) + ((phaseInCycle + 1) * 22.5).toInt(),
        ),
      );
      final delayToNextPhase = nextPhaseStart.difference(now);

      _cycleTimer?.cancel();
      _cycleTimer = Timer(delayToNextPhase, () {
        _playSleepPhase();
      });
    } catch (e) {
      debugPrint('播放睡眠阶段失败: $e');
      await stopSound();
      rethrow;
    }
  }

  Future<void> playSound(String soundName) async {
    try {
      await startCustomMode(soundName);
    } catch (e) {
      debugPrint('播放声音失败: $e');
      rethrow;
    }
  }

  Future<void> pauseSound() async {
    if (!_isPlaying) return;

    try {
      await _player.pause();
      _isPlaying = false;
    } catch (e) {
      debugPrint('暂停声音失败: $e');
      rethrow;
    }
  }

  Future<void> stopSound() async {
    try {
      _cycleTimer?.cancel();
      _fadeTimer?.cancel();
      _cycleTimer = null;
      _fadeTimer = null;
      _isPresetMode = false;
      _isCustomMode = false;

      if (_isPlaying) {
        await _player.stop();
        _isPlaying = false;
        _currentSound = null;
      }
    } catch (e) {
      debugPrint('停止声音失败: $e');
      // 重置状态，即使发生错误
      _isPlaying = false;
      _currentSound = null;
      rethrow;
    }
  }

  Future<void> setVolume(double volume) async {
    try {
      _volume = volume.clamp(0.0, 1.0);
      if (_isPlaying) {
        await _player.setVolume(_volume);
      }
    } catch (e) {
      debugPrint('设置音量失败: $e');
      rethrow;
    }
  }

  Future<void> dispose() async {
    try {
      await stopSound();
      _playerStateSubscription?.cancel();
      _playerErrorSubscription?.cancel();
      await _player.dispose();
      _isInitialized = false;
    } catch (e) {
      debugPrint('释放音频服务资源失败: $e');
      rethrow;
    }
  }
}
