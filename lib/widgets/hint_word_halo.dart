import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Слово-подсказка с мягким мерцающим ореолом — фокус внимания на цели.
class HintWordHalo extends StatefulWidget {
  const HintWordHalo({
    super.key,
    required this.text,
    this.style,
    this.active = true,
  });

  final String text;
  final TextStyle? style;
  final bool active;

  @override
  State<HintWordHalo> createState() => _HintWordHaloState();
}

class _HintWordHaloState extends State<HintWordHalo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    if (widget.active) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant HintWordHalo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final style = widget.style ??
        Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            );

    if (!widget.active) {
      return Text(widget.text, style: style, textAlign: TextAlign.center);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final pulse = (math.sin(t * math.pi * 2) * 0.5 + 0.5);
        final shimmer = t;

        final glowColor = Color.lerp(
          colors.primary,
          const Color(0xFF6A3DE8),
          0.45,
        )!;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment(-1.4 + shimmer * 2.8, -0.3),
              end: Alignment(0.2 + shimmer * 2.8, 0.5),
              colors: [
                glowColor.withValues(alpha: 0.06 + pulse * 0.04),
                glowColor.withValues(alpha: 0.18 + pulse * 0.16),
                glowColor.withValues(alpha: 0.06 + pulse * 0.04),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
            border: Border.all(
              color: glowColor.withValues(alpha: 0.35 + pulse * 0.45),
              width: 1.5 + pulse * 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: glowColor.withValues(alpha: 0.28 + pulse * 0.32),
                blurRadius: 12 + pulse * 16,
                spreadRadius: 1 + pulse * 3,
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.35 + pulse * 0.25),
                blurRadius: 6 + pulse * 4,
                spreadRadius: -1,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Text(
        widget.text,
        style: style,
        textAlign: TextAlign.center,
      ),
    );
  }
}
