import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:intl/intl.dart';
import '../models/dream_record.dart';
import '../services/dream_record_service.dart';
import 'dream_edit_screen.dart';

class DreamDiaryScreen extends StatefulWidget {
  final String? initialDreamId;

  const DreamDiaryScreen({
    super.key,
    this.initialDreamId,
  });

  @override
  State<DreamDiaryScreen> createState() => _DreamDiaryScreenState();
}

class _DreamDiaryScreenState extends State<DreamDiaryScreen> {
  final List<DreamRecord> _records = [];
  bool _isLoading = true;
  String _searchQuery = '';
  int? _moodFilter;
  String? _expandedDreamId;

  // 存储每个梦境卡片的GlobalKey
  final Map<String?, GlobalKey> _dreamCardKeys = {};

  Widget _buildMoodTag(int mood) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_getMoodIcon(mood), color: Colors.white, size: 16),
        const SizedBox(width: 4),
        Text(_getMoodText(mood), style: const TextStyle(color: Colors.white, fontSize: 14)),
      ],
    ),
  );

  Widget _buildTag(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
  );

  @override
  void initState() {
    super.initState();
    _expandedDreamId = widget.initialDreamId;
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    final records = await DreamRecordService.instance.readAllDreams();
    setState(() {
      _records.clear();
      _records.addAll(records..sort((a, b) => b.date.compareTo(a.date)));
      _isLoading = false;
    });

    // 如果有指定的梦境ID，滚动到对应位置
    if (_expandedDreamId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final index = _filteredRecords.indexWhere((r) => r.id == _expandedDreamId);
        if (index != -1) {
          final context = _dreamCardKeys[_expandedDreamId]?.currentContext;
          if (context != null) {
            Scrollable.ensureVisible(
              context,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        }
      });
    }
  }

  List<DreamRecord> get _filteredRecords {
    return _records.where((record) {
      final matchesSearch = _searchQuery.isEmpty ||
          record.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          record.content.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesMood = _moodFilter == null ||
          (_moodFilter! <= -60 && record.mood <= -60) ||
          (_moodFilter! == -20 && record.mood > -60 && record.mood <= -20) ||
          (_moodFilter! == 0 && record.mood > -20 && record.mood < 20) ||
          (_moodFilter! == 20 && record.mood >= 20 && record.mood < 60) ||
          (_moodFilter! >= 60 && record.mood >= 60);
      
      return matchesSearch && matchesMood;
    }).toList();
  }

  String _calculateTotalWords() {
    return _records.fold<int>(0, (sum, record) => 
      sum + record.content.characters.length).toString();
  }

  String _calculateTotalDays() {
    if (_records.isEmpty) return '0';
    final dates = _records.map((r) => DateTime(r.date.year, r.date.month, r.date.day))
                         .toSet()
                         .toList();
    return dates.length.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
                  _buildStats(),
                  _buildSearchAndFilter(),
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                        : _filteredRecords.isEmpty
                            ? Center(
                                child: Text(
                                  _records.isEmpty ? '还没有记录梦境\n点击右下角的按钮开始记录' 
                                                 : '没有找到符合条件的记录',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(20),
                                itemCount: _filteredRecords.length,
                                itemBuilder: (context, index) {
                                  return _buildDreamCard(_filteredRecords[index]);
                                },
                              ),
                  ),
                ],
              ),
              Positioned(
                right: 20,
                bottom: 20,
                child: _buildAddDreamButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 100,
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
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _calculateTotalWords(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '总字数',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            Container(
              width: 1,
              height: 40,
              color: Colors.white24,
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _calculateTotalDays(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '记录天数',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: GlassmorphicContainer(
              width: double.infinity,
              height: 45,
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
              child: TextField(
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: '搜索梦境...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, color: Colors.white70),
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                  isDense: true,
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
                keyboardAppearance: Brightness.light,
              ),
            ),
          ),
          const SizedBox(width: 10),
          GlassmorphicContainer(
            width: 45,
            height: 45,
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
              child: InkWell(
                onTap: _showMoodFilterDialog,
                borderRadius: BorderRadius.circular(20),
                child: Icon(
                  Icons.filter_list,
                  color: _moodFilter == null ? Colors.white70 : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMoodFilterDialog() {
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
                padding: EdgeInsets.all(20),
                child: Text(
                  '按心情筛选',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(color: Colors.white24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildFilterOption('全部', null),
                      _buildFilterOption('非常消极', -100),
                      _buildFilterOption('消极', -20),
                      _buildFilterOption('中性', 0),
                      _buildFilterOption('积极', 20),
                      _buildFilterOption('非常积极', 100),
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

  Widget _buildFilterOption(String label, int? value) {
    final isSelected = _moodFilter == value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() => _moodFilter = value);
          Navigator.pop(context);
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (isSelected) ...[
                const Spacer(),
                const Icon(Icons.check, color: Colors.white),
              ],
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
            '梦境日记',
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

  Widget _buildDreamCard(DreamRecord record) {
    // 确保每个记录都有一个对应的key
    _dreamCardKeys[record.id] ??= GlobalKey();
    final isExpanded = record.id == _expandedDreamId;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _expandedDreamId = isExpanded ? null : record.id;
        });
      },
      child: Container(
        key: _dreamCardKeys[record.id],
        margin: const EdgeInsets.only(bottom: 15),
        child: GlassmorphicContainer(
          width: double.infinity,
          height: isExpanded ? 200 : 100,
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        record.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      DateFormat('MM-dd HH:mm').format(record.date),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      _getMoodIcon(record.mood),
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getMoodText(record.mood),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '清晰度 ${record.clarity}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                if (isExpanded) ...[
                  const SizedBox(height: 15),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        record.content,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
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
      return '非常消极';
    } else if (mood <= -20) {
      return '消极';
    } else if (mood < 20) {
      return '中性';
    } else if (mood < 60) {
      return '积极';
    } else {
      return '非常积极';
    }
  }

  Widget _buildAddDreamButton() {
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
                builder: (context) => const DreamEditScreen(),
              ),
            );
            if (result == true) {
              _loadRecords();
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

  void _showDreamDetails(DreamRecord record) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.transparent,
      enableDrag: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF6B8EFF).withOpacity(0.95),
                const Color(0xFFFF8FB1).withOpacity(0.95),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: GlassmorphicContainer(
            width: double.infinity,
            height: double.infinity,
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
              children: [
                const SizedBox(height: 10),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white70,
                  size: 24,
                ),
                const SizedBox(height: 5),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  record.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.white),
                                    onPressed: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => DreamEditScreen(record: record),
                                        ),
                                      );
                                      if (result == true) {
                                        Navigator.pop(context);
                                        _loadRecords();
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.white),
                                    onPressed: () => _showDeleteConfirmation(record),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            DateFormat('yyyy年MM月dd日 HH:mm').format(record.date),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              _buildMoodTag(record.mood),
                              const SizedBox(width: 8),
                              _buildTag('清晰度 ${record.clarity}'),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            record.content,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(DreamRecord record) {
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
                  '确认删除',
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
                  '确定要删除这条梦境记录吗？\n删除后无法恢复。',
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
                    onPressed: () async {
                      await DreamRecordService.instance.deleteRecord(record.id);
                      if (mounted) {
                        Navigator.pop(context); // 关闭确认对话框
                        Navigator.pop(context); // 关闭详情页
                        _loadRecords(); // 重新加载记录
                      }
                    },
                    child: const Text(
                      '删除',
                      style: TextStyle(
                        color: Colors.red,
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
  }
}