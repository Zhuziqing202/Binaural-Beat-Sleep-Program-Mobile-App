import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../services/sleep_record_service.dart';
import '../services/dream_record_service.dart';
import '../services/sleep_score_service.dart';
import '../models/dream_record.dart';
import '../models/sleep_record.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dream_diary_screen.dart';
import 'sleep_record_screen.dart';
import 'sleep_records_list_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SleepReportScreen extends StatefulWidget {
  const SleepReportScreen({super.key});

  @override
  State<SleepReportScreen> createState() => _SleepReportScreenState();
}

class _SleepReportScreenState extends State<SleepReportScreen> {
  int _selectedPeriod = 7; // 默认显示7天
  int _selectedWeekOffset = 0; // 添加周偏移量状态
  Map<String, Duration> _sleepData = {};
  bool _isLoading = true;
  DreamRecord? _todaysDream;
  Map<String, double> _stageDurations = {};
  double _sleepScore = 0;
  String _scoreGrade = 'D';
  String _scoreSuggestion = '';

  @override
  void initState() {
    super.initState();
    _loadSleepData();
    _loadTodaysDream();
  }

  Future<void> _loadSleepData() async {
    setState(() => _isLoading = true);

    // 获取最近指定天数的睡眠记录
    final data = await SleepRecordService.instance
        .getRecentRecords(_selectedPeriod, 'day');

    // 获取最新记录的睡眠阶段数据和计算睡眠评分
    final records = await SleepRecordService.instance.getAllRecords();
    Map<String, int>? latestStageDurations;
    double score = 0;
    String grade = 'D';
    String suggestion = '暂无睡眠记录';

    if (records.isNotEmpty) {
      // 获取昨天的日期范围（18:00到今天12:00）
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final startTime =
          DateTime(yesterday.year, yesterday.month, yesterday.day, 18);
      final endTime = DateTime(today.year, today.month, today.day, 12);

      // 筛选这个时间范围内的睡眠记录
      final yesterdaySleepRecords = records.where((record) {
        return record.startTime.isAfter(startTime) &&
            record.startTime.isBefore(endTime);
      }).toList();

      if (yesterdaySleepRecords.isNotEmpty) {
        // 如果有多条记录，选择最长的那条
        final latestRecord = yesterdaySleepRecords.reduce(
            (a, b) => a.duration.inMinutes > b.duration.inMinutes ? a : b);

        latestStageDurations = latestRecord.stageDurations;

        // 计算睡眠评分
        score = SleepScoreService.calculateSleepScore(
          sleepStart: latestRecord.startTime,
          sleepEnd: latestRecord.endTime,
          efficiency: latestRecord.sleepEfficiency,
        );
        grade = SleepScoreService.getScoreGrade(score);
        suggestion = SleepScoreService.getScoreSuggestion(score);
      }
    }

    setState(() {
      _sleepData = data;
      _stageDurations = latestStageDurations
              ?.map((key, value) => MapEntry(key, value.toDouble())) ??
          {};
      _sleepScore = score;
      _scoreGrade = grade;
      _scoreSuggestion = suggestion;
      _isLoading = false;
    });
  }

  Future<void> _loadTodaysDream() async {
    final dream =
        await DreamRecordService.instance.getLatestDreamForDate(DateTime.now());
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
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Container(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios,
                                  color: Colors.white),
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
                        const SizedBox(height: 16),
                        _buildStatisticsCard(),
                        const SizedBox(height: 10),
                        _buildSleepChart(),
                        const SizedBox(height: 10),
                        _buildViewDetailsButton(),
                        const SizedBox(height: 10),
                        _buildDreamCard(),
                        const SizedBox(height: 90),
                      ],
                    ),
                  ),
                ),
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

  Widget _buildStatisticsCard() {
    return FutureBuilder<List<SleepRecord>>(
      future: SleepRecordService.instance.getAllRecords(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 100);
        }

        // 获取选定周的日期范围
        final now = DateTime.now();
        final weekStart =
            now.subtract(Duration(days: 7 * _selectedWeekOffset + 6));
        final weekEnd = weekStart.add(const Duration(days: 6));

        // 筛选该周的睡眠记录
        final weekRecords = snapshot.data!.where((record) {
          return record.startTime.isAfter(weekStart) &&
              record.startTime.isBefore(weekEnd.add(const Duration(days: 1)));
        }).toList();

        // 计算平均睡眠时长
        double avgDuration = 0;
        if (weekRecords.isNotEmpty) {
          final totalMinutes = weekRecords.fold<int>(
              0, (sum, record) => sum + record.duration.inMinutes);
          avgDuration = totalMinutes / (60.0 * weekRecords.length);
        }

        // 计算平均入睡时间
        String avgBedtime = '--:--';
        if (weekRecords.isNotEmpty) {
          final totalMinutes = weekRecords.fold<int>(0, (sum, record) {
            final hour = record.startTime.hour;
            final minute = record.startTime.minute;
            // 如果时间在凌晨,加24小时来计算平均值
            final adjustedHour = hour < 12 ? hour + 24 : hour;
            return sum + (adjustedHour * 60 + minute);
          });
          final avgMinutes = totalMinutes ~/ weekRecords.length;
          final avgHour = (avgMinutes ~/ 60) % 24;
          final avgMinute = avgMinutes % 60;
          avgBedtime =
              '${avgHour.toString().padLeft(2, '0')}:${avgMinute.toString().padLeft(2, '0')}';
        }

        // 计算平均得分
        double avgScore = 0;
        if (weekRecords.isNotEmpty) {
          final totalScore = weekRecords.fold<double>(0, (sum, record) {
            return sum +
                SleepScoreService.calculateSleepScore(
                  sleepStart: record.startTime,
                  sleepEnd: record.endTime,
                  efficiency: record.sleepEfficiency,
                );
          });
          avgScore = totalScore / weekRecords.length;
        }

        return GlassmorphicContainer(
          width: double.infinity,
          height: 100,
          borderRadius: 15,
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('平均时长', '${avgDuration.toStringAsFixed(1)}h',
                    Icons.access_time),
                _buildStatItem('入睡时间', avgBedtime, Icons.nightlight),
                _buildStatItem('平均得分', avgScore.toStringAsFixed(0), Icons.star),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSleepChart() {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 220,
      borderRadius: 15,
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
        padding: const EdgeInsets.all(16),
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
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _selectedWeekOffset++;
                        });
                      },
                    ),
                    IconButton(
                      icon:
                          const Icon(Icons.chevron_right, color: Colors.white),
                      onPressed: _selectedWeekOffset > 0
                          ? () {
                              setState(() {
                                _selectedWeekOffset--;
                              });
                            }
                          : null,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: FutureBuilder<List<SleepRecord>>(
                future: SleepRecordService.instance.getAllRecords(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    );
                  }

                  // 获取选定周的日期范围
                  final now = DateTime.now();
                  final weekStart =
                      now.subtract(Duration(days: 7 * _selectedWeekOffset + 6));
                  final dates = List.generate(7, (index) {
                    return weekStart.add(Duration(days: index));
                  });

                  // 为每一天计算睡眠时长
                  final spots = dates.asMap().entries.map((entry) {
                    final date = entry.value;
                    // 修改日期范围计算：当天18:00到次日12:00
                    final dayStart =
                        DateTime(date.year, date.month, date.day, 18);
                    final dayEnd = date.add(const Duration(days: 1, hours: 12));

                    // 只统计在这个时间范围内开始的睡眠记录
                    final dayRecords = snapshot.data!.where((record) {
                      return record.startTime.isAfter(dayStart) &&
                          record.startTime.isBefore(dayEnd) &&
                          record.date ==
                              SleepRecord.getDateString(date); // 确保日期匹配
                    }).toList();

                    double sleepHours = 0;
                    if (dayRecords.isNotEmpty) {
                      final longestRecord = dayRecords.reduce((a, b) =>
                          a.duration.inMinutes > b.duration.inMinutes ? a : b);
                      sleepHours = longestRecord.duration.inMinutes / 60.0;
                    }

                    return FlSpot(entry.key.toDouble(), sleepHours);
                  }).toList();

                  return LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value % 2 == 0) {
                                return Text(
                                  '${value.toInt()}h',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                );
                              }
                              return const Text('');
                            },
                            reservedSize: 30,
                          ),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              final intValue = value.toInt();
                              if (intValue >= 0 && intValue < dates.length) {
                                final date = dates[intValue];
                                return Text(
                                  '${date.month}/${date.day}',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: 6,
                      minY: 0,
                      maxY: 12,
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          curveSmoothness: 0.2,
                          preventCurveOverShooting: true,
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
                            cutOffY: 0,
                            applyCutOffY: true,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 200.ms);
  }

  Widget _buildSleepStagesCard() {
    if (_sleepData.isEmpty) return const SizedBox.shrink();

    // 获取最新的睡眠记录
    final latestDate =
        _sleepData.keys.reduce((a, b) => a.compareTo(b) > 0 ? a : b);
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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DreamDiaryScreen(
              initialDreamId: _todaysDream?.id,
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
              padding: const EdgeInsets.all(16),
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
                  const SizedBox(height: 12),
                  if (_todaysDream == null)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '还没有记录昨晚的梦境呢~',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Text(
                              '记录梦境不仅能帮助你更好地了解自己的内心世界,还能发现生活中被忽略的灵感哦！点击这里开始记录吧 ✨',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Expanded(
                      child: Column(
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
                          const SizedBox(height: 8),
                          Text(
                            _todaysDream!.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Text(
                              _todaysDream!.content,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
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
      height: 50,
      borderRadius: 25,
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
          borderRadius: BorderRadius.circular(25),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '查看详细数据',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 14,
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
