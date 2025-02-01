import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../services/health_service.dart';

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
  Map<String, dynamic> _healthData = {};
  bool _isLoading = true;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionAndLoadData();
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

  @override
  Widget build(BuildContext context) {
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
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.health_and_safety, color: Colors.white),
                const SizedBox(width: 10),
                const Text(
                  '健康数据',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (!_hasPermission)
                  TextButton(
                    onPressed: _requestPermission,
                    child: const Text(
                      '同步健康数据',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 15),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else if (_hasPermission && _healthData.isNotEmpty)
              Expanded(
                child: Row(
                  children: [
                    _buildDataItem(
                      icon: Icons.bedtime,
                      title: '总睡眠',
                      value: '${(_healthData['totalSleepTime'] / 60).toStringAsFixed(1)}小时',
                    ),
                    _buildDataItem(
                      icon: Icons.nightlight,
                      title: '深睡',
                      value: '${(_healthData['deepSleepTime'] / 60).toStringAsFixed(1)}小时',
                    ),
                    _buildDataItem(
                      icon: Icons.favorite,
                      title: '心率',
                      value: '${_healthData['averageHeartRate'].toStringAsFixed(0)}次/分',
                    ),
                    _buildDataItem(
                      icon: Icons.air,
                      title: '呼吸',
                      value: '${_healthData['averageRespiratoryRate'].toStringAsFixed(1)}次/分',
                    ),
                  ],
                ),
              )
            else if (_hasPermission)
              const Center(
                child: Text(
                  '暂无健康数据',
                  style: TextStyle(color: Colors.white),
                ),
              )
            else
              const Center(
                child: Text(
                  '请同步健康数据以查看详细信息',
                  style: TextStyle(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
} 