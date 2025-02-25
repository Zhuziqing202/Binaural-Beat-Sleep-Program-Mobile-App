import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';

class GAD7QuestionnaireScreen extends StatefulWidget {
  const GAD7QuestionnaireScreen({super.key});

  @override
  State<GAD7QuestionnaireScreen> createState() =>
      _GAD7QuestionnaireScreenState();
}

class _GAD7QuestionnaireScreenState extends State<GAD7QuestionnaireScreen> {
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
                      '短版焦虑量表（GAD-7）',
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
                Text(
                  '参考文献：\n1. Spitzer, R. L., Kroenke, K., Williams, J. B. W., & Löwe, B. (2006). A brief measure for assessing generalized anxiety disorder: The GAD-7. Archives of Internal Medicine, 166(10), 1092-1097.',
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
    if (_totalScore <= 4) {
      interpretation = '您目前没有明显的焦虑症状，维持当前的健康生活方式即可。';
    } else if (_totalScore <= 9) {
      interpretation = '您的焦虑感可能偶尔干扰到日常生活。建议尝试一些放松技术，如深呼吸、冥想等。';
    } else if (_totalScore <= 14) {
      interpretation = '焦虑症状可能会影响到您的情绪和行为，需要更多的关注。建议寻求专业的心理治疗。';
    } else {
      interpretation = '您的焦虑症状非常严重，强烈建议您寻求专业的心理治疗。';
    }
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('短版焦虑量表（GAD-7）解读'),
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
      '您在过去两周内有多频繁感到紧张、焦虑或烦躁？',
      '您在过去两周内有多频繁感到无法放松？',
      '您在过去两周内有多频繁感到情绪低落？',
      '您在过去两周内有多频繁感到失去兴趣或乐趣？',
      '您在过去两周内有多频繁感到容易疲劳或精力不足？',
      '您在过去两周内有多频繁感到自我评价低？',
      '您在过去两周内有多频繁感到难以入睡？',
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
      ],
    );
  }
}
