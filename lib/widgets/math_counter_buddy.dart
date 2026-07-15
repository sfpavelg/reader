import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Как двигается человечек в мат.визуале.
enum MathBuddyMotion {
  /// На месте, слегка подпрыгивает.
  bounce,

  /// Бежит влево — «прибегает» к левой группе (после «+»).
  runIn,

  /// Бежит вправо — «убегает» (после «−»).
  runAway,
}

/// Маленький пляшущий человечек или зверёк для тренажёра «Считаем».
class MathCounterBuddy extends StatefulWidget {
  const MathCounterBuddy({
    super.key,
    required this.variant,
    this.size = 46,
    this.color,
    this.motion = MathBuddyMotion.bounce,
  });

  final int variant;
  final double size;
  final Color? color;
  final MathBuddyMotion motion;

  @override
  State<MathCounterBuddy> createState() => _MathCounterBuddyState();
}

class _MathCounterBuddyState extends State<MathCounterBuddy>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    final phase = (widget.variant % 5) * 0.17;
    final duration = switch (widget.motion) {
      MathBuddyMotion.bounce => 700 + (widget.variant % 3) * 90,
      MathBuddyMotion.runIn ||
      MathBuddyMotion.runAway =>
        480 + (widget.variant % 4) * 40,
    };
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: duration),
    )..value = phase;
    _controller.repeat(reverse: widget.motion == MathBuddyMotion.bounce);
  }

  @override
  void didUpdateWidget(covariant MathCounterBuddy oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.motion != widget.motion) {
      _controller.repeat(reverse: widget.motion == MathBuddyMotion.bounce);
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
    final palette = _buddyPalette(widget.variant, widget.color ?? colors.primary);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final paint = CustomPaint(
          size: Size(widget.size, widget.size * 1.15),
          painter: _BuddyPainter(
            kind: BuddyKind.values[widget.variant % BuddyKind.values.length],
            palette: palette,
            armWave: math.sin(t * math.pi * 2 + widget.variant * 0.5),
          ),
        );

        return switch (widget.motion) {
          MathBuddyMotion.bounce => Transform.translate(
              offset: Offset(0, -math.sin(t * math.pi) * widget.size * 0.1),
              child: Transform.rotate(
                angle: math.sin(t * math.pi * 2 + widget.variant) * 0.12,
                child: paint,
              ),
            ),
          MathBuddyMotion.runIn => _runMotion(
              t: t,
              faceLeft: true,
              child: paint,
            ),
          MathBuddyMotion.runAway => _runMotion(
              t: t,
              faceLeft: false,
              child: paint,
            ),
        };
      },
    );
  }

  Widget _runMotion({
    required double t,
    required bool faceLeft,
    required Widget child,
  }) {
    final phase = (t + widget.variant * 0.13) * 2 * math.pi;
    final stride = math.sin(phase);
    final hop = -math.sin(phase * 2).abs() * widget.size * 0.12;
    final lean = faceLeft ? -0.08 : 0.08;
    final drift = stride * widget.size * 0.16 + (faceLeft ? -1 : 1) * widget.size * 0.06;

    return Transform.translate(
      offset: Offset(drift, hop),
      child: Transform.rotate(
        angle: lean + stride * 0.06,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(faceLeft ? -1.0 : 1.0, 1.0, 1.0),
          child: child,
        ),
      ),
    );
  }
}

enum BuddyKind { person, bunny, bear, kitten, fox }

class _BuddyPalette {
  const _BuddyPalette({
    required this.body,
    required this.head,
    required this.cheek,
    required this.limb,
  });

  final Color body;
  final Color head;
  final Color cheek;
  final Color limb;
}

_BuddyPalette _buddyPalette(int variant, Color base) {
  final hues = [base, Color.lerp(base, Colors.orange, 0.25)!, Color.lerp(base, Colors.purple, 0.2)!, Color.lerp(base, Colors.teal, 0.3)!, Color.lerp(base, Colors.pink, 0.25)!];
  final main = hues[variant % hues.length];
  return _BuddyPalette(
    body: main.withValues(alpha: 0.92),
    head: Color.lerp(main, Colors.white, 0.35)!,
    cheek: Color.lerp(main, Colors.white, 0.55)!,
    limb: Color.lerp(main, Colors.black, 0.25)!,
  );
}

class _BuddyPainter extends CustomPainter {
  const _BuddyPainter({
    required this.kind,
    required this.palette,
    required this.armWave,
  });

  final BuddyKind kind;
  final _BuddyPalette palette;
  final double armWave;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final headR = size.width * 0.22;
    final headCenter = Offset(cx, size.height * 0.28);
    final bodyTop = headCenter.dy + headR * 0.75;
    final bodyBottom = size.height * 0.82;

    _drawEars(canvas, headCenter, headR);
    _drawHead(canvas, headCenter, headR);
    _drawFace(canvas, headCenter, headR);
    _drawBody(canvas, cx, bodyTop, bodyBottom);
    _drawLimbs(canvas, cx, bodyTop, bodyBottom, size.width);
  }

  void _drawEars(Canvas canvas, Offset headCenter, double headR) {
    final paint = Paint()..color = palette.head;
    switch (kind) {
      case BuddyKind.bunny:
        final earW = headR * 0.42;
        final earH = headR * 1.35;
        for (final dx in [-headR * 0.55, headR * 0.55]) {
          final rect = RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: headCenter + Offset(dx, -headR * 0.95),
              width: earW,
              height: earH,
            ),
            Radius.circular(earW),
          );
          canvas.drawRRect(rect, paint);
          canvas.drawRRect(
            rect.deflate(earW * 0.18),
            Paint()..color = palette.cheek.withValues(alpha: 0.8),
          );
        }
      case BuddyKind.bear:
        canvas.drawCircle(headCenter + Offset(-headR * 0.95, -headR * 0.35), headR * 0.34, paint);
        canvas.drawCircle(headCenter + Offset(headR * 0.95, -headR * 0.35), headR * 0.34, paint);
      case BuddyKind.kitten:
        final ear = Path()
          ..moveTo(headCenter.dx - headR * 0.95, headCenter.dy - headR * 0.1)
          ..lineTo(headCenter.dx - headR * 0.45, headCenter.dy - headR * 1.2)
          ..lineTo(headCenter.dx - headR * 0.05, headCenter.dy - headR * 0.35)
          ..close();
        canvas.drawPath(ear, paint);
        canvas.drawPath(ear.shift(Offset(headR * 1.9, 0)), paint);
      case BuddyKind.fox:
        final ear = Path()
          ..moveTo(headCenter.dx - headR * 0.85, headCenter.dy - headR * 0.2)
          ..lineTo(headCenter.dx - headR * 0.35, headCenter.dy - headR * 1.05)
          ..lineTo(headCenter.dx - headR * 0.05, headCenter.dy - headR * 0.25)
          ..close();
        canvas.drawPath(ear, paint);
        canvas.drawPath(ear.shift(Offset(headR * 1.7, 0)), paint);
      case BuddyKind.person:
        break;
    }
  }

  void _drawHead(Canvas canvas, Offset center, double r) {
    canvas.drawCircle(center, r, Paint()..color = palette.head);
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = palette.limb.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.08,
    );
  }

  void _drawFace(Canvas canvas, Offset center, double r) {
    final eyePaint = Paint()..color = palette.limb;
    final eyeY = center.dy - r * 0.05;
    canvas.drawCircle(center + Offset(-r * 0.38, eyeY), r * 0.1, eyePaint);
    canvas.drawCircle(center + Offset(r * 0.38, eyeY), r * 0.1, eyePaint);

    final smile = Path()
      ..moveTo(center.dx - r * 0.35, center.dy + r * 0.28)
      ..quadraticBezierTo(
        center.dx,
        center.dy + r * 0.55 + armWave * r * 0.08,
        center.dx + r * 0.35,
        center.dy + r * 0.28,
      );
    canvas.drawPath(
      smile,
      Paint()
        ..color = palette.limb
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.09
        ..strokeCap = StrokeCap.round,
    );

    if (kind == BuddyKind.kitten || kind == BuddyKind.fox) {
      final whisker = Paint()
        ..color = palette.limb.withValues(alpha: 0.55)
        ..strokeWidth = r * 0.05;
      for (final dy in [-0.08, 0.08]) {
        canvas.drawLine(
          center + Offset(r * 0.45, r * dy),
          center + Offset(r * 1.05, r * (dy + 0.04)),
          whisker,
        );
        canvas.drawLine(
          center + Offset(-r * 0.45, r * dy),
          center + Offset(-r * 1.05, r * (dy + 0.04)),
          whisker,
        );
      }
    }
  }

  void _drawBody(Canvas canvas, double cx, double top, double bottom) {
    final w = (bottom - top) * 0.72;
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, (top + bottom) / 2),
        width: w,
        height: bottom - top,
      ),
      Radius.circular(w * 0.35),
    );
    canvas.drawRRect(rect, Paint()..color = palette.body);
  }

  void _drawLimbs(
    Canvas canvas,
    double cx,
    double top,
    double bottom,
    double width,
  ) {
    final paint = Paint()
      ..color = palette.limb
      ..strokeWidth = width * 0.09
      ..strokeCap = StrokeCap.round;

    final shoulderY = top + (bottom - top) * 0.18;
    final armLift = armWave * width * 0.14;
    canvas.drawLine(
      Offset(cx - width * 0.18, shoulderY),
      Offset(cx - width * 0.42, shoulderY - width * 0.28 - armLift),
      paint,
    );
    canvas.drawLine(
      Offset(cx + width * 0.18, shoulderY),
      Offset(cx + width * 0.42, shoulderY - width * 0.22 + armLift),
      paint,
    );

    final hipY = bottom - width * 0.04;
    final step = math.sin(armWave * math.pi) * width * 0.08;
    canvas.drawLine(
      Offset(cx - width * 0.12, hipY),
      Offset(cx - width * 0.2 - step, bottom + width * 0.02),
      paint,
    );
    canvas.drawLine(
      Offset(cx + width * 0.12, hipY),
      Offset(cx + width * 0.2 + step, bottom + width * 0.02),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _BuddyPainter oldDelegate) =>
      oldDelegate.armWave != armWave || oldDelegate.kind != kind;
}
