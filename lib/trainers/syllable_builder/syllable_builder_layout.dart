import 'dart:math' as math;

import 'syllable_builder_task.dart';

/// Раскладка падающих слогов: дорожки, покачивание, разведение на пустом поле.
abstract final class SyllableBuilderLayout {
  static const blockWidth = 88.0;
  static const blockHeight = 56.0;
  static const fallSpeed = 110.0;
  static const driftAmplitude = 42.0;
  static const tickMs = 16;
  static const minVerticalGap = blockHeight + 18;
  static const overlapAllowThreshold = 7;

  /// Горизонтальная позиция 0…1 внутри игровой зоны (с учётом ширины блока).
  static double laneXFactor(int laneIndex, int laneCount) {
    if (laneCount <= 1) return 0.5;
    const edge = 0.06;
    final span = 1.0 - 2 * edge;
    return edge + span * (laneIndex / (laneCount - 1));
  }

  /// Случайная позиция для помехи — шире, чем у целевых слогов.
  static double randomXFactor(double randomUnit) {
    const edge = 0.04;
    return edge + randomUnit * (1.0 - 2 * edge);
  }

  /// Стартовая высота: слоги входят по очереди, не все сразу в одной точке.
  static double startY({
    required int stackIndex,
    required double randomOffset,
  }) {
    final stackGap = blockHeight + 28;
    return -blockHeight - stackIndex * stackGap - randomOffset * 60;
  }

  /// После ухода за низ экрана — снова сверху, со сдвигом по дорожке.
  static double respawnY(int stackIndex) {
    return -blockHeight - stackIndex * (blockHeight + 20);
  }

  static double driftOffset(FallingSyllableBlock block) {
    return math.sin(block.xPhase) * driftAmplitude;
  }

  static double baseLeft(double playAreaWidth, double xFactor) {
    return (playAreaWidth - blockWidth) * xFactor;
  }

  static double blockLeft(FallingSyllableBlock block, double playAreaWidth) {
    return baseLeft(playAreaWidth, block.xFactor) + driftOffset(block);
  }

  /// Когда слогов мало — не даём им накладываться по вертикали.
  static void separateSparseBlocks(
    List<FallingSyllableBlock> blocks,
    double playAreaWidth,
  ) {
    final active = blocks.where((b) => !b.collected).toList();
    if (active.length > overlapAllowThreshold) return;

    active.sort((a, b) => a.y.compareTo(b.y));
    for (var i = 1; i < active.length; i++) {
      final upper = active[i - 1];
      final lower = active[i];
      if (!_horizontallyOverlap(upper, lower, playAreaWidth)) continue;

      final minY = upper.y + minVerticalGap;
      if (lower.y < minY) {
        lower.y = minY;
      }
    }
  }

  static bool _horizontallyOverlap(
    FallingSyllableBlock a,
    FallingSyllableBlock b,
    double playAreaWidth,
  ) {
    final leftA = blockLeft(a, playAreaWidth);
    final leftB = blockLeft(b, playAreaWidth);
    return (leftA - leftB).abs() < blockWidth * 0.72;
  }
}
