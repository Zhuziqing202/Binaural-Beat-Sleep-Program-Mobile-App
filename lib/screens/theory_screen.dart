import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TheoryScreen extends StatelessWidget {
  const TheoryScreen({super.key});

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
                      '理论依据',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildTheoryCard(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTheoryCard() {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 800,
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
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTheorySection(
                '粉噪音的助眠效果',
                '粉噪音（Pink Noise）是一种与白噪音相似的声音信号，但其功率谱密度随着频率的增加而减少，使其听起来更加平衡且柔和。研究表明，粉噪音有助于：\n\n'
                    '• 提升深度睡眠质量\n'
                    '• 降低外界噪音干扰\n'
                    '• 促进深度睡眠阶段（N3阶段）的脑电活动\n'
                    '• 增强夜间恢复效果\n\n'
                    '根据Suzuki等人(1991)的研究，持续的粉噪音播放能够增强深睡的效果，进而提高睡眠的恢复质量。',
              ),
              const SizedBox(height: 20),
              _buildTheorySection(
                '双耳节拍对睡眠的影响',
                '双耳节拍（Binaural Beats）通过左右耳播放不同频率的声音，促使大脑产生特定脑波。研究发现：\n\n'
                    '• 低频双耳节拍（如3Hz）能有效增强深睡阶段\n'
                    '• 通过影响自主神经系统，帮助调节睡眠过程\n'
                    '• 增加副交感神经活性，促进放松\n'
                    '• 提高入睡速度和睡眠深度\n\n'
                    'Dabiri等人(2022)的研究表明，双耳节拍尤其是低频在深度睡眠阶段表现出积极效果。McConnell等人(2014)进一步证实，双耳节拍技术通过影响自主神经系统，能够增加副交感神经的活性。',
              ),
              const SizedBox(height: 20),
              _buildTheorySection(
                '结合效果',
                '粉噪音和双耳节拍的结合能够：\n\n'
                    '• 在不同睡眠阶段提供最佳声音刺激\n'
                    '• 提升入睡速度\n'
                    '• 延长深睡时间\n'
                    '• 减少中途醒来\n'
                    '• 实现个性化和精准的助眠效果\n\n'
                    'Lee等人(2022)的研究发现，粉噪音和双耳节拍的结合能更好地帮助用户提升入睡速度、延长深睡时间，并减少中途醒来。',
              ),
              const SizedBox(height: 30),
              _buildTheorySection(
                '参考文献',
                '1. Dabiri, R., et al. (2022). The effect of auditory stimulation using delta binaural beat for a better sleep and post-sleep mood: A pilot study. Digital Health, 8.\n\n'
                    '2. Lee, E., et al. (2022). Entrapment of binaural auditory beats in subjects with symptoms of insomnia. Brain Sciences, 12(3), 339.\n\n'
                    '3. McConnell, P. A., et al. (2014). Auditory driving of the autonomic nervous system: Listening to theta-frequency binaural beats post-exercise increases parasympathetic activation and sympathetic withdrawal. Frontiers in Psychology, 5, 1248.\n\n'
                    '4. Suzuki, S., et al. (1991). Sleep deepening effect of steady pink noise. Journal of Sound and Vibration, 151(3), 407-414.',
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildTheorySection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
