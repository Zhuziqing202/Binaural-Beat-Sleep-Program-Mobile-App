import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/audio_player_widget.dart';
import '../services/audio_service.dart';
import '../widgets/health_data_widget.dart';
import '../utils/animation_utils.dart';
import 'dart:async';
import 'dart:math';
import '../services/alarm_service.dart';

class SleepPreparationScreen extends StatefulWidget {
  const SleepPreparationScreen({super.key});

  @override
  State<SleepPreparationScreen> createState() => _SleepPreparationScreenState();
}

class _SleepPreparationScreenState extends State<SleepPreparationScreen> {
  final AudioService _audioService = AudioService.instance;
  final AlarmService _alarmService = AlarmService.instance;
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

  // 修改闹钟相关状态
  TimeOfDay _wakeTime = TimeOfDay.now().replacing(hour: 7, minute: 0);
  bool _enableSmartWake = false;
  int _smartWakeWindow = 30;
  final List<int> _smartWakeOptions = [5, 10, 15, 20, 25, 30];
  bool _hasSetAlarm = false;
  DateTime? _scheduledAlarmTime;

  Timer? _countdownTimer;
  final String _alarmTimeKey = 'alarm_time';
  final String _smartWakeKey = 'smart_wake';
  final String _smartWakeWindowKey = 'smart_wake_window';

  @override
  void initState() {
    super.initState();
    _loadAlarmSettings();
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted && _hasSetAlarm) {
        setState(() {});  // 触发重建以更新倒计时显示
      }
    });
  }

  Future<void> _saveAlarmSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (_hasSetAlarm && _scheduledAlarmTime != null) {
      await prefs.setString(_alarmTimeKey, _scheduledAlarmTime!.toIso8601String());
      await prefs.setBool(_smartWakeKey, _enableSmartWake);
      await prefs.setInt(_smartWakeWindowKey, _smartWakeWindow);
    } else {
      await prefs.remove(_alarmTimeKey);
      await prefs.remove(_smartWakeKey);
      await prefs.remove(_smartWakeWindowKey);
    }
  }

  Future<void> _loadAlarmSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final alarmTimeStr = prefs.getString(_alarmTimeKey);
    
    if (alarmTimeStr != null) {
      final alarmTime = DateTime.parse(alarmTimeStr);
      // 如果闹钟时间已过期，则不加载
      if (alarmTime.isAfter(DateTime.now())) {
        setState(() {
          _hasSetAlarm = true;
          _scheduledAlarmTime = alarmTime;
          _wakeTime = TimeOfDay.fromDateTime(alarmTime);
          _enableSmartWake = prefs.getBool(_smartWakeKey) ?? false;
          _smartWakeWindow = prefs.getInt(_smartWakeWindowKey) ?? 30;
        });
        // 重新设置系统闹钟
        await _alarmService.setAlarm(
          wakeTime: alarmTime,
          isSmartWake: _enableSmartWake,
          smartWakeWindow: _enableSmartWake ? _smartWakeWindow : null,
        );
      } else {
        // 清除过期的闹钟设置
        await _saveAlarmSettings();
      }
    }
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
    const sizeStep = (maxSize - minSize) / breathInDuration; // 每秒增加的尺寸

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

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '$hours小时${minutes > 0 ? ' $minutes分钟' : ''}';
    }
    return '$minutes分钟';
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.white.withOpacity(0.15),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  void _setAlarm() async {
    final wakeTime = _wakeTime;
    final now = DateTime.now();
    var wakeDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      wakeTime.hour,
      wakeTime.minute,
    );

    if (wakeDateTime.isBefore(now)) {
      wakeDateTime = wakeDateTime.add(const Duration(days: 1));
    }

    try {
      await _alarmService.setAlarm(
        wakeTime: wakeDateTime,
        isSmartWake: _enableSmartWake,
        smartWakeWindow: _enableSmartWake ? _smartWakeWindow : null,
      );

      setState(() {
        _hasSetAlarm = true;
        _scheduledAlarmTime = wakeDateTime;
      });

      // 保存闹钟设置
      await _saveAlarmSettings();

      _showSnackBar(
        _enableSmartWake 
          ? '已设置智能闹钟,将在${_formatTimeOfDay(wakeTime)}前$_smartWakeWindow分钟内唤醒'
          : '已设置闹钟,将在${_formatTimeOfDay(wakeTime)}唤醒',
      );
    } catch (e) {
      _showSnackBar('设置闹钟失败,请检查权限设置');
    }
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
                      const SizedBox(height: 20),
                      _buildAlarmSettings()
                          .animate()
                          .fadeIn(delay: 400.ms, duration: 500.ms)
                          .slideX(begin: 0.2, end: 0),
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

  Widget _buildAlarmSettings() {
    return GlassmorphicContainer(
      width: double.infinity,
      height: _hasSetAlarm ? 220 : 240,
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '闹钟设置',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_hasSetAlarm)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white),
                    onPressed: () async {
                      await _alarmService.cancelAlarm();
                      setState(() {
                        _hasSetAlarm = false;
                        _scheduledAlarmTime = null;
                      });
                      await _saveAlarmSettings();
                      _showSnackBar('闹钟已删除');
                    },
                  ),
              ],
            ),
            if (_hasSetAlarm) ...[
              const SizedBox(height: 20),
              _buildAlarmInfo(),
            ] else ...[
              const SizedBox(height: 20),
              _buildAlarmSetup(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAlarmInfo() {
    if (_scheduledAlarmTime == null) return const SizedBox();
    
    final now = DateTime.now();
    final duration = _scheduledAlarmTime!.difference(now);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.alarm, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              '闹钟时间: ${_formatTimeOfDay(_wakeTime)}',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            const Icon(Icons.timer_outlined, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              '距离闹钟响起: ${_formatDuration(duration)}',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
        if (_enableSmartWake) ...[
          const SizedBox(height: 15),
          Row(
            children: [
              const Icon(Icons.brightness_auto, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                '智能唤醒: 提前$_smartWakeWindow分钟',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAlarmSetup() {
    return Column(
      children: [
        InkWell(
          onTap: () async {
            final time = await showTimePicker(
              context: context,
              initialTime: _wakeTime,
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    timePickerTheme: TimePickerThemeData(
                      backgroundColor: Colors.grey[900],
                      hourMinuteTextColor: Colors.white,
                      dayPeriodTextColor: Colors.white,
                      dialHandColor: const Color(0xFFFF8FB1),
                      dialBackgroundColor: Colors.grey[800],
                      dialTextColor: Colors.white,
                      entryModeIconColor: Colors.white,
                    ),
                    textButtonTheme: TextButtonThemeData(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (time != null) {
              setState(() => _wakeTime = time);
            }
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '起床时间',
                style: TextStyle(color: Colors.white),
              ),
              Text(
                _formatTimeOfDay(_wakeTime),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  '智能唤醒',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(width: 10),
                if (_enableSmartWake)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: DropdownButton<int>(
                      value: _smartWakeWindow,
                      dropdownColor: const Color(0xFF6B8EFF).withOpacity(0.9),
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                      underline: const SizedBox(),
                      style: const TextStyle(color: Colors.white),
                      items: _smartWakeOptions.map((minutes) {
                        return DropdownMenuItem<int>(
                          value: minutes,
                          child: Text('$minutes分钟'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _smartWakeWindow = value);
                        }
                      },
                    ),
                  ),
              ],
            ),
            Switch(
              value: _enableSmartWake,
              onChanged: (value) => setState(() => _enableSmartWake = value),
              activeColor: Colors.white,
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _setAlarm,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('设置闹钟'),
          ),
        ),
      ],
    );
  }
} 