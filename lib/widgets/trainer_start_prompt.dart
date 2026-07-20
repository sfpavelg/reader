import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Мерцающая панель с переливанием цвета — кнопка «готов начать».
class PulsingShimmerPanel extends StatefulWidget {
  const PulsingShimmerPanel({
    super.key,
    required this.child,
    this.onTap,
    this.panelKey,
    this.active = true,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.baseColor,
    this.width,
    this.emphasized = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final GlobalKey? panelKey;
  final bool active;
  final EdgeInsets padding;
  final BorderRadius borderRadius;
  final Color? baseColor;
  final double? width;
  final bool emphasized;

  @override
  State<PulsingShimmerPanel> createState() => _PulsingShimmerPanelState();
}

class _PulsingShimmerPanelState extends State<PulsingShimmerPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    if (widget.active) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant PulsingShimmerPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
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
    final pulsing = widget.active && widget.onTap != null;

    Widget panel = AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final glow = pulsing ? math.sin(t * math.pi * 2) * 0.5 + 0.5 : 0.0;
        final shimmer = pulsing ? t : 0.0;

        final fill = widget.baseColor ?? colors.surfaceContainerHighest;
        final shimmerHi = Color.lerp(
          colors.primaryContainer,
          colors.tertiaryContainer,
          0.75,
        )!;

        // Полоса блеска полностью уходит за левый край (t=0) и за правый (t=1),
        // чтобы цикл всегда шёл «с начала карточки», а не со средины.
        final travel = pulsing ? (shimmer * 3.2 - 1.6) : 0.0;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: widget.width ?? double.infinity,
          padding: widget.padding,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            color: pulsing ? null : fill,
            gradient: pulsing
                ? LinearGradient(
                    begin: Alignment(travel - 0.55, -0.35),
                    end: Alignment(travel + 0.55, 0.45),
                    colors: [
                      fill,
                      fill,
                      shimmerHi,
                      Color.lerp(shimmerHi, colors.primary, 0.35)!,
                      fill,
                      fill,
                    ],
                    stops: const [0.0, 0.28, 0.45, 0.55, 0.72, 1.0],
                  )
                : null,
            border: Border.all(
              color: pulsing
                  ? Color.lerp(colors.outline, colors.primary, glow)!
                  : widget.emphasized
                      ? colors.primary
                      : colors.outline,
              width: pulsing
                  ? 2 + glow * 3
                  : widget.emphasized
                      ? 3
                      : 2,
            ),
            boxShadow: pulsing
                ? [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.22 * glow),
                      blurRadius: 10 + glow * 14,
                      spreadRadius: glow * 2,
                    ),
                  ]
                : null,
          ),
          child: child,
        );
      },
      child: widget.child,
    );

    if (widget.onTap != null) {
      panel = Material(
        color: Colors.transparent,
        child: InkWell(
          key: widget.panelKey,
          borderRadius: widget.borderRadius,
          onTap: widget.onTap,
          child: panel,
        ),
      );
    } else if (widget.panelKey != null) {
      panel = KeyedSubtree(key: widget.panelKey, child: panel);
    }

    return panel;
  }
}

/// Кнопка «Начать» с указателем рукой (как во «Вспышках»).
class TrainerStartPrompt extends StatelessWidget {
  const TrainerStartPrompt({
    super.key,
    required this.onTap,
    this.label = 'Начать',
    this.panelKey,
  });

  final VoidCallback onTap;
  final String label;
  final GlobalKey? panelKey;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        PulsingShimmerPanel(
          panelKey: panelKey,
          onTap: onTap,
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 22),
          width: 220,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colors.onPrimaryContainer,
                ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          '👆',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
