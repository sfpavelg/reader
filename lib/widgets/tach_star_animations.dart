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

/// Дрожь, затем змейкой падает вниз за край экрана (неверный ответ).
class FallingStarOverlay extends StatefulWidget {
  const FallingStarOverlay({
    super.key,
    required this.from,
    required this.fallToY,
    required this.onComplete,
    this.color = const Color(0xFFEF5350),
    this.size = 28,
    this.wavePhase = 0,
  });

  static const shakeFraction = 0.16;
  static const duration = Duration(milliseconds: 1150);
  static const snakeWaves = 2.6;
  static const snakeAmplitude = 42.0;

  final Offset from;
  final double fallToY;
  final VoidCallback onComplete;
  final Color color;
  final double size;
  final double wavePhase;

  @override
  State<FallingStarOverlay> createState() => _FallingStarOverlayState();
}

class _FallingStarOverlayState extends State<FallingStarOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  var _completed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: FallingStarOverlay.duration,
    )..forward().whenComplete(_finish);
  }

  void _finish() {
    if (_completed) return;
    _completed = true;
    widget.onComplete();
  }

  @override
  void dispose() {
    if (!_completed && _controller.value > 0.08) {
      _finish();
    }
    _controller.dispose();
    super.dispose();
  }

  bool get _isShaking =>
      _controller.value < FallingStarOverlay.shakeFraction;

  Offset _shakeOffset(double t) {
    final progress = t / FallingStarOverlay.shakeFraction;
    final amp = 2.5 + progress * 5.5;
    return Offset(
      math.sin(progress * math.pi * 11) * amp,
      math.cos(progress * math.pi * 8) * amp * 0.55,
    );
  }

  Offset _snakePosition(double fallT) {
    final start = widget.from;
    final end = Offset(start.dx, widget.fallToY);
    final base = Offset.lerp(start, end, Curves.easeInCubic.transform(fallT))!;
    final envelope = math.sin(fallT * math.pi).clamp(0.0, 1.0);
    final wiggle = math.sin(
          fallT * math.pi * FallingStarOverlay.snakeWaves * 2 +
              widget.wavePhase,
        ) *
        FallingStarOverlay.snakeAmplitude *
        envelope;
    return Offset(base.dx + wiggle, base.dy);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _controller.value;
            late final Offset pos;
            late final double opacity;
            late final double scale;
            late final double rotation;

            if (_isShaking) {
              pos = widget.from + _shakeOffset(t);
              opacity = 1;
              scale = 1;
              rotation = 0;
            } else {
              final fallT = ((t - FallingStarOverlay.shakeFraction) /
                      (1 - FallingStarOverlay.shakeFraction))
                  .clamp(0.0, 1.0);
              pos = _snakePosition(fallT);
              opacity = fallT < 0.82 ? 1.0 : (1 - (fallT - 0.82) / 0.18);
              scale = 1.05 - fallT * 0.25;
              rotation = fallT * math.pi * 1.4 + widget.wavePhase * 0.2;
            }

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: pos.dx - widget.size / 2,
                  top: pos.dy - widget.size / 2,
                  child: Opacity(
                    opacity: opacity.clamp(0.0, 1.0),
                    child: Transform.rotate(
                      angle: rotation,
                      child: Transform.scale(
                        scale: scale,
                        child: Icon(
                          Icons.star_rounded,
                          size: widget.size,
                          color: widget.color,
                          shadows: [
                            Shadow(
                              color: widget.color.withValues(alpha: 0.45),
                              blurRadius: 10,
                            ),
                            const Shadow(
                              color: Colors.black26,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
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
