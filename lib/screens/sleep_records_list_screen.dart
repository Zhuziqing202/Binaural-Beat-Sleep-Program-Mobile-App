import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../models/sleep_record.dart';
import '../services/sleep_record_service.dart';
import 'sleep_record_screen.dart';

class SleepRecordsListScreen extends StatefulWidget {
  const SleepRecordsListScreen({super.key});

  @override
  State<SleepRecordsListScreen> createState() => _SleepRecordsListScreenState();
}

class _SleepRecordsListScreenState extends State<SleepRecordsListScreen> {
  final _sleepRecordService = SleepRecordService.instance;
  List<SleepRecord> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    final records = await _sleepRecordService.getAllRecords();
    setState(() {
      _records = records;
      _isLoading = false;
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
              Padding(
                padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
                      icon:
                          const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
                      '睡眠日记',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
              ),
              if (_isLoading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
              ),
                )
              else if (_records.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      '暂无睡眠记录',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 16,
                      ),
                    ),
                    ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _records.length,
                    itemBuilder: (context, index) {
                      final record = _records[index];
                      return _buildRecordCard(record);
                    },
                        ),
                      ),
                    ],
                  ),
        ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SleepRecordScreen(),
          ),
        );
          _loadRecords();
        },
        backgroundColor: Colors.white.withOpacity(0.2),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildRecordCard(SleepRecord record) {
    final startTime = DateFormat('MM/dd HH:mm').format(record.startTime);
    final endTime = DateFormat('MM/dd HH:mm').format(record.endTime);
    final duration = record.duration;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SleepRecordScreen(record: record),
            ),
          ).then((_) => _loadRecords());
      },
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 120,
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
                  Text(
                      '睡眠时长：${hours}小时${minutes}分钟',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                        '${(record.sleepEfficiency * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
                const SizedBox(height: 8),
                Text(
                  '开始时间：$startTime',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                  ),
                const SizedBox(height: 4),
                  Text(
                  '结束时间：$endTime',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms);
  }
} 
