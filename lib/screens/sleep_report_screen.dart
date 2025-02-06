import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../services/sleep_record_service.dart';
import '../services/dream_record_service.dart';
import '../models/dream_record.dart';
import '../models/sleep_record.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dream_diary_screen.dart';
import 'sleep_record_screen.dart';

class SleepReportScreen extends StatefulWidget {
  const SleepReportScreen({super.key});

  @override
  State<SleepReportScreen> createState() => _SleepReportScreenState();
}

class _SleepReportScreenState extends State<SleepReportScreen> {
  int _selectedPeriod = 7; // 默认显示7天
  Map<String, Duration> _sleepData = {};
  bool _isLoading = true;
  DreamRecord? _todaysDream;

  @override
  void initState() {
    super.initState();
    _loadSleepData();
    _loadTodaysDream();
  }

  Future<void> _loadSleepData() async {
    setState(() => _isLoading = true);
    final data = await SleepRecordService.instance.getRecentRecords(
      _selectedPeriod,
      _selectedPeriod <= 31 ? 'day' : _selectedPeriod <= 365 ? 'month' : 'year'
    );
    setState(() {
      _sleepData = data;
      _isLoading = false;
    });
  }

  Future<void> _loadTodaysDream() async {
    final dream = await DreamRecordService.instance.getLatestDreamForDate(DateTime.now());
    setState(() {
      _todaysDream = dream;
    });
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final decimalHours = hours + (minutes / 60);
    return decimalHours.toStringAsFixed(2);
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
          child: Stack(
            children: [
              Column(
                children: [
                  _buildAppBar(context),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildPeriodSelector(),
                          const SizedBox(height: 20),
                          _buildSleepDurationChart(),
                          const SizedBox(height: 20),
                          _buildSleepStagesCard(),
                          const SizedBox(height: 20),
                          _buildDreamRecord(),
                          const SizedBox(height: 20),
                          _buildMoodAnalysis(),
                          const SizedBox(height: 20),
                          _buildAIAnalysis(),
                          const SizedBox(height: 80), // 为底部按钮留出空间
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                right: 20,
                bottom: 20,
                child: _buildAddRecordButton(),
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
            '睡眠报告',
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

  Widget _buildPeriodSelector() {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 60,
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
          _buildPeriodButton('周', 7),
          _buildPeriodButton('月', 30),
          _buildPeriodButton('年', 365),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String text, int days) {
    final isSelected = _selectedPeriod == days;
    return TextButton(
      onPressed: () {
        setState(() => _selectedPeriod = days);
        _loadSleepData();
      },
      style: TextButton.styleFrom(
        backgroundColor: isSelected ? Colors.white.withOpacity(0.3) : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildSleepDurationChart() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      );
    }

    String getXAxisLabel(String key) {
      if (_selectedPeriod <= 31) {
        // 日视图：显示"月-日"
        return key.substring(5);
      } else if (_selectedPeriod <= 365) {
        // 月视图：显示"年-月"
        return key.substring(0, 7);
      } else {
        // 年视图：显示年份
        return key;
      }
    }

    return GlassmorphicContainer(
      width: double.infinity,
      height: 300,
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
            const Text(
              '睡眠时长趋势',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toStringAsFixed(1)}h',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < _sleepData.keys.length) {
                            final key = _sleepData.keys.elementAt(index);
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                getXAxisLabel(key),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _sleepData.entries.map((e) {
                        final hours = e.value.inHours.toDouble() + (e.value.inMinutes % 60) / 60;
                        return FlSpot(
                          _sleepData.keys.toList().indexOf(e.key).toDouble(),
                          double.parse(hours.toStringAsFixed(2)),
                        );
                      }).toList(),
                      isCurved: true,
                      color: Colors.white,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.white,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ],
                  minY: 0,
                  maxY: 12, // 最大12小时
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSleepStagesCard() {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 200,
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
            const Text(
              '睡眠阶段分析',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildStageProgressBar('深度睡眠', 0.3),
            const SizedBox(height: 10),
            _buildStageProgressBar('浅度睡眠', 0.5),
            const SizedBox(height: 10),
            _buildStageProgressBar('快速眼动', 0.2),
          ],
        ),
      ),
    );
  }

  Widget _buildStageProgressBar(String title, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 5),
        LinearProgressIndicator(
          value: value,
          backgroundColor: Colors.white.withOpacity(0.2),
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ],
    );
  }

  Widget _buildDreamRecord() {
    return GestureDetector(
      onTap: _todaysDream == null ? null : () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DreamDiaryScreen(
              initialDreamId: _todaysDream!.id,
            ),
          ),
        );
      },
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 160,
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
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '昨晚的梦',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_todaysDream != null)
                        Text(
                          DateFormat('HH:mm').format(_todaysDream!.date),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  if (_todaysDream == null)
                    const Center(
                      child: Text(
                        '今天还没有记录梦境',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _getMoodIcon(_todaysDream!.mood),
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _getMoodText(_todaysDream!.mood),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _todaysDream!.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                ],
              ),
            ),
            if (_todaysDream != null)
              Positioned(
                right: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white.withOpacity(0.7),
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getMoodIcon(int mood) {
    if (mood <= -60) {
      return Icons.sentiment_very_dissatisfied;
    } else if (mood <= -20) {
      return Icons.sentiment_dissatisfied;
    } else if (mood < 20) {
      return Icons.sentiment_neutral;
    } else if (mood < 60) {
      return Icons.sentiment_satisfied;
    } else {
      return Icons.sentiment_very_satisfied;
    }
  }

  String _getMoodText(int mood) {
    if (mood <= -60) {
      return '非常消极的梦';
    } else if (mood <= -20) {
      return '消极的梦';
    } else if (mood < 20) {
      return '中性的梦';
    } else if (mood < 60) {
      return '积极的梦';
    } else {
      return '非常积极的梦';
    }
  }

  Widget _buildMoodAnalysis() {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 150,
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
            const Text(
              '心情分析',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMoodItem(Icons.sentiment_very_satisfied, '起床心情', '愉悦'),
                _buildMoodItem(Icons.nightlight, '睡眠质量', '良好'),
                _buildMoodItem(Icons.battery_charging_full, '精力充沛', '90%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodItem(IconData icon, String title, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 5),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAIAnalysis() {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 150,
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
              children: [
                const Icon(Icons.psychology, color: Colors.white),
                const SizedBox(width: 10),
                const Text(
                  'AI 睡眠建议',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Pro',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            const Text(
              '根据您的睡眠数据分析，建议调整入睡时间至22:30，并在睡前30分钟进行冥想放松。',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddRecordButton() {
    return GlassmorphicContainer(
      width: 60,
      height: 60,
      borderRadius: 30,
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
        child: InkWell(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SleepRecordScreen(),
              ),
            );
            if (result == true) {
              _loadSleepData();
            }
          },
          borderRadius: BorderRadius.circular(30),
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 30,
          ),
        ),
      ),
    );
  }
} 