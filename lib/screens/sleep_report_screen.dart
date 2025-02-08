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
import 'sleep_records_list_screen.dart';

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
  Map<String, double> _stageDurations = {};

  @override
  void initState() {
    super.initState();
    _loadSleepData();
    _loadTodaysDream();
  }

  Future<void> _loadSleepData() async {
    setState(() => _isLoading = true);
    
    // 获取最近指定天数的睡眠记录
    final data = await SleepRecordService.instance.getRecentRecords(_selectedPeriod, 'day');
    
    // 获取最新记录的睡眠阶段数据
    final records = await SleepRecordService.instance.getAllRecords();
    Map<String, int>? latestStageDurations;
    if (records.isNotEmpty) {
      final latestRecord = records.reduce((a, b) => 
        a.startTime.isAfter(b.startTime) ? a : b
      );
      latestStageDurations = latestRecord.stageDurations;
    }

    setState(() {
      _sleepData = data;
      _stageDurations = latestStageDurations?.map(
        (key, value) => MapEntry(key, value.toDouble())
      ) ?? {};
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
    final hours = duration.inHours.toDouble();
    final minutes = duration.inMinutes.remainder(60) / 60;
    final decimalHours = hours + minutes;
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
                  if (_isLoading)
                    const Expanded(
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _buildSleepChart(),
                            const SizedBox(height: 20),
                            _buildViewDetailsButton(),
                            const SizedBox(height: 20),
                            _buildSleepStagesCard(),
                            const SizedBox(height: 20),
                            if (_todaysDream != null) _buildDreamCard(),
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

  Widget _buildSleepChart() {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '睡眠时长趋势',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildPeriodSelector(),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _buildChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPeriodButton('7天', 7),
        const SizedBox(width: 10),
        _buildPeriodButton('30天', 30),
        const SizedBox(width: 10),
        _buildPeriodButton('90天', 90),
      ],
    );
  }

  Widget _buildPeriodButton(String text, int days) {
    final isSelected = _selectedPeriod == days;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = days;
        });
        _loadSleepData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Colors.white.withOpacity(isSelected ? 0.5 : 0.3),
            width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
            color: Colors.white.withOpacity(isSelected ? 1 : 0.7),
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildChart() {
    if (_sleepData.isEmpty) {
      return const Center(
        child: Text(
          '暂无数据',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      );
    }

    final List<FlSpot> spots = [];
    var index = 0.0;
    
    _sleepData.forEach((date, duration) {
      final hours = double.parse(_formatDuration(duration));
      if (hours > 0) {
        spots.add(FlSpot(index, hours));
      }
      index++;
    });

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 2,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.white.withOpacity(0.1),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                if (value % 1 != 0) return const Text('');
                final index = value.toInt();
                if (index >= _sleepData.length) return const Text('');
                
                final date = DateTime.now().subtract(
                  Duration(days: _sleepData.length - 1 - index),
                );
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat('dd').format(date),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                    ),
                            ),
                          );
                        },
                      ),
                    ),
          leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
              interval: 2,
                        getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                              ),
                            );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (_sleepData.length - 1).toDouble(),
        minY: 0,
        maxY: 12,
                  lineBarsData: [
                    LineChartBarData(
            spots: spots,
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
                  strokeWidth: 1,
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
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.white.withOpacity(0.8),
            tooltipRoundedRadius: 8,
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                return LineTooltipItem(
                  '${barSpot.y.toStringAsFixed(1)}小时',
                  const TextStyle(
                    color: Color(0xFF6B8EFF),
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSleepStagesCard() {
    if (_sleepData.isEmpty) return const SizedBox.shrink();

    // 获取最新的睡眠记录
    final latestDate = _sleepData.keys.reduce((a, b) => a.compareTo(b) > 0 ? a : b);
    final latestRecord = _sleepData[latestDate];
    if (latestRecord == null) return const SizedBox.shrink();

    // 计算各阶段占比
    final totalSeconds = latestRecord.inSeconds;
    if (totalSeconds == 0) return const SizedBox.shrink();

    final Map<String, double> stageRatios = {};
    for (var entry in _stageDurations.entries) {
      stageRatios[entry.key] = entry.value / totalSeconds;
    }

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
              '睡眠阶段',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildStageProgressBar('深度睡眠', stageRatios['deep'] ?? 0),
            const SizedBox(height: 15),
            _buildStageProgressBar('浅度睡眠', stageRatios['core'] ?? 0),
            const SizedBox(height: 15),
            _buildStageProgressBar('快速眼动', stageRatios['rem'] ?? 0),
          ],
        ),
      ),
    );
  }

  Widget _buildStageProgressBar(String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            Text(
              '${(value * 100).round()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            widthFactor: value,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDreamCard() {
    return GestureDetector(
      onTap: () {
        if (_todaysDream != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DreamDiaryScreen(initialDreamId: _todaysDream!.id),
            ),
          );
        }
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

  Widget _buildMoodAnalysis() {
    if (_sleepData.isEmpty) return const SizedBox.shrink();

    return FutureBuilder<List<SleepRecord>>(
      future: SleepRecordService.instance.getAllRecords(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        // 获取最新记录
        final latestRecord = snapshot.data!.reduce(
          (a, b) => a.startTime.isAfter(b.startTime) ? a : b
        );

        return GlassmorphicContainer(
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
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '睡眠质量',
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
                    _buildMoodIndicator('睡眠效率', latestRecord.sleepEfficiency, Icons.nightlight_round),
                    _buildMoodIndicator(
                      '深睡占比', 
                      latestRecord.stageDurations['deep']?.toDouble() ?? 0 / latestRecord.duration.inSeconds,
                      Icons.bedtime
                    ),
                    _buildMoodIndicator(
                      'REM占比', 
                      latestRecord.stageDurations['rem']?.toDouble() ?? 0 / latestRecord.duration.inSeconds,
                      Icons.remove_red_eye
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMoodIndicator(String label, double value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${(value * 100).round()}%',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAIAnalysis() {
    return GlassmorphicContainer(
      width: double.infinity,
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.psychology,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'AI 睡眠建议',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              '根据您最近的睡眠数据分析，建议：\n1. 尝试在22:30前入睡\n2. 保持规律的作息时间\n3. 睡前30分钟避免使用电子设备',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
                height: 1.5,
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

  Widget _buildViewDetailsButton() {
    return GlassmorphicContainer(
      width: double.infinity,
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
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SleepRecordsListScreen(),
              ),
            ).then((_) => _loadSleepData());
          },
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '查看详细数据',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getMoodIcon(int mood) {
    if (mood > 50) {
      return Icons.sentiment_very_satisfied;
    } else if (mood > 0) {
      return Icons.sentiment_satisfied;
    } else if (mood < -50) {
      return Icons.sentiment_very_dissatisfied;
    } else if (mood < 0) {
      return Icons.sentiment_dissatisfied;
    }
    return Icons.sentiment_neutral;
  }

  String _getMoodText(int mood) {
    if (mood > 50) {
      return '非常愉快';
    } else if (mood > 0) {
      return '愉快';
    } else if (mood < -50) {
      return '非常烦躁';
    } else if (mood < 0) {
      return '烦躁';
    }
    return '平静';
  }
} 