import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/audio_player_widget.dart';
import '../services/audio_service.dart';
import 'dart:async';
import 'package:pink_sleep/screens/sleeping_screen.dart';

class SleepPreparationScreen extends StatefulWidget {
  const SleepPreparationScreen({super.key});

  @override
  State<SleepPreparationScreen> createState() => _SleepPreparationScreenState();
}

class _SleepPreparationScreenState extends State<SleepPreparationScreen> {
  final AudioService _audioService = AudioService.instance;
  final List<Map<String, dynamic>> _sounds = [
    {'name': 'ocean', 'display': '海浪', 'icon': Icons.waves},
    {'name': 'rain', 'display': '雨声', 'icon': Icons.water_drop},
    {'name': 'forest', 'display': '森林', 'icon': Icons.forest},
    {'name': 'white_noise', 'display': '白噪音', 'icon': Icons.noise_aware},
    {'name': 'stream', 'display': '溪流', 'icon': Icons.water},
    {'name': 'fire', 'display': '篝火', 'icon': Icons.local_fire_department},
  ];
  String? _selectedSound;

  // 呼吸引导相关状态
  bool _isBreathingActive = false;
  String _breathingPhase = '点击开始';
  Timer? _breathingTimer;
  int _remainingCycles = 6;
  double _circleSize = 150.0;

  // 添加睡眠语录列表
  final List<String> _sleepQuotes = [
    "别怕，今晚就算是给你发的'不睡觉奖'，你也能获得'明天拖延奖'！",
    "如果你担心明天早上迟到，先别急，今天晚上就让自己先睡个好觉，反正迟到又不怪你。",
    "今天的烦恼已经申请了加班，但你已经放工了，别管它，准备休息！",
    "大脑：'今晚也该放假了吧？'你：'好呀，正好我也准备逃避现实了！'",
    "你今天做了多少事？不重要，最重要的是现在可以躺下，关掉一切，进入'什么都不管'模式！",
    "别再计算明天的课、工作、生活了，你的床才是今晚唯一的'deadline'！",
    "你可能以为自己的脑袋是电池，但今晚的你是'关机'状态，直接重启！",
    "今晚的任务：躺下，不动，什么也不想，明天的你会感谢今晚的懒惰！",
    "如果明天的任务是一座大山，那今晚的你就好好当个'懒山'休息吧！",
    "今天熬夜的理由已经消失，毕竟大家都知道，打工人不熬夜，怎么对得起工资！",
    "今晚不用努力，明天再努力，反正梦里也没有上班，睡着就好。",
    "今天的奋斗已经够了，给自己发个加班费——一个美好的梦。",
    "你的床不收门票，今晚就让它免费带你去一场梦境之旅吧。",
    "大脑：'今晚又要思考吗？'你：'别急，先给你一个关机键。'",
    "记住，睡觉比刷社交媒体更有效，特别是在明天考试前。",
    "今天的任务清单已经满了，剩下的就交给梦境，明天再说。",
    "你没时间休息？没事，床会说：'你也可以休息一下，反正你也不想动了。'",
    "明天的事让它去蹦跶，今晚的你只需要躺下，什么也不想！",
    "记得，床是你的最佳合伙人，今晚它的任务是把你从焦虑中救出来。",
    "如果脑袋不想停下来，给它放个假，去梦乡旅行！",
    "别担心，今天的烦恼已经排队等着明天处理，今晚就先睡觉吧。",
    "想象你是个企鹅，躺在冰床上，什么都不管，进入冬眠模式。",
    "今天的咖啡已经帮你熬过了所有困境，剩下的交给梦吧，咖啡不用再加了。",
    "心情低落？别担心，梦境会给你准备一个热气腾腾的安慰包。",
    "现在躺下，什么都不想，明天的邮件，等会儿再发给你。",
    "你现在的任务就是睡觉，其他事明天再干，反正都没那么急。",
    "其实，睡觉就是给自己发放的'不务正业'奖励，今晚就好好享受吧。",
    "床是你最忠诚的员工，它已经准备好接手所有的不想动任务了！",
    "今天的烦恼就像手机里的未读消息，今晚先关机，明天再看。",
    "今晚让脑袋成为'思维放空模式'，明天再处理那些乱七八糟的事情。",
  ];

  late String _currentQuote;

  @override
  void initState() {
    super.initState();
    _currentQuote = _getRandomQuote();
  }

  String _getRandomQuote() {
    return _sleepQuotes[DateTime.now().microsecond % _sleepQuotes.length];
  }

  @override
  void dispose() {
    _breathingTimer?.cancel();
    _audioService.stopPresetSound();
    _audioService.stopCustomSound();
    super.dispose();
  }

  void _startBreathing() {
    if (_isBreathingActive) {
      _stopBreathing();
      return;
    }

    setState(() {
      _isBreathingActive = true;
      _remainingCycles = 6;
      _breathingPhase = '准备';
      _circleSize = 150.0;
    });

    // 延迟1秒后开始第一次呼吸循环
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _isBreathingActive) {
        _runBreathingCycle();
      }
    });
  }

  void _stopBreathing() {
    _breathingTimer?.cancel();
    setState(() {
      _isBreathingActive = false;
      _breathingPhase = '点击开始';
      _circleSize = 150.0;
    });
  }

  void _runBreathingCycle() {
    const breathInDuration = 4;
    const holdDuration = 2;
    const breathOutDuration = 4;
    const totalDuration = breathInDuration + holdDuration + breathOutDuration;
    int currentSecond = 0;
    const minSize = 100.0; // 减小初始大小
    const maxSize = 140.0; // 减小最大大小
    const sizeStep = (maxSize - minSize) / breathInDuration;

    _breathingTimer?.cancel();
    _breathingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (currentSecond < breathInDuration) {
          // 吸气阶段：逐渐增大
          _breathingPhase = '吸气';
          _circleSize = minSize + (currentSecond + 1) * sizeStep;
        } else if (currentSecond < breathInDuration + holdDuration) {
          // 屏息阶段：保持最大
          _breathingPhase = '屏息';
          _circleSize = maxSize;
        } else {
          // 呼气阶段：逐渐减小
          _breathingPhase = '呼气';
          final breathOutProgress =
              currentSecond - breathInDuration - holdDuration;
          _circleSize = maxSize - (breathOutProgress + 1) * sizeStep;
        }
      });

      currentSecond++;
      if (currentSecond >= totalDuration) {
        currentSecond = 0;
        setState(() {
          _remainingCycles--;
        });

        if (_remainingCycles <= 0) {
          _breathingTimer?.cancel();
          setState(() {
            _isBreathingActive = false;
            _breathingPhase = '训练完成';
            _circleSize = minSize;
          });

          // 显示完成提示
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => Dialog(
                backgroundColor: Colors.transparent,
                child: GlassmorphicContainer(
                  width: 280,
                  height: 240,
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
                      const SizedBox(height: 16),
                      const Icon(
                        Icons.check_circle_outline,
                        color: Colors.white,
                        size: 40,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '呼吸训练完成',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          '继续保持放松的状态\n让我们准备一个美好的睡眠',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: 160,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.white.withOpacity(0.2),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => Navigator.pop(context),
                            child: const Center(
                              child: Text(
                                '确定',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          }
        }
      }
    });
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
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
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
                            Text(
                              '入睡准备',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: standardFontSize * 1.2,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // 入睡建议卡片
                        GlassmorphicContainer(
                          width: double.infinity,
                          height: screenHeight * 0.15,
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
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '今日入睡建议',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: standardFontSize * 0.9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _currentQuote,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: standardFontSize * 0.7,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildBreathingGuide()
                            .animate()
                            .fadeIn(delay: 300.ms, duration: 500.ms)
                            .slideX(begin: -0.2, end: 0),
                        const SizedBox(height: 20),
                        _buildPreparationSteps(),
                      ],
                    ),
                  ),
                ),
              ),
              // 底部按钮
              Padding(
                padding: const EdgeInsets.all(16),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SleepingScreen(),
                      ),
                    );
                  },
                  child: GlassmorphicContainer(
                    width: double.infinity,
                    height: 56,
                    borderRadius: 28,
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
                    child: Center(
                      child: Text(
                        '准备完成',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: standardFontSize * 0.9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreathingGuide() {
    const minSize = 100.0; // 减小初始圆圈大小
    const maxSize = 140.0; // 减小最大圆圈大小
    const sizeStep = (maxSize - minSize) / 4;

    return GlassmorphicContainer(
      width: double.infinity,
      height: 280,
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '正念呼吸引导',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _isBreathingActive ? '剩余周期：$_remainingCycles' : '每次训练6个周期',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _startBreathing,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              width: _circleSize,
              height: _circleSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _breathingPhase,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!_isBreathingActive) ...[
                      const SizedBox(height: 8),
                      Text(
                        '点击开始训练',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreparationSteps() {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 380,
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '入睡建议',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Column(
              children: [
                _buildPreparationItem(
                  '1. 放松身心',
                  '深呼吸5-10分钟，让身体和心灵都放松下来',
                  Icons.spa,
                ),
                const SizedBox(height: 12),
                _buildPreparationItem(
                  '2. 调整光线',
                  '调暗房间灯光，营造舒适的睡眠环境',
                  Icons.wb_sunny,
                ),
                const SizedBox(height: 12),
                _buildPreparationItem(
                  '3. 远离电子设备',
                  '睡前一小时避免使用手机等电子设备',
                  Icons.phone_android,
                ),
                const SizedBox(height: 12),
                _buildPreparationItem(
                  '4. 温度调节',
                  '保持房间温度在18-22度之间',
                  Icons.thermostat,
                ),
                const SizedBox(height: 12),
                _buildPreparationItem(
                  '5. 穿着舒适',
                  '选择宽松、透气的睡衣',
                  Icons.checkroom,
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildPreparationItem(
      String title, String description, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 14,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
