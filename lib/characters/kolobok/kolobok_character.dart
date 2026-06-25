import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../widgets/app_feedback.dart';
import 'kolobok_stage.dart';

enum KolobokAction { idle, jump, spin, wink, joy }

class KolobokCharacter extends StatefulWidget {
  const KolobokCharacter({
    super.key,
    required this.stage,
    this.size = 240,
    this.onAction,
  });

  final KolobokStage stage;
  final double size;
  final ValueChanged<KolobokAction>? onAction;

  @override
  State<KolobokCharacter> createState() => _KolobokCharacterState();
}

class _KolobokCharacterState extends State<KolobokCharacter>
    with TickerProviderStateMixin {
  late final AnimationController _idle;
  late final AnimationController _action;
  KolobokAction _currentAction = KolobokAction.idle;

  @override
  void initState() {
    super.initState();
    _idle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _action = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
  }

  @override
  void dispose() {
    _idle.dispose();
    _action.dispose();
    super.dispose();
  }

  Future<void> play(KolobokAction action) async {
    await AppFeedback.tap();
    widget.onAction?.call(action);
    setState(() => _currentAction = action);
    _action
      ..stop()
      ..reset();
    await _action.forward();
    if (mounted) {
      setState(() => _currentAction = KolobokAction.idle);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_idle, _action]),
      builder: (context, child) {
        final actionT = _action.value;
        final idleScale = 1 + math.sin(_idle.value * math.pi) * 0.025;
        final jumpY = _currentAction == KolobokAction.jump
            ? -math.sin(actionT * math.pi) * 34
            : 0.0;
        final joyY = _currentAction == KolobokAction.joy
            ? -math.sin(actionT * math.pi * 2) * 8
            : 0.0;
        final spinAngle = _currentAction == KolobokAction.spin
            ? actionT * math.pi * 2
            : 0.0;
        final showWink =
            _currentAction == KolobokAction.wink &&
            actionT > 0.18 &&
            actionT < 0.68;
        final showJoyStar = _currentAction == KolobokAction.joy;
        final shadowScale =
            1 -
            ((_currentAction == KolobokAction.jump)
                ? math.sin(actionT * math.pi) * 0.28
                : 0.0);

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                bottom: widget.size * 0.12,
                child: Transform.scale(
                  scaleX: shadowScale,
                  child: Container(
                    width: widget.size * 0.38,
                    height: widget.size * 0.05,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: widget.size * 0.025,
                          spreadRadius: widget.size * 0.005,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (showJoyStar) _JoyStar(size: widget.size, progress: actionT),
              Transform.translate(
                offset: Offset(0, jumpY + joyY),
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(spinAngle),
                  child: Transform.scale(
                    scale: idleScale,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (widget.stage == KolobokStage.adult)
                          _AdultKolobokLayers(wink: showWink, size: widget.size)
                        else ...[
                          _KolobokBody(stage: widget.stage, size: widget.size),
                          _Eyes(
                            stage: widget.stage,
                            wink: showWink,
                            size: widget.size,
                          ),
                        ],
                        _InteractionZone(
                          label: 'глаза',
                          rect: Rect.fromLTWH(
                            widget.size * 0.31,
                            widget.size * 0.27,
                            widget.size * 0.38,
                            widget.size * 0.18,
                          ),
                          onTap: () => play(KolobokAction.wink),
                        ),
                        _InteractionZone(
                          label: 'прыжок',
                          rect: Rect.fromLTWH(
                            widget.size * 0.25,
                            widget.size * 0.45,
                            widget.size * 0.5,
                            widget.size * 0.32,
                          ),
                          onTap: () => play(KolobokAction.jump),
                        ),
                        _InteractionZone(
                          label: 'крутись',
                          rect: Rect.fromLTWH(
                            0,
                            widget.size * 0.32,
                            widget.size * 0.24,
                            widget.size * 0.42,
                          ),
                          onTap: () => play(KolobokAction.spin),
                        ),
                        _InteractionZone(
                          label: 'радость',
                          rect: Rect.fromLTWH(
                            widget.size * 0.76,
                            widget.size * 0.28,
                            widget.size * 0.24,
                            widget.size * 0.46,
                          ),
                          onTap: () => play(KolobokAction.joy),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _KolobokBody extends StatelessWidget {
  const _KolobokBody({required this.stage, required this.size});

  final KolobokStage stage;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _KolobokBodyPainter(stage),
    );
  }
}

class _AdultKolobokLayers extends StatelessWidget {
  const _AdultKolobokLayers({required this.wink, required this.size});

  static const _base = 'assets/characters/kolobok/stage_06_adult';

  final bool wink;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Image.asset(
              '$_base/body_layer.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
          ),
          Positioned.fill(
            child: Transform.translate(
              offset: Offset(0, -size * 0.035),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 90),
                child: Transform.scale(
                  scale: 0.72,
                  child: Image.asset(
                    wink
                        ? '$_base/eyes_wink_layer.png'
                        : '$_base/eyes_open_layer.png',
                    key: ValueKey(wink),
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Transform.translate(
              offset: Offset(0, size * 0.11),
              child: Transform.scale(
                scale: 0.68,
                child: Image.asset(
                  '$_base/mouth_smile_layer.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KolobokBodyPainter extends CustomPainter {
  _KolobokBodyPainter(this.stage);

  final KolobokStage stage;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.52);
    final bodyPaint = Paint()
      ..shader =
          RadialGradient(
            center: const Alignment(-0.35, -0.45),
            radius: 0.9,
            colors: [
              stage.color.withValues(alpha: 0.95),
              stage.color,
              Color.alphaBlend(
                Colors.deepOrange.withValues(alpha: 0.35),
                stage.color,
              ),
            ],
          ).createShader(
            Rect.fromCircle(center: center, radius: size.width * 0.36),
          );

    final bodyScale = 0.58 + stage.level * 0.055;
    final radius = size.width * bodyScale / 2;
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: radius * 1.55,
        height: radius * (stage.level <= 2 ? 1.25 : 1.45),
      ),
      Radius.circular(radius),
    );

    if (stage.level >= 3) {
      final armPaint = Paint()..shader = bodyPaint.shader;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(center.dx - radius * 0.65, center.dy + radius * 0.12),
          width: radius * 0.34,
          height: radius * 0.56,
        ),
        armPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(center.dx + radius * 0.65, center.dy + radius * 0.12),
          width: radius * 0.34,
          height: radius * 0.56,
        ),
        armPaint,
      );
    }

    canvas.drawRRect(body, bodyPaint);

    if (stage.level <= 2) {
      final tailPath = Path()
        ..moveTo(center.dx + radius * 0.4, center.dy + radius * 0.18)
        ..quadraticBezierTo(
          center.dx + radius * 1.05,
          center.dy + radius * 0.15,
          center.dx + radius * 0.9,
          center.dy + radius * 0.62,
        )
        ..quadraticBezierTo(
          center.dx + radius * 0.58,
          center.dy + radius * 0.42,
          center.dx + radius * 0.35,
          center.dy + radius * 0.28,
        );
      canvas.drawPath(tailPath, bodyPaint);
    }

    canvas.drawCircle(
      Offset(center.dx - radius * 0.2, center.dy - radius * 0.25),
      radius * 0.22,
      Paint()..color = Colors.white.withValues(alpha: 0.28),
    );
  }

  @override
  bool shouldRepaint(covariant _KolobokBodyPainter oldDelegate) {
    return oldDelegate.stage != stage;
  }
}

class _Eyes extends StatelessWidget {
  const _Eyes({required this.stage, required this.wink, required this.size});

  final KolobokStage stage;
  final bool wink;
  final double size;

  @override
  Widget build(BuildContext context) {
    final eyeTop = size * (stage.level <= 2 ? 0.35 : 0.33);
    final eyeGap = size * 0.08;
    final eyeSize = size * (0.08 + stage.level * 0.006);

    return Positioned(
      top: eyeTop,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          wink ? _WinkEye(size: eyeSize) : _OpenEye(size: eyeSize),
          SizedBox(width: eyeGap),
          _OpenEye(size: eyeSize),
        ],
      ),
    );
  }
}

class _OpenEye extends StatelessWidget {
  const _OpenEye({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size * 1.12,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF5B2A1C), width: 2),
      ),
      child: Align(
        alignment: const Alignment(0.18, 0.22),
        child: Container(
          width: size * 0.48,
          height: size * 0.52,
          decoration: const BoxDecoration(
            color: Color(0xFF5A2D1D),
            shape: BoxShape.circle,
          ),
          child: Align(
            alignment: const Alignment(-0.3, -0.4),
            child: Container(
              width: size * 0.16,
              height: size * 0.16,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WinkEye extends StatelessWidget {
  const _WinkEye({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 1.12),
      painter: _WinkEyePainter(),
    );
  }
}

class _WinkEyePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF5B2A1C)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(size.width * 0.1, size.height * 0.55)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.85,
        size.width * 0.9,
        size.height * 0.55,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _JoyStar extends StatelessWidget {
  const _JoyStar({required this.size, required this.progress});

  final double size;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final angle = -math.pi * 0.8 + progress * math.pi * 2.4;
    return Transform.translate(
      offset: Offset(
        math.cos(angle) * size * 0.38,
        math.sin(angle) * size * 0.28,
      ),
      child: Transform.rotate(
        angle: angle,
        child: Image.asset(
          progress < 0.55
              ? 'assets/characters/kolobok/effects/comet_layer.png'
              : 'assets/characters/kolobok/effects/star_layer.png',
          width: size * (progress < 0.55 ? 0.34 : 0.18),
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}

class _InteractionZone extends StatelessWidget {
  const _InteractionZone({
    required this.label,
    required this.rect,
    required this.onTap,
  });

  final String label;
  final Rect rect;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Positioned.fromRect(
      rect: rect,
      child: Tooltip(
        message: label,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: onTap,
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}
