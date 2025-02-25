import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../services/health_service.dart';
import '../services/sleep_record_service.dart';
import '../models/sleep_record.dart';

class HealthDataWidget extends StatefulWidget {
  final DateTime date;

  const HealthDataWidget({
    super.key,
    required this.date,
  });

  @override
  State<HealthDataWidget> createState() => _HealthDataWidgetState();
}

class _HealthDataWidgetState extends State<HealthDataWidget> {
  final HealthService _healthService = HealthService.instance;
  final SleepRecordService _sleepRecordService = SleepRecordService.instance;
  Map<String, dynamic> _healthData = {};
  bool _isLoading = true;
  bool _hasPermission = false;
  List<SleepRecord> _weekRecords = [];

  @override
  void initState() {
    super.initState();
    _checkPermissionAndLoadData();
    _loadWeekData();
  }

  Future<void> _checkPermissionAndLoadData() async {
    final hasPermission = await _healthService.hasHealthData();
    setState(() {
      _hasPermission = hasPermission;
    });

    if (_hasPermission) {
      await _loadHealthData();
    }
  }

  Future<void> _loadHealthData() async {
    setState(() {
      _isLoading = true;
    });

    final data = await _healthService.getSleepData(widget.date);

    setState(() {
      _healthData = data;
      _isLoading = false;
    });
  }

  Future<void> _requestPermission() async {
    final granted = await _healthService.requestPermissions();
    if (granted) {
      setState(() {
        _hasPermission = true;
      });
      await _loadHealthData();
    }
  }

  Future<void> _loadWeekData() async {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    final records = await _sleepRecordService.getAllRecords();
    final weekRecords = records.where((record) {
      return record.startTime.isAfter(weekAgo) &&
          record.startTime.isBefore(now);
    }).toList();

    setState(() {
      _weekRecords = weekRecords;
    });
  }

  String _getAverageSleepDuration() {
    if (_weekRecords.isEmpty) return '暂无数据';

    final totalMinutes = _weekRecords.fold<int>(
      0,
      (sum, record) => sum + record.duration.inMinutes,
    );
    final averageMinutes = totalMinutes ~/ _weekRecords.length;
    final hours = averageMinutes ~/ 60;
    final minutes = averageMinutes % 60;

    return '$hours小时$minutes分钟';
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '睡眠数据',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '本周平均睡眠时长',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getAverageSleepDuration(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
