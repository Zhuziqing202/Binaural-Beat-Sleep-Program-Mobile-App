import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';

class ISIQuestionnaireScreen extends StatefulWidget {
  const ISIQuestionnaireScreen({super.key});

  @override
  State<ISIQuestionnaireScreen> createState() => _ISIQuestionnaireScreenState();
}

class _ISIQuestionnaireScreenState extends State<ISIQuestionnaireScreen> {
  final List<int> _responses = List.filled(7, 0);
  int _totalScore = 0;

  void _calculateScore() {
    _totalScore = _responses.reduce((a, b) => a + b);
    setState(() {});
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon:
                          const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      '失眠严重指数量表（ISI）',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ...List.generate(7, (index) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildQuestionItem(index),
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white54),
                    ],
                  );
                }),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      _calculateScore();
                      _showInterpretation();
                    },
                    child: const Text('计算分数'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 50, vertical: 12),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '总分: $_totalScore',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 20),
                _buildScoreStandard(),
                const SizedBox(height: 20),
                Text(
                  '参考文献：\n1. Bastien, C. H., Vallieres, A., & Morin, C. M. (2001). Validation of the Insomnia Severity Index as an outcome measure for insomnia research. Sleep Medicine, 2(4), 297-307.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showInterpretation() {
    String interpretation;
    if (_totalScore <= 7) {
      interpretation = '您的睡眠质量良好，未出现明显的失眠困扰。继续保持健康的睡眠习惯，有助于维持良好的睡眠状态。';
    } else if (_totalScore <= 14) {
      interpretation = '您的睡眠质量有所下降，可能会出现偶尔入睡困难或浅睡现象。建议调整睡眠环境和作息时间，避免压力和刺激物。';
    } else if (_totalScore <= 21) {
      interpretation = '您的失眠问题较为明显，可能伴随夜间醒来或白天疲倦感。建议采取更为系统的睡眠干预措施，如认知行为疗法。';
    } else {
      interpretation = '您的失眠症状可能严重影响到日常生活和工作，建议立即寻求专业帮助。';
    }
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('失眠严重指数量表（ISI）解读'),
          content: Text('总分: $_totalScore\n\n' +
              interpretation +
              '\n\n您可以定期填写问卷，观察自己状态的变化。'),
          actions: <Widget>[
            TextButton(
              child: const Text('确定'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuestionItem(int index) {
    final questions = [
      '您的睡眠质量如何？',
      '您在过去两周内有多频繁感到难以入睡？',
      '您在过去两周内有多频繁感到睡眠不安？',
      '您在过去两周内有多频繁感到早醒？',
      '您在过去两周内有多频繁感到白天疲惫？',
      '您在过去两周内有多频繁感到情绪低落？',
      '您在过去两周内有多频繁感到焦虑？',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '问题 ${index + 1}: ${questions[index]}',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(4, (i) {
            return Column(
              children: [
                Text(
                  i == 0
                      ? '从不'
                      : i == 1
                          ? '偶尔'
                          : i == 2
                              ? '经常'
                              : '总是',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    _responses[index] = i;
                    setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _responses[index] == i
                          ? Colors.white.withOpacity(0.3)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${i}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildScoreStandard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '评分标准：',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '0-7分：没有失眠问题\n'
          '8-14分：轻度失眠\n'
          '15-21分：中度失眠\n'
          '22-28分：重度失眠',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
