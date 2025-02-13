import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/audio_service.dart';
import '../services/sleep_record_service.dart';
import '../models/sleep_record.dart';
import 'dart:async';
import '../services/sleep_stage_service.dart';

class SleepingScreen extends StatefulWidget {
  const SleepingScreen({super.key});

  @override
  State<SleepingScreen> createState() => _SleepingScreenState();
}

class _SleepingScreenState extends State<SleepingScreen> {
  final AudioService _audioService = AudioService.instance;
  final SleepStageService _stageService = SleepStageService.instance;
  int _selectedMode = 0; // 0: 睡眠阶段, 1: 预设周期, 2: 频段选择
  double _volume = 0.7; // 默认音量
  DateTime _startTime = DateTime.now();
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  bool _isCustomMode = false;
  bool _isCustomExpanded = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _startSleepMonitoring();
    _audioService.setSleepStartTime(DateTime.now());
    _audioService.startPresetCycle();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsed = DateTime.now().difference(_startTime);
      });
    });
  }

  void _startSleepMonitoring() {
    _startTime = DateTime.now();
    _stageService.startMonitoring();
  }

  Future<void> _stopSleepMonitoring() async {
    _timer?.cancel();
    _stageService.stopMonitoring();

    // 获取睡眠阶段数据
    final stageDurations = _stageService.getStagesDuration();
    final metrics = _stageService.getSleepQualityMetrics();

    // 创建睡眠记录
    final record = SleepRecord(
      startTime: _startTime,
      endTime: DateTime.now(),
      duration: _elapsed,
      date: SleepRecord.getDateString(_startTime),
      stageDurations: {
        'awake': stageDurations[SleepStage.awake]?.inSeconds ?? 0,
        'core': stageDurations[SleepStage.core]?.inSeconds ?? 0,
        'deep': stageDurations[SleepStage.deep]?.inSeconds ?? 0,
        'rem': stageDurations[SleepStage.rem]?.inSeconds ?? 0,
      },
      sleepEfficiency: metrics['sleepEfficiency'] ?? 0.0,
    );

    // 保存记录
    await SleepRecordService.instance.saveSleepRecord(record);

    await _audioService.stopPresetSound();
    await _audioService.stopCustomSound();
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioService.stopPresetSound();
    _audioService.stopCustomSound();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final standardFontSize = screenWidth * 0.045;

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
          bottom: false,
          child: SingleChildScrollView(
            child: Container(
              constraints: BoxConstraints(
                minHeight: screenHeight - MediaQuery.of(context).padding.top,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildAppBar(context, standardFontSize),
                    SizedBox(height: screenHeight * 0.04),
                    _buildTimeDisplay(standardFontSize),
                    SizedBox(height: screenHeight * 0.06),
                    _buildAudioControl(standardFontSize),
                    SizedBox(height: screenHeight * 0.02),
                    _buildVolumeControl(standardFontSize),
                    SizedBox(height: screenHeight * 0.06),
                    _buildEndButton(standardFontSize),
                    SizedBox(height: screenHeight * 0.04),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, double standardFontSize) {
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back_ios,
              color: Colors.white, size: standardFontSize),
          onPressed: () => Navigator.pop(context),
        ),
        Text(
          '睡眠中',
          style: TextStyle(
            color: Colors.white,
            fontSize: standardFontSize * 1.2,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeDisplay(double standardFontSize) {
    return Column(
      children: [
        Text(
          _formatDuration(_elapsed),
          style: TextStyle(
            color: Colors.white,
            fontSize: standardFontSize * 3,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        SizedBox(height: standardFontSize * 0.5),
        Text(
          '已入睡时长',
          style: TextStyle(
            color: Colors.white,
            fontSize: standardFontSize * 0.9,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildAudioControl(double standardFontSize) {
    return Column(
      children: [
        // 睡眠计划卡片
        GlassmorphicContainer(
          width: double.infinity,
          height: standardFontSize * 8,
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
              Padding(
                padding: EdgeInsets.symmetric(horizontal: standardFontSize),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '睡眠计划',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: standardFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Switch(
                      value: _audioService.isPresetMode,
                      onChanged: (value) {
                        if (value) {
                          _audioService.startPresetCycle();
                        } else {
                          _audioService.stopPresetSound();
                        }
                        setState(() {});
                      },
                      activeColor: Colors.white,
                      inactiveTrackColor: Colors.white.withOpacity(0.3),
                    ),
                  ],
                ),
              ),
              SizedBox(height: standardFontSize),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: standardFontSize * 2),
                child: Text(
                  '脑波同步技术通过特定频率的声波刺激，帮助大脑进入理想的睡眠状态。随着睡眠的深入，音频将自动调整以匹配您的睡眠周期。',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: standardFontSize * 0.7,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),

        SizedBox(height: standardFontSize),

        // 自定义音频卡片
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height:
              _isCustomExpanded ? standardFontSize * 12 : standardFontSize * 4,
          child: GlassmorphicContainer(
            width: double.infinity,
            height: _isCustomExpanded
                ? standardFontSize * 12
                : standardFontSize * 4,
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
            child: Material(
              color: Colors.transparent,
              child: AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                crossFadeState: _isCustomExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: Padding(
                  padding: EdgeInsets.symmetric(horizontal: standardFontSize),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '自定义音频',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: standardFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Switch(
                        value: _isCustomExpanded,
                        onChanged: (value) {
                          setState(() {
                            _isCustomExpanded = value;
                          });
                        },
                        activeColor: Colors.white,
                        inactiveTrackColor: Colors.white.withOpacity(0.3),
                      ),
                    ],
                  ),
                ),
                secondChild: Column(
                  children: [
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: standardFontSize),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '自定义音频',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: standardFontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Switch(
                            value: _isCustomExpanded,
                            onChanged: (value) {
                              setState(() {
                                _isCustomExpanded = value;
                              });
                            },
                            activeColor: Colors.white,
                            inactiveTrackColor: Colors.white.withOpacity(0.3),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 3,
                        padding: EdgeInsets.all(standardFontSize * 0.5),
                        mainAxisSpacing: standardFontSize * 0.2,
                        crossAxisSpacing: standardFontSize * 0.2,
                        childAspectRatio: 1.5,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildAudioButton('海浪声', 'ocean.mp3', Icons.waves),
                          _buildAudioButton('雨声', 'rain.mp3', Icons.water_drop),
                          _buildAudioButton(
                              '白噪音', 'white_noise.mp3', Icons.noise_aware),
                          _buildAudioButton('森林', 'forest.mp3', Icons.forest),
                          _buildAudioButton('溪流', 'stream.mp3', Icons.water),
                          _buildAudioButton(
                              '篝火', 'fire.mp3', Icons.local_fire_department),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),
      ],
    );
  }

  Widget _buildAudioButton(String label, String audioPath, IconData icon) {
    final bool isPlaying = _audioService.isCustomPlaying &&
        _audioService.currentCustomSound == audioPath;

    return GestureDetector(
      onTap: () => _toggleCustomSound(audioPath),
      child: Container(
        decoration: BoxDecoration(
          color: isPlaying
              ? Colors.white.withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withOpacity(isPlaying ? 0.5 : 0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPlaying ? Icons.pause : icon,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVolumeControl(double standardFontSize) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: standardFontSize * 5,
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.music_note, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  '音量控制',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: standardFontSize * 0.8,
                  ),
                ),
                const Spacer(),
                Text(
                  '音量控制切换',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: standardFontSize * 0.7,
                  ),
                ),
                Switch(
                  value: _isCustomMode,
                  onChanged: (value) {
                    setState(() {
                      _isCustomMode = value;
                    });
                  },
                  activeColor: Colors.white,
                  inactiveTrackColor: Colors.white.withOpacity(0.3),
                ),
              ],
            ),
          ),
          Row(
            children: [
              const SizedBox(width: 20),
              const Icon(Icons.volume_down, color: Colors.white, size: 20),
              Expanded(
                child: Slider(
                  value: _isCustomMode
                      ? _audioService.customVolume
                      : _audioService.presetVolume,
                  onChanged: (value) {
                    if (_isCustomMode) {
                      _audioService.setCustomVolume(value);
                    } else {
                      _audioService.setPresetVolume(value);
                    }
                    setState(() {});
                  },
                  activeColor: Colors.white,
                  inactiveColor: Colors.white.withOpacity(0.3),
                ),
              ),
              const Icon(Icons.volume_up, color: Colors.white, size: 20),
              const SizedBox(width: 20),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEndButton(double standardFontSize) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: GlassmorphicContainer(
              width: standardFontSize * 15,
              height: standardFontSize * 10,
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
                  Padding(
                    padding: EdgeInsets.all(standardFontSize),
                    child: Text(
                      '确认结束睡眠',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: standardFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: standardFontSize),
                    child: Text(
                      '确定要结束本次睡眠记录吗？',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: standardFontSize * 0.8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: standardFontSize),
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
                            fontSize: standardFontSize * 0.8,
                          ),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: standardFontSize,
                        color: Colors.white24,
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _stopSleepMonitoring();
                        },
                        child: Text(
                          '确定',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: standardFontSize * 0.8,
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
      child: Column(
        children: [
          Container(
            width: standardFontSize * 4,
            height: standardFontSize * 4,
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
            child: Icon(
              Icons.stop_rounded,
              color: Colors.white,
              size: standardFontSize * 2,
            ),
          )
              .animate(
                onPlay: (controller) => controller.repeat(reverse: true),
              )
              .scale(
                duration: 2.seconds,
                begin: const Offset(1, 1),
                end: const Offset(1.1, 1.1),
                curve: Curves.easeInOut,
              ),
          SizedBox(height: standardFontSize * 0.5),
          Text(
            '结束睡眠',
            style: TextStyle(
              color: Colors.white,
              fontSize: standardFontSize * 0.8,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepPlanStatus(double standardFontSize) {
    final currentPhase = _getCurrentSleepPhase();
    final phaseIcon = _getSleepPhaseIcon(currentPhase);
    final phaseName = _getSleepPhaseName(currentPhase);

    return Container(
      padding: EdgeInsets.all(standardFontSize),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: standardFontSize * 4,
            height: standardFontSize * 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
              border: Border.all(
                color: Colors.white,
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  phaseIcon,
                  color: Colors.white,
                  size: standardFontSize * 1.5,
                ),
                SizedBox(height: standardFontSize * 0.3),
                Text(
                  phaseName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: standardFontSize * 0.7,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
              .animate(
                onPlay: (controller) => controller.repeat(reverse: true),
              )
              .scale(
                duration: 3.seconds,
                begin: const Offset(1, 1),
                end: const Offset(1.05, 1.05),
                curve: Curves.easeInOut,
              ),
        ],
      ),
    );
  }

  String _getCurrentSleepPhase() {
    final elapsedMinutes = _elapsed.inMinutes;
    final currentCycle = (elapsedMinutes ~/ 90);
    final phaseInCycle = ((elapsedMinutes % 90) ~/ 22.5).toInt();

    switch (phaseInCycle) {
      case 0:
        return 'N1';
      case 1:
        return 'N2';
      case 2:
        return 'N3';
      case 3:
        return 'REM';
      default:
        return 'N1';
    }
  }

  IconData _getSleepPhaseIcon(String phase) {
    switch (phase) {
      case 'N1':
        return Icons.waves;
      case 'N2':
        return Icons.waves_outlined;
      case 'N3':
        return Icons.water;
      case 'REM':
        return Icons.remove_red_eye;
      default:
        return Icons.waves;
    }
  }

  String _getSleepPhaseName(String phase) {
    switch (phase) {
      case 'N1':
        return '浅睡期';
      case 'N2':
        return '中睡期';
      case 'N3':
        return '深睡期';
      case 'REM':
        return '快速眼动';
      default:
        return '浅睡期';
    }
  }

  void _toggleCustomSound(String audioPath) async {
    if (_audioService.isCustomPlaying &&
        _audioService.currentCustomSound == audioPath) {
      await _audioService.stopCustomSound();
    } else {
      await _audioService.playCustomSound(audioPath);
    }
    setState(() {});
  }
}
