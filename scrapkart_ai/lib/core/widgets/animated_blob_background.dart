import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/colors.dart';

class AnimatedBlobBackground extends StatefulWidget {
  final Widget child;
  const AnimatedBlobBackground({super.key, required this.child});

  @override
  State<AnimatedBlobBackground> createState() => _AnimatedBlobBackgroundState();
}

class _AnimatedBlobBackgroundState extends State<AnimatedBlobBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: AppColors.background),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              children: [
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.1 +
                      sin(_controller.value * 2 * pi) * 20,
                  left: MediaQuery.of(context).size.width * 0.1 +
                      cos(_controller.value * 2 * pi) * 20,
                  child: _buildBlob(AppColors.secondary.withValues(alpha: 0.3), 200),
                ),
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.5 +
                      cos(_controller.value * 2 * pi) * 30,
                  right: MediaQuery.of(context).size.width * 0.1 +
                      sin(_controller.value * 2 * pi) * 30,
                  child: _buildBlob(AppColors.tertiary.withValues(alpha: 0.3), 250),
                ),
                Positioned(
                  bottom: MediaQuery.of(context).size.height * 0.1 -
                      sin(_controller.value * 2 * pi) * 20,
                  left: MediaQuery.of(context).size.width * 0.2 -
                      cos(_controller.value * 2 * pi) * 20,
                  child: _buildBlob(AppColors.accent.withValues(alpha: 0.3), 180),
                ),
              ],
            );
          },
        ),
        // Glass overlay to make everything smooth
        Positioned.fill(
          child: Container(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        SafeArea(child: widget.child),
      ],
    );
  }

  Widget _buildBlob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: size / 2,
            spreadRadius: size / 4,
          ),
        ],
      ),
    );
  }
}
