import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService instance = AudioService._init();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  String? _currentSound;
  double _volume = 0.5;

  AudioService._init();

  bool get isPlaying => _isPlaying;
  String? get currentSound => _currentSound;
  double get volume => _volume;

  Future<void> playSound(String soundName) async {
    if (_currentSound == soundName && _isPlaying) {
      await pauseSound();
      return;
    }

    try {
      if (_currentSound != soundName) {
        await _audioPlayer.stop();
        await _audioPlayer.setSource(AssetSource('audio/$soundName.mp3'));
        _currentSound = soundName;
      }

      await _audioPlayer.setVolume(_volume);
      await _audioPlayer.resume();
      _isPlaying = true;
    } catch (e) {
      print('Error playing sound: $e');
      _isPlaying = false;
    }
  }

  Future<void> pauseSound() async {
    try {
      await _audioPlayer.pause();
      _isPlaying = false;
    } catch (e) {
      print('Error pausing sound: $e');
    }
  }

  Future<void> stopSound() async {
    try {
      await _audioPlayer.stop();
      _isPlaying = false;
      _currentSound = null;
    } catch (e) {
      print('Error stopping sound: $e');
    }
  }

  Future<void> setVolume(double volume) async {
    try {
      _volume = volume.clamp(0.0, 1.0);
      await _audioPlayer.setVolume(_volume);
    } catch (e) {
      print('Error setting volume: $e');
    }
  }

  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
} 