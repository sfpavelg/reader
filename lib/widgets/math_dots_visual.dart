import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'math_counter_buddy.dart';

/// Персонажи для «Считаем» и «Группами».
class MathDotsVisual extends StatelessWidget {
  const MathDotsVisual({
    super.key,
    this.dotCount,
    this.rows,
    this.cols,
    this.color,
    this.buddySize = 46,
    this.maxWidth = double.infinity,
    this.maxHeight = double.infinity,
  }) : assert(
          (dotCount != null) ^ (rows != null && cols != null),
          'Use dotCount or rows+cols',
        );

  const MathDotsVisual.count({
    super.key,
    required int count,
    this.color,
    this.buddySize = 46,
    this.maxWidth = double.infinity,
    this.maxHeight = double.infinity,
  })  : dotCount = count,
        rows = null,
        cols = null;

  const MathDotsVisual.grid({
    super.key,
    required int rows,
    required int cols,
    this.color,
    this.buddySize = 38,
    this.maxWidth = double.infinity,
    this.maxHeight = double.infinity,
  })  : dotCount = null,
        rows = rows,
        cols = cols;

  final int? dotCount;
  final int? rows;
  final int? cols;
  final Color? color;
  final double buddySize;
  final double maxWidth;
  final double maxHeight;

  static const _hSpacing = 6.0;
  static const _vSpacing = 8.0;
  static const _wrapSpacing = 8.0;
  /// CustomPaint 1.15× size + небольшой запас на подпрыгивание.
  static const _buddyHeightFactor = 1.22;

  static double _spaceCap(double maxWidth, double maxHeight) {
    if (maxWidth.isFinite && maxHeight.isFinite && maxWidth > 0 && maxHeight > 0) {
      return math.min(maxWidth, maxHeight);
    }
    return 120;
  }

  static double _fitGridBuddySize({
    required int rows,
    required int cols,
    required double maxWidth,
    required double maxHeight,
  }) {
    if (maxWidth.isFinite &&
        maxHeight.isFinite &&
        maxWidth > 0 &&
        maxHeight > 0) {
      final byWidth = (maxWidth - (cols - 1) * _hSpacing) / cols;
      final byHeight = (maxHeight - (rows - 1) * _vSpacing) /
          (rows * _buddyHeightFactor);
      return math.min(byWidth, byHeight).clamp(10.0, _spaceCap(maxWidth, maxHeight));
    }

    final total = rows * cols;
    if (total <= 16) return 38;
    if (total <= 30) return 28;
    if (total <= 56) return 22;
    return 16;
  }

  static ({int cols, double size}) _bestWrapLayout({
    required int count,
    required double maxWidth,
    required double maxHeight,
  }) {
    if (count <= 0) return (cols: 1, size: 10.0);

    if (!maxWidth.isFinite ||
        !maxHeight.isFinite ||
        maxWidth <= 0 ||
        maxHeight <= 0) {
      return (cols: math.min(count, 5), size: 46.0);
    }

    var bestCols = 1;
    var bestSize = 10.0;
    final cap = _spaceCap(maxWidth, maxHeight);

    for (var cols = 1; cols <= count; cols++) {
      final rowCount = (count / cols).ceil();
      final byWidth = (maxWidth - (cols - 1) * _wrapSpacing) / cols;
      final byHeight = (maxHeight - (rowCount - 1) * _wrapSpacing) /
          (rowCount * _buddyHeightFactor);
      final size = math.min(byWidth, byHeight);
      if (size > bestSize) {
        bestSize = size;
        bestCols = cols;
      }
    }

    return (cols: bestCols, size: bestSize.clamp(10.0, cap));
  }

  Widget _centerInBox({required Widget child}) {
    if (maxWidth.isFinite &&
        maxHeight.isFinite &&
        maxWidth > 0 &&
        maxHeight > 0) {
      return SizedBox(
        width: maxWidth,
        height: maxHeight,
        child: Center(child: child),
      );
    }
    return Center(child: child);
  }

  Widget _buildBuddyGrid({
    required int itemCount,
    required int cols,
    required double size,
    required int startVariant,
  }) {
    final rowCount = (itemCount / cols).ceil();
    var index = 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var r = 0; r < rowCount; r++)
          Padding(
            padding: EdgeInsets.only(bottom: r < rowCount - 1 ? _wrapSpacing : 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var c = 0; c < cols && index < itemCount; c++) ...[
                  if (c > 0) const SizedBox(width: _wrapSpacing),
                  MathCounterBuddy(
                    variant: startVariant + index++,
                    size: size,
                    color: color,
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (rows != null && cols != null) {
      final gridRows = rows!;
      final gridCols = cols!;
      final size = _fitGridBuddySize(
        rows: gridRows,
        cols: gridCols,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );
      var index = 0;
      return _centerInBox(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var r = 0; r < gridRows; r++)
              Padding(
                padding:
                    EdgeInsets.only(bottom: r < gridRows - 1 ? _vSpacing : 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var c = 0; c < gridCols; c++) ...[
                      if (c > 0) const SizedBox(width: _hSpacing),
                      MathCounterBuddy(
                        variant: index++,
                        size: size,
                        color: color,
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      );
    }

    final count = dotCount ?? 0;
    final layout = _bestWrapLayout(
      count: count,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
    return _centerInBox(
      child: _buildBuddyGrid(
        itemCount: count,
        cols: layout.cols,
        size: layout.size,
        startVariant: 0,
      ),
    );
  }
}

/// Группы человечков: [left] ⊕ [right] для сложения или вычитания.
class MathAddendsVisual extends StatelessWidget {
  const MathAddendsVisual({
    super.key,
    required this.left,
    required this.right,
    this.operatorSymbol = '+',
    this.rightMotion = MathBuddyMotion.runIn,
    this.color,
    this.maxWidth = double.infinity,
    this.maxHeight = double.infinity,
  });

  /// Сложение: левые прыгают, правые прибегают слева направо к ним.
  const MathAddendsVisual.addition({
    super.key,
    required this.left,
    required this.right,
    this.color,
    this.maxWidth = double.infinity,
    this.maxHeight = double.infinity,
  })  : operatorSymbol = '+',
        rightMotion = MathBuddyMotion.runIn;

  /// Вычитание: левые прыгают, после «−» убегают вправо.
  const MathAddendsVisual.subtraction({
    super.key,
    required this.left,
    required this.right,
    this.color,
    this.maxWidth = double.infinity,
    this.maxHeight = double.infinity,
  })  : operatorSymbol = '−',
        rightMotion = MathBuddyMotion.runAway;

  final int left;
  final int right;
  final String operatorSymbol;
  final MathBuddyMotion rightMotion;
  final Color? color;
  final double maxWidth;
  final double maxHeight;

  static const _hGap = 4.0;
  static const _opBudget = 44.0;
  static const _buddyHeightFactor = 1.22;

  /// Размер так, чтобы обе группы и знак поместились в один ряд.
  double _fitBuddySize() {
    final total = left + right;
    if (total <= 0) return 24.0;

    if (!maxWidth.isFinite ||
        !maxHeight.isFinite ||
        maxWidth <= 0 ||
        maxHeight <= 0) {
      return total <= 6 ? 42.0 : total <= 12 ? 32.0 : 24.0;
    }

    final gaps = math.max(0, left - 1) + math.max(0, right - 1);
    final byWidth = (maxWidth - _opBudget - gaps * _hGap) / total;
    final byHeight = maxHeight / _buddyHeightFactor;
    final cap = math.min(maxWidth * 0.45, maxHeight * 0.9);
    return math.min(byWidth, byHeight).clamp(10.0, cap);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final buddySize = _fitBuddySize();

    final opStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w900,
          color: colors.primary,
          fontSize: buddySize * 0.7,
          height: 1,
        );

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _BuddyGroup(
          count: left,
          startVariant: 0,
          size: buddySize,
          color: color,
          motion: MathBuddyMotion.bounce,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: SizedBox(
            height: buddySize,
            child: Center(
              child: Text(operatorSymbol, style: opStyle),
            ),
          ),
        ),
        _BuddyGroup(
          count: right,
          startVariant: left,
          size: buddySize,
          color: color,
          motion: rightMotion,
        ),
      ],
    );

    if (maxWidth.isFinite &&
        maxHeight.isFinite &&
        maxWidth > 0 &&
        maxHeight > 0) {
      return SizedBox(
        width: maxWidth,
        height: maxHeight,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: content,
        ),
      );
    }
    return Center(child: content);
  }
}

class _BuddyGroup extends StatelessWidget {
  const _BuddyGroup({
    required this.count,
    required this.startVariant,
    required this.size,
    required this.motion,
    this.color,
  });

  final int count;
  final int startVariant;
  final double size;
  final MathBuddyMotion motion;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return SizedBox(width: size * 0.6, height: size);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          MathCounterBuddy(
            variant: startVariant + i,
            size: size,
            color: color,
            motion: motion,
          ),
        ],
      ],
    );
  }
}

/// Подсказка «Найди число» — сложение: все человечки в ряд.
/// Известные (слева) прыгают, остальные стоят неподвижно —
/// ребёнок считает стоящих.
class MathMissingAdditionHintVisual extends StatelessWidget {
  const MathMissingAdditionHintVisual({
    super.key,
    required this.total,
    required this.known,
    this.color,
    this.maxWidth = double.infinity,
    this.maxHeight = double.infinity,
  });

  final int total;
  final int known;
  final Color? color;
  final double maxWidth;
  final double maxHeight;

  static const _innerGap = 4.0;
  static const _buddyHeightFactor = 1.22;

  double _fitBuddySize() {
    if (total <= 0) return 12.0;
    if (!maxWidth.isFinite || !maxHeight.isFinite || maxWidth <= 0 || maxHeight <= 0) {
      return total <= 6 ? 42.0 : 28.0;
    }
    final gaps = math.max(0, total - 1);
    final byWidth = (maxWidth - gaps * _innerGap) / total;
    final byHeight = maxHeight / _buddyHeightFactor;
    final cap = math.min(maxHeight * 0.9, maxWidth * 0.55);
    return math.min(byWidth, byHeight).clamp(10.0, cap);
  }

  @override
  Widget build(BuildContext context) {
    final buddySize = _fitBuddySize();
    final knownCount = known.clamp(0, total);
    // Для 2 + ? = 10: слева 8 стоят неподвижно (ответ), справа 2 прыгают.
    final stillCount = total - knownCount;
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: _innerGap),
          MathCounterBuddy(
            variant: i,
            size: buddySize,
            color: color,
            motion: i < stillCount
                ? MathBuddyMotion.still
                : MathBuddyMotion.bounce,
          ),
        ],
      ],
    );
    return _fitInBox(
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      child: content,
    );
  }
}

/// Подсказка «Найди число» — вычитание: через сложение `result + missing`.
class MathMissingSubtractionHintVisual extends StatelessWidget {
  const MathMissingSubtractionHintVisual({
    super.key,
    required this.result,
    required this.missing,
    this.color,
    this.maxWidth = double.infinity,
    this.maxHeight = double.infinity,
  });

  final int result;
  final int missing;
  final Color? color;
  final double maxWidth;
  final double maxHeight;

  static const _innerGap = 4.0;
  static const _opBudget = 44.0;
  static const _buddyHeightFactor = 1.22;

  double _fitBuddySize() {
    final count = result + missing;
    if (count <= 0) return 12.0;
    if (!maxWidth.isFinite || !maxHeight.isFinite || maxWidth <= 0 || maxHeight <= 0) {
      return count <= 6 ? 42.0 : 28.0;
    }
    final gaps = math.max(0, result - 1) + math.max(0, missing - 1);
    final byWidth = (maxWidth - _opBudget - gaps * _innerGap) / count;
    final byHeight = maxHeight / _buddyHeightFactor;
    final cap = math.min(maxHeight * 0.9, maxWidth * 0.55);
    return math.min(byWidth, byHeight).clamp(10.0, cap);
  }

  @override
  Widget build(BuildContext context) {
    final buddySize = _fitBuddySize();
    final colors = Theme.of(context).colorScheme;
    final plusStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w900,
          color: colors.primary,
          fontSize: buddySize * 0.7,
          height: 1,
        );

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _BuddyRowGroup(
          count: result,
          startVariant: 0,
          size: buddySize,
          motion: MathBuddyMotion.bounce,
          color: color,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: SizedBox(
            height: buddySize,
            child: Center(
              child: Text('+', style: plusStyle),
            ),
          ),
        ),
        _BuddyRowGroup(
          count: missing,
          startVariant: result,
          size: buddySize,
          motion: MathBuddyMotion.bounce,
          motionSpeed: 1.85,
          color: color,
        ),
      ],
    );

    return _fitInBox(
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      child: content,
    );
  }
}

Widget _fitInBox({
  required double maxWidth,
  required double maxHeight,
  required Widget child,
}) {
  if (maxWidth.isFinite &&
      maxHeight.isFinite &&
      maxWidth > 0 &&
      maxHeight > 0) {
    return SizedBox(
      width: maxWidth,
      height: maxHeight,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
  return Center(child: child);
}

class _BuddyRowGroup extends StatelessWidget {
  const _BuddyRowGroup({
    required this.count,
    required this.startVariant,
    required this.size,
    required this.motion,
    this.motionSpeed = 1.0,
    this.color,
  });

  static const _innerGap = 4.0;

  final int count;
  final int startVariant;
  final double size;
  final MathBuddyMotion motion;
  final double motionSpeed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) {
      return SizedBox(width: size * 0.6, height: size);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: _innerGap),
          MathCounterBuddy(
            variant: startVariant + i,
            size: size,
            color: color,
            motion: motion,
            motionSpeed: motionSpeed,
          ),
        ],
      ],
    );
  }
}
