import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/audio_player_widget.dart';
import '../services/audio_service.dart';
import '../widgets/health_data_widget.dart';
import '../utils/animation_utils.dart';
import 'dart:async';
import 'dart:math';

class SleepPreparationScreen extends StatefulWidget {
  const SleepPreparationScreen({super.key});

  @override
  State<SleepPreparationScreen> createState() => _SleepPreparationScreenState();
}

class _SleepPreparationScreenState extends State<SleepPreparationScreen> {
  final AudioService _audioService = AudioService.instance;
  final List<Map<String, dynamic>> _sounds = [
    {'name': 'ocean.mp3', 'display': '海浪', 'icon': Icons.waves},
    {'name': 'rain.mp3', 'display': '雨声', 'icon': Icons.water_drop},
    {'name': 'forest.mp3', 'display': '森林', 'icon': Icons.forest},
    {'name': 'white_noise.mp3', 'display': '白噪音', 'icon': Icons.noise_aware},
    {'name': 'stream.mp3', 'display': '溪流', 'icon': Icons.water},
    {'name': 'fire.mp3', 'display': '篝火', 'icon': Icons.local_fire_department},
  ];
  String? _selectedSound;
  
  // 呼吸引导相关状态
  bool _isBreathingActive = false;
  String _breathingPhase = '点击开始';
  Timer? _breathingTimer;
  int _remainingCycles = 6;
  double _circleSize = 150.0;

  @override
  void dispose() {
    _breathingTimer?.cancel();
    super.dispose();
  }

  void _startBreathing() {
    if (_isBreathingActive) {
      _stopBreathing();
      return;
    }

    setState(() {
      _isBreathingActive = true;
      _remainingCycles = 6;
      _breathingPhase = '准备';
      _circleSize = 150.0;
    });

    // 延迟1秒后开始第一次呼吸循环
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _isBreathingActive) {
        _runBreathingCycle();
      }
    });
  }

  void _stopBreathing() {
    _breathingTimer?.cancel();
    setState(() {
      _isBreathingActive = false;
      _breathingPhase = '点击开始';
      _circleSize = 150.0;
    });
  }

  void _runBreathingCycle() {
    const breathInDuration = 4;
    const holdDuration = 2;
    const breathOutDuration = 4;
    const totalDuration = breathInDuration + holdDuration + breathOutDuration;
    int currentSecond = 0;
    const minSize = 150.0;
    const maxSize = 220.0;
    const sizeStep = (maxSize - minSize) / breathInDuration;

    _breathingTimer?.cancel();
    _breathingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (currentSecond < breathInDuration) {
          // 吸气阶段：逐渐增大
          _breathingPhase = '吸气';
          _circleSize = minSize + (currentSecond + 1) * sizeStep;
        } else if (currentSecond < breathInDuration + holdDuration) {
          // 屏息阶段：保持最大
          _breathingPhase = '屏息';
          _circleSize = maxSize;
        } else {
          // 呼气阶段：逐渐减小
          _breathingPhase = '呼气';
          final breathOutProgress = currentSecond - breathInDuration - holdDuration;
          _circleSize = maxSize - (breathOutProgress + 1) * sizeStep;
        }
      });

      currentSecond++;
      if (currentSecond >= totalDuration) {
        currentSecond = 0;
        setState(() {
          _remainingCycles--;
        });

        if (_remainingCycles <= 0) {
          _breathingTimer?.cancel();
          setState(() {
            _isBreathingActive = false;
            _breathingPhase = '训练完成';
            _circleSize = minSize;
          });
          
          // 显示完成提示
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => Dialog(
                backgroundColor: Colors.transparent,
                child: GlassmorphicContainer(
                  width: 300,
                  height: 260,
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 20),
                      const Icon(
                        Icons.check_circle_outline,
                        color: Colors.white,
                        size: 50,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        '呼吸训练完成',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Text(
                          '继续保持放松的状态\n让我们准备一个美好的睡眠',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Container(
                        width: 200,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          color: Colors.white.withOpacity(0.2),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(22),
                            onTap: () => Navigator.pop(context),
                            child: const Center(
                              child: Text(
                                '确定',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6B8EFF), Color(0xFFFF8FB1)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context)
                  .animate()
                  .fadeIn(duration: 500.ms, curve: Curves.easeOut)
                  .slideY(begin: -0.2, end: 0, duration: 500.ms, curve: Curves.easeOut),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildSoundSelector()
                          .animate()
                          .fadeIn(delay: 100.ms, duration: 500.ms)
                          .slideX(begin: -0.2, end: 0),
                      const SizedBox(height: 20),
                      if (_selectedSound != null)
                        AudioPlayerWidget(
                          soundName: _selectedSound!,
                          displayName: _sounds.firstWhere((s) => s['name'] == _selectedSound)['display'],
                          icon: _sounds.firstWhere((s) => s['name'] == _selectedSound)['icon'],
                        )
                            .animate()
                            .fadeIn(duration: 300.ms)
                            .slideY(begin: -0.3, end: 0, duration: 300.ms, curve: Curves.easeOut),
                      const SizedBox(height: 20),
                      _buildBreathingGuide()
                          .animate()
                          .fadeIn(delay: 300.ms, duration: 500.ms)
                          .slideX(begin: -0.2, end: 0),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            '入睡准备',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoundSelector() {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '助眠音频',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _sounds.length,
                itemBuilder: (context, index) {
                  final sound = _sounds[index];
                  final isSelected = sound['name'] == _selectedSound;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ChoiceChip(
                      label: Text(sound['display']),
                      selected: isSelected,
                      onSelected: (selected) async {
                        if (selected) {
                          // 停止当前播放的音频
                          await _audioService.stopSound();
                          // 开始播放新选择的音频
                          await _audioService.startCustomMode(sound['name']);
                          setState(() => _selectedSound = sound['name']);
                        } else {
                          // 停止播放
                          await _audioService.stopSound();
                          setState(() => _selectedSound = null);
                        }
                      },
                      backgroundColor: Colors.white.withOpacity(0.1),
                      selectedColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.black : Colors.white,
                      ),
                    ),
                  ).animate(
                    onPlay: (controller) => controller.repeat(reverse: true),
                  ).shimmer(
                    duration: 2.seconds,
                    color: Colors.white24,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreathingGuide() {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 280,
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '正念呼吸引导',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _isBreathingActive ? '剩余周期：$_remainingCycles' : '每次训练6个周期',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _startBreathing,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              width: _circleSize,
              height: _circleSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _breathingPhase,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!_isBreathingActive) ...[
                      const SizedBox(height: 8),
                      Text(
                        '点击开始训练',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 