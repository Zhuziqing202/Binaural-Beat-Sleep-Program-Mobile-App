import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../services/audio_service.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String soundName;
  final String displayName;
  final IconData icon;

  const AudioPlayerWidget({
    super.key,
    required this.soundName,
    required this.displayName,
    required this.icon,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioService _audioService = AudioService.instance;
  bool _isPlaying = false;
  double _volume = 0.5;

  @override
  void initState() {
    super.initState();
    _isPlaying = _audioService.isPlaying && _audioService.currentSound == widget.soundName;
    _volume = _audioService.volume;
  }

  @override
  Widget build(BuildContext context) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 120,
      borderRadius: 20,
      blur: 20,
      alignment: Alignment.center,
      border: 2,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.1),
          Colors.white.withOpacity(0.05),
        ],
      ),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.5),
          Colors.white.withOpacity(0.2),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Row(
              children: [
                Icon(widget.icon, color: Colors.white, size: 24),
                const SizedBox(width: 10),
                Text(
                  widget.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                    color: Colors.white,
                    size: 32,
                  ),
                  onPressed: _togglePlay,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.volume_down, color: Colors.white, size: 20),
                Expanded(
                  child: Slider(
                    value: _volume,
                    onChanged: _updateVolume,
                    activeColor: Colors.white,
                    inactiveColor: Colors.white.withOpacity(0.3),
                  ),
                ),
                const Icon(Icons.volume_up, color: Colors.white, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _togglePlay() async {
    if (_isPlaying) {
      await _audioService.pauseSound();
    } else {
      await _audioService.playSound(widget.soundName);
    }
    setState(() {
      _isPlaying = _audioService.isPlaying;
    });
  }

  void _updateVolume(double value) async {
    await _audioService.setVolume(value);
    setState(() {
      _volume = value;
    });
  }
} 