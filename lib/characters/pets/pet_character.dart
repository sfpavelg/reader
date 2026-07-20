import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../widgets/app_feedback.dart';
import '../kolobok/kolobok_character.dart';
import 'pet_catalog.dart';

/// Интерактивный питомец: Попрыгунчик = Колобок, остальные — свои головастики.
class PetCharacter extends StatelessWidget {
  const PetCharacter({
    super.key,
    required this.petId,
    required this.level,
    this.size = 240,
    this.onAction,
  });

  final PetId petId;
  final int level;
  final double size;
  final ValueChanged<KolobokAction>? onAction;

  @override
  Widget build(BuildContext context) {
    if (petId == PetId.poprygunchik) {
      return KolobokCharacter(
        stage: PetCatalog.stageForLevel(level),
        size: size,
        onAction: onAction,
      );
    }
    return _SpeciesPetCharacter(
      petId: petId,
      level: level.clamp(1, 6),
      size: size,
      onAction: onAction,
    );
  }
}

class _SpeciesPetCharacter extends StatefulWidget {
  const _SpeciesPetCharacter({
    required this.petId,
    required this.level,
    required this.size,
    this.onAction,
  });

  final PetId petId;
  final int level;
  final double size;
  final ValueChanged<KolobokAction>? onAction;

  @override
  State<_SpeciesPetCharacter> createState() => _SpeciesPetCharacterState();
}

class _SpeciesPetCharacterState extends State<_SpeciesPetCharacter>
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

  Future<void> _play(KolobokAction action) async {
    await AppFeedback.tap();
    widget.onAction?.call(action);
    setState(() => _currentAction = action);
    _action
      ..stop()
      ..reset();
    await _action.forward();
    if (mounted) setState(() => _currentAction = KolobokAction.idle);
  }

  @override
  Widget build(BuildContext context) {
    final def = PetCatalog.byId(widget.petId);
    final stage = PetCatalog.stageForLevel(widget.level);

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
        final showWink = _currentAction == KolobokAction.wink &&
            actionT > 0.18 &&
            actionT < 0.68;
        final shadowScale = 1 -
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
                    width: widget.size * 0.42,
                    height: widget.size * 0.06,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(0, jumpY + joyY),
                child: Transform.rotate(
                  angle: spinAngle,
                  child: Transform.scale(
                    scale: idleScale,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (details) {
                        final local = details.localPosition;
                        final w = widget.size;
                        final h = widget.size;
                        if (local.dy < h * 0.42) {
                          _play(KolobokAction.wink);
                        } else if (local.dx < w * 0.28) {
                          _play(KolobokAction.spin);
                        } else if (local.dx > w * 0.72) {
                          _play(KolobokAction.joy);
                        } else {
                          _play(KolobokAction.jump);
                        }
                      },
                      child: CustomPaint(
                        size: Size.square(widget.size),
                        painter: _SpeciesPainter(
                          petId: widget.petId,
                          color: Color.lerp(
                            def.color,
                            stage.color,
                            (widget.level - 1) / 5,
                          )!,
                          level: widget.level,
                          wink: showWink,
                        ),
                      ),
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

class _SpeciesPainter extends CustomPainter {
  _SpeciesPainter({
    required this.petId,
    required this.color,
    required this.level,
    required this.wink,
  });

  final PetId petId;
  final Color color;
  final int level;
  final bool wink;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.52);
    final bodyScale = 0.58 + level * 0.055;
    final radius = size.width * bodyScale / 2;
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.45),
        radius: 0.9,
        colors: [
          color.withValues(alpha: 0.95),
          color,
          Color.alphaBlend(Colors.black.withValues(alpha: 0.12), color),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    _paintSpeciesExtras(canvas, center, radius, bodyPaint);

    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: radius * 1.55,
        height: radius * (level <= 2 ? 1.25 : 1.45),
      ),
      Radius.circular(radius),
    );
    canvas.drawRRect(body, bodyPaint);

    if (level <= 2) {
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

    if (level >= 3) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(center.dx - radius * 0.65, center.dy + radius * 0.12),
          width: radius * 0.34,
          height: radius * 0.56,
        ),
        bodyPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(center.dx + radius * 0.65, center.dy + radius * 0.12),
          width: radius * 0.34,
          height: radius * 0.56,
        ),
        bodyPaint,
      );
    }

    canvas.drawCircle(
      Offset(center.dx - radius * 0.2, center.dy - radius * 0.25),
      radius * 0.22,
      Paint()..color = Colors.white.withValues(alpha: 0.28),
    );

    _paintFace(canvas, center, radius);
  }

  void _paintSpeciesExtras(
    Canvas canvas,
    Offset center,
    double radius,
    Paint bodyPaint,
  ) {
    switch (petId) {
      case PetId.pyatochok:
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(center.dx - radius * 0.55, center.dy - radius * 0.7),
            width: radius * 0.45,
            height: radius * 0.55,
          ),
          bodyPaint,
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(center.dx + radius * 0.55, center.dy - radius * 0.7),
            width: radius * 0.45,
            height: radius * 0.55,
          ),
          bodyPaint,
        );
      case PetId.sova:
        final ear = Paint()..color = color;
        final left = Path()
          ..moveTo(center.dx - radius * 0.55, center.dy - radius * 0.35)
          ..lineTo(center.dx - radius * 0.85, center.dy - radius * 1.05)
          ..lineTo(center.dx - radius * 0.15, center.dy - radius * 0.55)
          ..close();
        final right = Path()
          ..moveTo(center.dx + radius * 0.55, center.dy - radius * 0.35)
          ..lineTo(center.dx + radius * 0.85, center.dy - radius * 1.05)
          ..lineTo(center.dx + radius * 0.15, center.dy - radius * 0.55)
          ..close();
        canvas.drawPath(left, ear);
        canvas.drawPath(right, ear);
      case PetId.oslik:
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(center.dx - radius * 0.7, center.dy - radius * 0.85),
            width: radius * 0.32,
            height: radius * 0.95,
          ),
          bodyPaint,
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(center.dx + radius * 0.7, center.dy - radius * 0.85),
            width: radius * 0.32,
            height: radius * 0.95,
          ),
          bodyPaint,
        );
      case PetId.poprygunchik:
        break;
    }
  }

  void _paintFace(Canvas canvas, Offset center, double radius) {
    final eyeY = center.dy - radius * (level <= 2 ? 0.15 : 0.2);
    final eyeGap = radius * 0.32;
    final eyeR = radius * (0.16 + level * 0.01);

    void drawEye(Offset c, {required bool closed}) {
      if (closed) {
        final p = Paint()
          ..color = const Color(0xFF3E2723)
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(c.dx - eyeR * 0.7, c.dy),
          Offset(c.dx + eyeR * 0.7, c.dy),
          p,
        );
        return;
      }
      canvas.drawCircle(c, eyeR, Paint()..color = Colors.white);
      canvas.drawCircle(
        Offset(c.dx + eyeR * 0.1, c.dy + eyeR * 0.08),
        eyeR * 0.55,
        Paint()..color = const Color(0xFF3E2723),
      );
    }

    drawEye(Offset(center.dx - eyeGap, eyeY), closed: wink);
    drawEye(Offset(center.dx + eyeGap, eyeY), closed: false);

    switch (petId) {
      case PetId.pyatochok:
        final snout = Rect.fromCenter(
          center: Offset(center.dx, center.dy + radius * 0.28),
          width: radius * 0.7,
          height: radius * 0.45,
        );
        canvas.drawOval(snout, Paint()..color = const Color(0xFFFFB0C4));
        canvas.drawCircle(
          Offset(center.dx - radius * 0.12, center.dy + radius * 0.28),
          radius * 0.06,
          Paint()..color = const Color(0xFFE91E63),
        );
        canvas.drawCircle(
          Offset(center.dx + radius * 0.12, center.dy + radius * 0.28),
          radius * 0.06,
          Paint()..color = const Color(0xFFE91E63),
        );
      case PetId.sova:
        final beak = Path()
          ..moveTo(center.dx, center.dy + radius * 0.05)
          ..lineTo(center.dx - radius * 0.14, center.dy + radius * 0.32)
          ..lineTo(center.dx + radius * 0.14, center.dy + radius * 0.32)
          ..close();
        canvas.drawPath(beak, Paint()..color = const Color(0xFFFFB300));
      case PetId.oslik:
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(center.dx, center.dy + radius * 0.35),
            width: radius * 0.55,
            height: radius * 0.35,
          ),
          0.15,
          math.pi - 0.3,
          false,
          Paint()
            ..color = const Color(0xFF3E2723)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..strokeCap = StrokeCap.round,
        );
      case PetId.poprygunchik:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _SpeciesPainter oldDelegate) {
    return oldDelegate.petId != petId ||
        oldDelegate.color != color ||
        oldDelegate.level != level ||
        oldDelegate.wink != wink;
  }
}
