import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AnimationUtils {
  static List<Effect> get fadeSlideIn => [
        const FadeEffect(
          duration: Duration(milliseconds: 500),
          curve: Curves.easeOut,
        ),
        const SlideEffect(
          begin: Offset(0, 0.2),
          end: Offset.zero,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeOut,
        ),
      ];

  static List<Effect> get scaleIn => [
        const ScaleEffect(
          begin: Offset(0.8, 0.8),
          end: Offset(1, 1),
          duration: Duration(milliseconds: 500),
          curve: Curves.easeOut,
        ),
        const FadeEffect(
          duration: Duration(milliseconds: 500),
          curve: Curves.easeOut,
        ),
      ];

  static List<Effect> get breathe => [
        const ScaleEffect(
          begin: Offset(1, 1),
          end: Offset(1.1, 1.1),
          duration: Duration(seconds: 4),
          curve: Curves.easeInOut,
        ),
      ];

  static List<Effect> get pulse => [
        const ScaleEffect(
          begin: Offset(1, 1),
          end: Offset(1.05, 1.05),
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        ),
      ];

  static List<Effect> get shimmer => [
        const ShimmerEffect(
          duration: Duration(seconds: 2),
          color: Colors.white24,
          curve: Curves.easeInOut,
        ),
      ];
} 