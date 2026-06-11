/// Раскладка падающих слогов: отдельные дорожки, без наложения.
abstract final class SyllableBuilderLayout {
  static const blockWidth = 88.0;
  static const blockHeight = 56.0;
  static const fallSpeed = 72.0;
  static const tickMs = 16;

  /// Горизонтальная позиция 0…1 внутри игровой зоны (с учётом ширины блока).
  static double laneXFactor(int laneIndex, int laneCount) {
    if (laneCount <= 1) return 0.5;
    const edge = 0.06;
    final span = 1.0 - 2 * edge;
    return edge + span * (laneIndex / (laneCount - 1));
  }

  /// Стартовая высота: слоги входят по очереди, не все сразу в одной точке.
  static double startY({
    required int sequenceIndex,
    required int syllableCount,
    required double randomOffset,
  }) {
    final stackGap = blockHeight + 28;
    return -blockHeight - sequenceIndex * stackGap - randomOffset * 50;
  }

  /// После ухода за низ экрана — снова сверху, со сдвигом по дорожке.
  static double respawnY(int sequenceIndex) {
    return -blockHeight - sequenceIndex * (blockHeight + 24);
  }
}
