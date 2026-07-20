import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/star_colors.dart';
import 'star_stencil_bar.dart';
import 'stencil_header_verdict.dart';

/// Летящая звезда поверх экрана (от точки A к точке B).
class FlyingStarOverlay extends StatefulWidget {
  const FlyingStarOverlay({
    super.key,
    required this.from,
    required this.to,
    required this.onComplete,
    this.color = StarColors.progress,
    this.brightColor = StarColors.progressGlow,
    this.landedColor = StarColors.progress,
    this.zigzag = false,
    this.size = 28,
    this.duration,
  });

  /// Меньше волн — траектория ближе к прямой.
  static const zigzagWaves = 2.0;
  static const zigzagDuration = Duration(milliseconds: 460);
  static const directDuration = Duration(milliseconds: 180);

  final Offset from;
  final Offset to;
  final VoidCallback onComplete;
  final Color color;
  final Color brightColor;
  final Color landedColor;
  final bool zigzag;
  final double size;
  final Duration? duration;

  @override
  State<FlyingStarOverlay> createState() => _FlyingStarOverlayState();
}

class _FlyingStarOverlayState extends State<FlyingStarOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curve;
  var _completed = false;

  @override
  void initState() {
    super.initState();
    final effectiveDuration = widget.duration ??
        (widget.zigzag ? FlyingStarOverlay.zigzagDuration : FlyingStarOverlay.directDuration);
    _controller = AnimationController(vsync: this, duration: effectiveDuration);
    _curve = CurvedAnimation(
      parent: _controller,
      curve: widget.zigzag ? Curves.easeInOutSine : Curves.easeInCubic,
    );
    _controller.forward().whenComplete(_finish);
  }

  void _finish() {
    if (_completed) return;
    _completed = true;
    widget.onComplete();
  }

  @override
  void dispose() {
    // Завершаем только если анимация реально шла — иначе мгновенный dispose
    // (до первого кадра) засчитывал звезду без полёта.
    if (!_completed && _controller.value > 0.08) {
      _finish();
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedBuilder(
              animation: _curve,
              builder: (context, child) {
                final t = _curve.value;
                final pos = widget.zigzag
                    ? _zigzagPosition(t)
                    : Offset.lerp(widget.from, widget.to, t)!;
                final scale = 0.6 + 0.5 * (t < 0.5 ? t * 2 : (1 - t) * 2);

                final landedBlend = widget.zigzag
                    ? ((t - 0.82) / 0.18).clamp(0.0, 1.0)
                    : 0.0;
                final starColor = widget.zigzag
                    ? Color.lerp(widget.brightColor, widget.landedColor, landedBlend)!
                    : widget.color;
                final glow = widget.zigzag ? (1 - landedBlend) * 0.55 : 0.2;

                return Positioned(
                  left: pos.dx - widget.size / 2,
                  top: pos.dy - widget.size / 2,
                  child: Transform.scale(
                    scale: scale,
                    child: Icon(
                      Icons.star_rounded,
                      size: widget.size,
                      color: starColor,
                      shadows: [
                        Shadow(
                          color: starColor.withValues(alpha: glow),
                          blurRadius: 10 + glow * 12,
                        ),
                        const Shadow(color: Colors.black26, blurRadius: 4),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Offset _zigzagPosition(double t) {
    final base = Offset.lerp(widget.from, widget.to, t)!;
    final delta = widget.to - widget.from;
    final length = delta.distance;
    if (length < 1) return base;

    final dir = Offset(delta.dx / length, delta.dy / length);
    final perp = Offset(-dir.dy, dir.dx);
    // Плавное затухание у начала и конца — без резких поворотов.
    final envelope = math.pow(math.sin(t * math.pi), 0.85).toDouble();
    const amplitude = 12.0;
    final wiggle =
        math.sin(t * math.pi * FlyingStarOverlay.zigzagWaves * 2) *
        amplitude *
        envelope;

    return base + perp * wiggle;
  }
}

/// Дрожание и распад звезды (кошелёк или трафарет).
class ShatterStarOverlay extends StatefulWidget {
  const ShatterStarOverlay({
    super.key,
    required this.center,
    required this.onComplete,
    this.color = StarColors.progress,
    this.size = 28,
  });

  final Offset center;
  final VoidCallback onComplete;
  final Color color;
  final double size;

  @override
  State<ShatterStarOverlay> createState() => _ShatterStarOverlayState();
}

class _ShatterStarOverlayState extends State<ShatterStarOverlay>
    with SingleTickerProviderStateMixin {
  static const _shakeFraction = 0.42;

  late final AnimationController _controller;

  static const _dirs = [
    Offset(1, 0),
    Offset(0.7, 0.7),
    Offset(0, 1),
    Offset(-0.7, 0.7),
    Offset(-1, 0),
    Offset(-0.7, -0.7),
    Offset(0, -1),
    Offset(0.7, -0.7),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward().whenComplete(() {
        if (mounted) widget.onComplete();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isShaking => _controller.value < _shakeFraction;

  double get _shatterProgress {
    if (_controller.value <= _shakeFraction) return 0;
    return ((_controller.value - _shakeFraction) / (1 - _shakeFraction))
        .clamp(0.0, 1.0);
  }

  Offset _shakeOffset(double t) {
    final progress = t / _shakeFraction;
    final amp = 2.5 + progress * 4.5;
    return Offset(
      math.sin(progress * math.pi * 10) * amp,
      math.cos(progress * math.pi * 7) * amp * 0.55,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final shake = _isShaking
                ? _shakeOffset(_controller.value)
                : Offset.zero;
            final shatter = Curves.easeOut.transform(_shatterProgress);
            final center = widget.center + shake;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                if (_isShaking)
                  Positioned(
                    left: center.dx - widget.size / 2,
                    top: center.dy - widget.size / 2,
                    child: Icon(
                      Icons.star_rounded,
                      size: widget.size,
                      color: widget.color,
                    ),
                  ),
                if (!_isShaking) ...[
                  for (var i = 0; i < _dirs.length; i++)
                    Positioned(
                      left: center.dx + _dirs[i].dx * 34 * shatter - 6,
                      top: center.dy + _dirs[i].dy * 34 * shatter - 6,
                      child: Opacity(
                        opacity: 1 - shatter,
                        child: Transform.rotate(
                          angle: shatter * (i + 1) * 0.4,
                          child: Icon(
                            Icons.star_rounded,
                            size: 12 + (1 - shatter) * 4,
                            color: widget.color,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    left: center.dx - widget.size / 2,
                    top: center.dy - widget.size / 2,
                    child: Opacity(
                      opacity: 1 - shatter,
                      child: Transform.scale(
                        scale: 1 - shatter * 0.35,
                        child: Icon(
                          Icons.star_rounded,
                          size: widget.size,
                          color: widget.color,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Полоска: трафарет слева + смайлик по центру + кошелёк справа.
class TachStarsHeader extends StatelessWidget {
  const TachStarsHeader({
    super.key,
    required this.stencilFilled,
    required this.walletStars,
    this.shatterStencilIndex,
    this.stencilBarKey,
    this.walletKey,
    this.verdict = StencilHeaderVerdict.none,
    this.verdictGeneration = 0,
  });

  final int stencilFilled;
  final int walletStars;
  final int? shatterStencilIndex;
  final GlobalKey? stencilBarKey;
  final GlobalKey? walletKey;
  final StencilHeaderVerdict verdict;
  final int verdictGeneration;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        KeyedSubtree(
          key: stencilBarKey,
          child: StarStencilBar(
            filled: stencilFilled,
            shatterIndex: shatterStencilIndex,
          ),
        ),
        Expanded(
          child: Center(
            child: StencilHeaderBuddy(
              verdict: verdict,
              generation: verdictGeneration,
            ),
          ),
        ),
        KeyedSubtree(
          key: walletKey,
          child: _WalletChip(stars: walletStars),
        ),
      ],
    );
  }
}

class _WalletChip extends StatelessWidget {
  const _WalletChip({required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 22, color: StarColors.currency),
          const SizedBox(width: 4),
          Text(
            '$stars',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: StarColors.currency,
                ),
          ),
        ],
      ),
    );
  }
}
