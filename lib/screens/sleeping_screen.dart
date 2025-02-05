import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/audio_service.dart';
import '../services/sleep_record_service.dart';
import '../models/sleep_record.dart';
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
      _audioService.setSleepStartTime(_startTime!);
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
    final startTimeStr = prefs.getString('sleep_start_time');
    if (startTimeStr != null) {
      final startTime = DateTime.parse(startTimeStr);
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      
      // 创建并保存睡眠记录
      final record = SleepRecord(
        startTime: startTime,
        endTime: endTime,
        duration: duration,
        date: SleepRecord.getDateString(startTime),
      );
      
      await SleepRecordService.instance.saveSleepRecord(record);
      await prefs.remove('sleep_start_time');
    }
    
    // 停止音频播放
    _audioService.stopSound();
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            onTap: () {
              // 无论选择哪个模式，先停止当前播放
              if (_audioService.isPlaying) {
                _audioService.stopSound();
              }
              
              setState(() {
                _selectedMode = mode;
                if (mode == 1) {
                  // 预设睡眠周期模式
                  _audioService.startPresetCycle();
                  Navigator.pop(context);
                } else if (mode == 0) {
                  // 睡眠阶段同步模式 - 目前只停止播放
                  Navigator.pop(context);
                }
                // 自定义模式(mode == 2)不关闭弹窗，只更新状态
              });
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
            subtitle: mode == 1 ? Text(
              '90分钟为一个周期，自动调整频率',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
              ),
            ) : mode == 2 ? Text(
              '选择单一音频循环播放',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
              ),
            ) : null,
          ),
          if (mode == 2)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCustomModeButton('助眠', 'pink_noise_falling_asleep', Icons.nightlight),
                  _buildCustomModeButton('N1', 'pink_noise_n1', Icons.waves),
                  _buildCustomModeButton('N2', 'pink_noise_n2', Icons.waves_outlined),
                  _buildCustomModeButton('N3', 'pink_noise_n3', Icons.water),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCustomModeButton(String label, String soundName, IconData icon) {
    final isPlaying = _audioService.isCustomMode && 
                     _audioService.isPlaying && 
                     _audioService.currentSound == soundName;
    
    return GestureDetector(
      onTap: () {
        // 如果有任何音频在播放，先停止
        if (_audioService.isPlaying) {
          _audioService.stopSound();
        }
        // 开始播放新选择的音频（不使用淡入效果）
        _audioService.startCustomMode(soundName, useInitialFade: false);
        setState(() {
          _selectedMode = 2; // 设置为自定义模式
        });
        // 播放开始后关闭弹窗
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isPlaying ? Colors.white.withOpacity(0.3) : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isPlaying ? Colors.white : Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              isPlaying ? Icons.pause : icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
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
              _audioService.setVolume(value);
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