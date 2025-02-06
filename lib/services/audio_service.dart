import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

class AudioService {
  static final AudioService instance = AudioService._init();
  final AudioPlayer _player1 = AudioPlayer();
  final AudioPlayer _player2 = AudioPlayer();
  bool _isPlayer1Active = true;
  bool _isPlaying = false;
  String? _currentSound;
  double _volume = 0.5;
  Timer? _cycleTimer;
  Timer? _fadeTimer;
  Timer? _loopTimer;
  int _currentPhase = 0; // 0: 入睡, 1: N1, 2: N2, 3: N3, 4: REM
  bool _isPresetMode = false;
  bool _isCustomMode = false;
  DateTime? _sleepStartTime;
  static const _crossFadeDuration = Duration(seconds: 2);

  AudioService._init();

  AudioPlayer get _activePlayer => _isPlayer1Active ? _player1 : _player2;
  AudioPlayer get _inactivePlayer => _isPlayer1Active ? _player2 : _player1;

  bool get isPlaying => _isPlaying;
  String? get currentSound => _currentSound;
  double get volume => _volume;
  bool get isPresetMode => _isPresetMode;
  bool get isCustomMode => _isCustomMode;

  void setSleepStartTime(DateTime startTime) {
    _sleepStartTime = startTime;
  }

  Future<void> _setupLoopTransition(String soundName) async {
    if (!_isPlaying) return;

    try {
      // 准备非活动播放器
      await _inactivePlayer.setSource(AssetSource('audio/$soundName'));
      await _inactivePlayer.setVolume(0);
      await _inactivePlayer.setReleaseMode(ReleaseMode.loop);

      // 获取音频文件的持续时间（假设为60秒）
      const audioDuration = Duration(seconds: 60);
      const transitionStart = Duration(seconds: 58); // 在第58秒开始准备过渡
      
      _loopTimer?.cancel();
      _loopTimer = Timer(transitionStart, () async {
        if (!_isPlaying) return;
        
        // 启动下一个播放器（静音状态）
        await _inactivePlayer.resume();
        
        // 在最后2秒进行音量交叉淡变
        const steps = 20; // 20个步骤完成交叉淡变
        const stepDuration = 100; // 每步100毫秒，总共2秒
        final volumeStep = _volume / steps;
        
        var currentVolume = _volume;
        var nextVolume = 0.0;
        
        _fadeTimer?.cancel();
        _fadeTimer = Timer.periodic(Duration(milliseconds: stepDuration), (timer) async {
          if (!_isPlaying) {
            timer.cancel();
            return;
          }
          
          currentVolume -= volumeStep;
          nextVolume += volumeStep;
          
          await _activePlayer.setVolume(currentVolume.clamp(0.0, _volume));
          await _inactivePlayer.setVolume(nextVolume.clamp(0.0, _volume));
          
          if (nextVolume >= _volume) {
            timer.cancel();
            await _activePlayer.stop();
            
            // 切换活动播放器
            _isPlayer1Active = !_isPlayer1Active;
            
            // 为下一次循环做准备
            _setupLoopTransition(soundName);
          }
        });
      });
    } catch (e) {
      print('Error setting up loop transition: $e');
    }
  }

  Future<void> _crossFade(AudioPlayer fadeOutPlayer, AudioPlayer fadeInPlayer) async {
    const steps = 20;
    final stepDuration = _crossFadeDuration.inMilliseconds ~/ steps;
    final volumeStep = _volume / steps;

    var currentVolume = _volume;
    var nextVolume = 0.0;

    _fadeTimer?.cancel();
    _fadeTimer = Timer.periodic(Duration(milliseconds: stepDuration), (timer) async {
      currentVolume -= volumeStep;
      nextVolume += volumeStep;

      await fadeOutPlayer.setVolume(currentVolume.clamp(0.0, 1.0));
      await fadeInPlayer.setVolume(nextVolume.clamp(0.0, 1.0));

      if (nextVolume >= _volume) {
        timer.cancel();
        await fadeOutPlayer.stop();
      }
    });

    await fadeInPlayer.resume();
  }

  Future<void> startPresetCycle() async {
    _isPresetMode = true;
    _isCustomMode = false;
    _currentPhase = 0;
    await _playSleepPhase();
  }

  Future<void> startCustomMode(String soundName, {bool useInitialFade = true}) async {
    _isCustomMode = true;
    _isPresetMode = false;
    if (_currentSound == soundName && _isPlaying) {
      await stopSound();
      return;
    }

    try {
      // 停止当前播放的音频
      await _activePlayer.stop();
      await _inactivePlayer.stop();
      
      // 设置音频源并准备播放
      await _activePlayer.setSource(AssetSource('audio/$soundName'));
      await _activePlayer.setVolume(_volume);
      await _activePlayer.setReleaseMode(ReleaseMode.loop);
      await _activePlayer.resume();
      
      _currentSound = soundName;
      _isPlaying = true;

      // 准备第二个播放器用于无缝循环
      await _setupLoopTransition(soundName);
    } catch (e) {
      print('Error playing sound: $e');
      _isPlaying = false;
    }
  }

  Future<void> _playSleepPhase() async {
    if (!_isPresetMode) return;

    String soundFile;
    switch (_currentPhase) {
      case 1:
        soundFile = 'pink_noise_n1';
        break;
      case 2:
        soundFile = 'pink_noise_n2';
        break;
      case 3:
        soundFile = 'pink_noise_n3';
        break;
      default:
        soundFile = 'pink_noise_n1';
    }

    // 使用startCustomMode来播放音频，但不使用初始淡入效果
    await startCustomMode(soundFile, useInitialFade: false);

    if (_isPresetMode) {
      // 每个阶段22.5分钟
      _cycleTimer = Timer(const Duration(minutes: 22, seconds: 30), () {
        _currentPhase++;
        _playSleepPhase();
      });
    }
  }

  Future<void> _fadeInSound(String soundName) async {
    try {
      if (_currentSound != soundName) {
        if (_isPlaying) {
          await _fadeOutSound();
        }
        await _activePlayer.stop();
        await _activePlayer.setSource(AssetSource('audio/$soundName'));
        await _activePlayer.setVolume(0);
        await _activePlayer.resume();
        await _activePlayer.setReleaseMode(ReleaseMode.loop);
        _currentSound = soundName;
        _isPlaying = true;

        // 淡入效果
        const fadeDuration = Duration(seconds: 3);
        const steps = 30;
        final stepDuration = fadeDuration.inMilliseconds ~/ steps;
        final volumeStep = _volume / steps;

        var currentVolume = 0.0;
        _fadeTimer?.cancel();
        _fadeTimer = Timer.periodic(Duration(milliseconds: stepDuration), (timer) {
          currentVolume += volumeStep;
          if (currentVolume >= _volume) {
            _activePlayer.setVolume(_volume);
            timer.cancel();
            // 开始准备循环过渡
            _setupLoopTransition(soundName);
          } else {
            _activePlayer.setVolume(currentVolume);
          }
        });
      }
    } catch (e) {
      print('Error fading in sound: $e');
      _isPlaying = false;
    }
  }

  Future<void> _fadeOutSound() async {
    if (!_isPlaying) return;

    try {
      _loopTimer?.cancel();
      const fadeDuration = Duration(seconds: 3);
      const steps = 30;
      final stepDuration = fadeDuration.inMilliseconds ~/ steps;
      final volumeStep = _volume / steps;

      var currentVolume = _volume;
      _fadeTimer?.cancel();
      _fadeTimer = Timer.periodic(Duration(milliseconds: stepDuration), (timer) {
        currentVolume -= volumeStep;
        if (currentVolume <= 0) {
          _activePlayer.setVolume(0);
          _activePlayer.stop();
          _inactivePlayer.stop();
          _isPlaying = false;
          timer.cancel();
        } else {
          _activePlayer.setVolume(currentVolume);
        }
      });
    } catch (e) {
      print('Error fading out sound: $e');
    }
  }

  Future<void> playSound(String soundName) async {
    if (_currentSound == soundName && _isPlaying) {
      await stopSound();
      return;
    }

    try {
      await _activePlayer.stop();
      await _activePlayer.setSource(AssetSource('audio/$soundName'));
      await _activePlayer.setVolume(_volume);
      await _activePlayer.resume();
      await _activePlayer.setReleaseMode(ReleaseMode.loop);
      _currentSound = soundName;
      _isPlaying = true;

      // 准备下一个播放器用于无缝循环
      _setupLoopTransition(soundName);
    } catch (e) {
      print('Error playing sound: $e');
      _isPlaying = false;
    }
  }

  Future<void> pauseSound() async {
    try {
      await _fadeOutSound();
    } catch (e) {
      print('Error pausing sound: $e');
    }
  }

  Future<void> stopSound() async {
    try {
      _loopTimer?.cancel();
      _fadeTimer?.cancel();
      _cycleTimer?.cancel();
      _loopTimer = null;
      _fadeTimer = null;
      _cycleTimer = null;
      _isPresetMode = false;
      _isCustomMode = false;
      _currentPhase = 0;
      
      await _activePlayer.stop();
      await _inactivePlayer.stop();
      _isPlaying = false;
      _currentSound = null;
    } catch (e) {
      print('Error stopping sound: $e');
    }
  }

  Future<void> setVolume(double volume) async {
    try {
      _volume = volume.clamp(0.0, 1.0);
      if (_isPlaying) {
        await _activePlayer.setVolume(_volume);
      }
    } catch (e) {
      print('Error setting volume: $e');
    }
  }

  Future<void> dispose() async {
    _cycleTimer?.cancel();
    _fadeTimer?.cancel();
    _loopTimer?.cancel();
    await _player1.dispose();
    await _player2.dispose();
  }
} 