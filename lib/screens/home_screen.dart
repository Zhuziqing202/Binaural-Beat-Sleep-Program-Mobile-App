import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pink_sleep/screens/sleep_preparation_screen.dart';
import 'package:pink_sleep/screens/sleep_report_screen.dart';
import 'package:pink_sleep/screens/dream_diary_screen.dart';
import 'package:pink_sleep/screens/settings_screen.dart';
import 'package:pink_sleep/screens/sleeping_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final standardFontSize = screenWidth * 0.045; // 动态计算基准字体大小

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
          bottom: false, // 允许内容延伸到底部
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Container(
              constraints: BoxConstraints(
                minHeight: screenHeight - MediaQuery.of(context).padding.top,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                      child: Text(
                        '粉睡眠',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: standardFontSize * 1.4,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    GlassmorphicContainer(
                      width: double.infinity,
                      height: screenHeight * 0.28,
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
                      child: SizedBox(
                        height: screenHeight * 0.2,
                        child: Transform.scale(
                          scale: 0.7,
                          child: Image.asset(
                            'assets/images/sleep_banner.png',
                            fit: BoxFit.contain,
                            color: Colors.white.withOpacity(0.9),
                            colorBlendMode: BlendMode.modulate,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(duration: 600.ms).slideY(
                        begin: -0.2,
                        end: 0,
                        duration: 600.ms,
                        curve: Curves.easeOut),
                    SizedBox(height: screenHeight * 0.03),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.2,
                      children: [
                        _buildQuickAccessCard(
                          context,
                          '入睡准备',
                          '轻松入睡的必备步骤',
                          Icons.bed,
                          standardFontSize,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const SleepPreparationScreen(),
                              ),
                            );
                          },
                        ),
                        _buildQuickAccessCard(
                          context,
                          '睡眠报告',
                          '查看睡眠质量分析',
                          Icons.bar_chart,
                          standardFontSize,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SleepReportScreen(),
                              ),
                            );
                          },
                        ),
                        _buildQuickAccessCard(
                          context,
                          '睡眠日记',
                          '记录您的梦境',
                          Icons.book,
                          standardFontSize,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const DreamDiaryScreen(),
                              ),
                            );
                          },
                        ),
                        _buildQuickAccessCard(
                          context,
                          '设置',
                          '自定义您的睡眠体验',
                          Icons.settings,
                          standardFontSize,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SettingsScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    )
                        .animate()
                        .fadeIn(delay: 600.ms, duration: 600.ms)
                        .slideY(begin: 0.2, end: 0),
                    SizedBox(height: screenHeight * 0.05),
                    _buildStartSleepButton(context, standardFontSize),
                    SizedBox(height: screenHeight * 0.05),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccessCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    double standardFontSize, {
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: standardFontSize * 1.8,
              ),
              SizedBox(height: standardFontSize * 0.6),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: standardFontSize * 0.9,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: standardFontSize * 0.2),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: standardFontSize * 0.7,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStartSleepButton(BuildContext context, double standardFontSize) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SleepingScreen(),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            width: standardFontSize * 4,
            height: standardFontSize * 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: standardFontSize * 2,
            ),
          )
              .animate(
                onPlay: (controller) => controller.repeat(reverse: true),
              )
              .scale(
                duration: 2.seconds,
                begin: const Offset(1, 1),
                end: const Offset(1.1, 1.1),
                curve: Curves.easeInOut,
              ),
          SizedBox(height: standardFontSize * 0.4),
          Text(
            '开始睡眠',
            style: TextStyle(
              color: Colors.white,
              fontSize: standardFontSize * 0.8,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
