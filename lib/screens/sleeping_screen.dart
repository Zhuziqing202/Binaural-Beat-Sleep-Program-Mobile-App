import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SleepingScreen extends StatefulWidget {
  const SleepingScreen({super.key});

  @override
  State<SleepingScreen> createState() => _SleepingScreenState();
}

class _SleepingScreenState extends State<SleepingScreen> {
  final AudioService _audioService = AudioService.instance;
  int _selectedMode = 0; // 0: 睡眠阶段, 1: 预设周期, 2: 频段选择
  double _volume = 0.7; // 默认音量
  DateTime? _startTime;
  
  final List<String> _modes = ['睡眠阶段同步', '预设睡眠周期', '频段选择'];
  final List<String> _modeDescriptions = [
    '根据睡眠阶段自动调整',
    '按预设周期播放',
    '手动选择频段播放'
  ];

  @override
  void initState() {
    super.initState();
    _loadStartTime();
    // 启动定时更新
    _startPeriodicUpdate();
  }

  void _startPeriodicUpdate() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {});
        _startPeriodicUpdate();
      }
    });
  }

  Future<void> _loadStartTime() async {
    final prefs = await SharedPreferences.getInstance();
    final startTimeStr = prefs.getString('sleep_start_time');
    if (startTimeStr != null) {
      setState(() {
        _startTime = DateTime.parse(startTimeStr);
      });
    } else {
      _startSleeping();
    }
  }

  Future<void> _startSleeping() async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sleep_start_time', now.toIso8601String());
    setState(() {
      _startTime = now;
    });
  }

  Future<void> _endSleeping() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sleep_start_time');
    // TODO: 保存睡眠记录到数据库
    Navigator.pop(context);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    return '$hours:$minutes';
  }

  @override
  void dispose() {
    _audioService.stopSound();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Duration elapsed = _startTime != null ? DateTime.now().difference(_startTime!) : Duration.zero;
    
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
              _buildAppBar(context),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Spacer(),
                      _buildTimer(elapsed)
                          .animate(
                            onPlay: (controller) => controller.repeat(),
                          )
                          .shimmer(
                            duration: 2.seconds,
                            color: Colors.white24,
                          ),
                      const Spacer(),
                      _buildModeSelector()
                          .animate()
                          .fadeIn(delay: 200.ms, duration: 500.ms)
                          .slideX(begin: -0.2, end: 0),
                      const SizedBox(height: 20),
                      _buildVolumeControl()
                          .animate()
                          .fadeIn(delay: 400.ms, duration: 500.ms)
                          .slideX(begin: -0.2, end: 0),
                      const SizedBox(height: 40),
                      _buildEndSleepButton()
                          .animate()
                          .fadeIn(delay: 500.ms, duration: 500.ms)
                          .scale(delay: 500.ms, duration: 500.ms),
                      const SizedBox(height: 20),
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
            '睡眠中',
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

  Widget _buildTimer(Duration elapsed) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 200,
          height: 200,
          child: CircularProgressIndicator(
            value: (elapsed.inMinutes % 60) / 60,
            strokeWidth: 8,
            backgroundColor: Colors.white.withOpacity(0.2),
            color: Colors.white,
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatDuration(elapsed),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ).animate(
              onPlay: (controller) => controller.repeat(),
            ).fadeIn(
              duration: 3.seconds,
              curve: Curves.easeInOut,
            ).then(delay: 1.seconds),
            Text(
              '已睡眠时间',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModeSelector() {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 80,
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildModeButton(
            '播放模式',
            Icons.mode_rounded,
            () {
              showDialog(
                context: context,
                builder: (context) => Dialog(
                  backgroundColor: Colors.transparent,
                  child: GlassmorphicContainer(
                    width: 280,
                    height: 240,
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
                        const Padding(
                          padding: EdgeInsets.all(15),
                          child: Text(
                            '选择播放模式',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Divider(color: Colors.white24),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                _buildModeOption('睡眠阶段同步', 0),
                                _buildModeOption('预设睡眠周期', 1),
                                _buildModeOption('自定义', 2),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          _buildModeButton(
            '助眠音频',
            Icons.music_note_rounded,
            () {
              showDialog(
                context: context,
                builder: (context) => Dialog(
                  backgroundColor: Colors.transparent,
                  child: GlassmorphicContainer(
                    width: 280,
                    height: 360,
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
                        const Padding(
                          padding: EdgeInsets.all(15),
                          child: Text(
                            '选择助眠音效',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Divider(color: Colors.white24),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                _buildSoundOption('无', 'none', Icons.music_off),
                                _buildSoundOption('海浪', 'ocean', Icons.waves),
                                _buildSoundOption('雨声', 'rain', Icons.water_drop),
                                _buildSoundOption('森林', 'forest', Icons.forest),
                                _buildSoundOption('白噪音', 'white_noise', Icons.noise_aware),
                                _buildSoundOption('溪流', 'stream', Icons.water),
                                _buildSoundOption('篝火', 'fire', Icons.local_fire_department),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(String text, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeOption(String text, int mode) {
    final isSelected = _selectedMode == mode;
    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: () {
          setState(() => _selectedMode = mode);
          Navigator.pop(context);
        },
        leading: Icon(
          isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
          color: Colors.white,
        ),
        title: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildSoundOption(String text, String soundName, IconData icon) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: () {
          if (soundName == 'none') {
            _audioService.stopSound();
          } else {
            _audioService.playSound(soundName);
          }
          Navigator.pop(context);
        },
        leading: Icon(icon, color: Colors.white),
        title: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildVolumeControl() {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 80,
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
          Text(
            '音量: ${(_volume * 100).toInt()}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          Slider(
            value: _volume,
            min: 0.0,
            max: 1.0,
            activeColor: Colors.white,
            inactiveColor: Colors.white.withOpacity(0.3),
            onChanged: (value) {
              setState(() => _volume = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEndSleepButton() {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => Dialog(
                backgroundColor: Colors.transparent,
                child: GlassmorphicContainer(
                  width: 280,
                  height: 180,
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
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          '确认结束睡眠',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          '确定要结束本次睡眠记录吗？',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Divider(color: Colors.white24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              '取消',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 20,
                            color: Colors.white24,
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _endSleeping();
                            },
                            child: const Text(
                              '确定',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.stop_rounded,
              color: Colors.white,
              size: 40,
            ),
          ).animate(
            onPlay: (controller) => controller.repeat(reverse: true),
          ).scale(
            duration: 2.seconds,
            begin: const Offset(1, 1),
            end: const Offset(1.1, 1.1),
            curve: Curves.easeInOut,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          '结束睡眠',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
} 