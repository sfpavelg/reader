import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Точка на дуге обмена двух соседних ячеек (по часовой стрелке).
Offset swapArcPosition({
  required Offset start,
  required Offset end,
  required double t,
}) {
  final center = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
  final radius = (start - center).distance;
  var angleStart = math.atan2(start.dy - center.dy, start.dx - center.dx);
  var angleEnd = math.atan2(end.dy - center.dy, end.dx - center.dx);
  while (angleEnd > angleStart) {
    angleEnd -= 2 * math.pi;
  }
  final angle = angleStart + (angleEnd - angleStart) * t;
  return Offset(
    center.dx + radius * math.cos(angle),
    center.dy + radius * math.sin(angle),
  );
}

/// Пульсация подсветки: 3 цикла (0.25 с загорание + 0.25 с потухание).
const bookmarkMatchHighlightCycles = 3;
const bookmarkMatchHighlightHalfCycleMs = 250;

double matchHighlightPulse(double t, {int? cycles}) {
  final count = cycles ?? bookmarkMatchHighlightCycles;
  final local = (t * count) % 1.0;
  final triangle = local < 0.5 ? local * 2 : (1 - local) * 2;
  return 0.1 + 0.9 * triangle;
}

Duration matchHighlightDuration({int? cycles}) {
  final count = cycles ?? bookmarkMatchHighlightCycles;
  return Duration(
    milliseconds: count * bookmarkMatchHighlightHalfCycleMs * 2,
  );
}

const bookmarkSwapDuration = Duration(milliseconds: 640);
const bookmarkMatchHighlightDuration = Duration(milliseconds: 1500);
const bookmarkStartHintDuration = Duration(milliseconds: 750);
const bookmarkGravityDuration = Duration(milliseconds: 380);

Duration gravityDurationForRows(int maxRows) {
  if (maxRows <= 1) return bookmarkGravityDuration;
  return Duration(
    milliseconds: (bookmarkGravityDuration.inMilliseconds * (0.65 + maxRows * 0.12))
        .round()
        .clamp(320, 720),
  );
}
