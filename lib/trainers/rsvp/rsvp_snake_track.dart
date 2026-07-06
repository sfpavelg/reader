import 'dart:math' as math;
import 'dart:ui';

/// Замкнутый змеевидный путь: головной слог ведёт паровоз.
class RsvpSnakeTrack {
  RsvpSnakeTrack({
    required this.laneWidth,
    required this.laneHeight,
    required this.carWidth,
    required this.carHeight,
    required this.carGap,
    this.rowGap = 8,
    this.padding = 8,
  }) : _segments = _buildSegments(
          laneWidth: laneWidth,
          laneHeight: laneHeight,
          carWidth: carWidth,
          carHeight: carHeight,
          rowGap: rowGap,
          padding: padding,
        );

  final double laneWidth;
  final double laneHeight;
  final double carWidth;
  final double carHeight;
  final double carGap;
  final double rowGap;
  final double padding;

  final List<_SnakeSegment> _segments;

  double get pitch => carWidth + carGap;

  /// Длина одного полного цикла по видимому пути (без скрытых участков).
  double get cycleLength =>
      _segments.fold(0.0, (sum, segment) => sum + segment.length);

  /// @deprecated Используйте [cycleLength].
  double get loopLength => cycleLength;

  int get rowCount {
    if (laneHeight < carHeight) return 1;
    return math.max(
      1,
      ((laneHeight - carHeight) / rowStride).floor() + 1,
    );
  }

  double get rowStride => carHeight + rowGap;

  double get horizontalTravel => laneWidth + carWidth;

  double get _rowsContentHeight =>
      rowCount * carHeight + (rowCount - 1) * rowGap;

  double get _verticalInset => (laneHeight - _rowsContentHeight) / 2;

  double rowY(int row) => _verticalInset + row * rowStride;

  /// Горизонтальный цикл одной строки (без вертикали).
  double get rowLoopLength => horizontalTravel;

  /// Позиция вагона на змейке; каждый вагон оборачивается сам, не дожидаясь хвоста.
  Offset snakeCarPosition(double carDistance) {
    if (_segments.isEmpty) return Offset.zero;
    if (carDistance < 0) {
      return _segments.first.pointAt(0);
    }

    var d = carDistance;
    final cycle = cycleLength;
    if (cycle > 0) {
      d = d % cycle;
    }
    return _positionAlongPath(d);
  }

  Offset positionAt(double distance) => snakeCarPosition(distance);

  bool intersectsLane(Offset topLeft) {
    final left = topLeft.dx;
    final right = left + carWidth;
    final top = topLeft.dy;
    final bottom = top + carHeight;
    return right > 0 &&
        left < laneWidth &&
        bottom > 0 &&
        top < laneHeight;
  }

  /// Слог рисуем только когда левый край внутри поля — без «хвоста» за левой границей.
  bool visibleInLane(Offset topLeft) {
    if (!intersectsLane(topLeft)) return false;
    return topLeft.dx >= 0;
  }

  /// @deprecated Используйте [intersectsLane].
  bool isOnLane(Offset topLeft) => intersectsLane(topLeft);

  /// Позиция слога в «Суматохе» на фиксированной строке.
  Offset chaosCarPositionAt({
    required int row,
    required double distance,
  }) {
    return chaosCarPositionsAt(row: row, distance: distance).first;
  }

  /// Позиции слога с бесшовным переносом через край (LTR: правый → левый).
  List<Offset> chaosCarPositionsAt({
    required int row,
    required double distance,
    bool crossRowWrap = false,
    int? wrapRow,
  }) {
    final y = rowY(row);
    if (row.isEven) {
      return _chaosLtrPositions(
        y: y,
        row: row,
        distance: distance,
        crossRowWrap: crossRowWrap,
        wrapRow: wrapRow,
      );
    }
    return _chaosRtlPositions(
      y: y,
      row: row,
      distance: distance,
      crossRowWrap: crossRowWrap,
      wrapRow: wrapRow,
    );
  }

  int _defaultWrapRow(int row, bool crossRowWrap) {
    if (!crossRowWrap) return row;
    if (row + 1 < rowCount) return row + 1;
    if (row == rowCount - 1) return 0;
    return row;
  }

  List<Offset> _chaosLtrPositions({
    required double y,
    required int row,
    required double distance,
    required bool crossRowWrap,
    int? wrapRow,
  }) {
    final travel = horizontalTravel;
    final targetRow = wrapRow ?? _defaultWrapRow(row, crossRowWrap);
    final onLastLtrOverlap =
        crossRowWrap && row == rowCount - 1 && row.isEven && distance > laneWidth;
    final s = onLastLtrOverlap
        ? distance
        : (distance < travel ? distance : distance % travel);
    final x = -carWidth + s;

    if (s <= laneWidth) {
      return [Offset(x, y)];
    }

    final overflow = s - laneWidth;
    if (crossRowWrap) {
      // Последняя LTR-строка → строка 0: ghost входит слева (как при wrapRow == null).
      if (row == rowCount - 1 &&
          row.isEven &&
          (wrapRow == null || wrapRow == 0)) {
        return [Offset(x, y), Offset(overflow - carWidth, rowY(0))];
      }
      return [Offset(x, y), Offset(laneWidth - overflow, rowY(targetRow))];
    }
    return [Offset(x, y), Offset(overflow - carWidth, y)];
  }

  List<Offset> _chaosRtlPositions({
    required double y,
    required int row,
    required double distance,
    required bool crossRowWrap,
    int? wrapRow,
  }) {
    final travel = horizontalTravel;
    final s = distance < travel ? distance : distance % travel;
    final x = laneWidth - carWidth - s;
    final leftExitStart = laneWidth - carWidth;
    final targetRow = wrapRow ?? _defaultWrapRow(row, crossRowWrap);

    if (crossRowWrap && s > leftExitStart) {
      final leftOverflow = s - leftExitStart;
      return [Offset(x, y), Offset(leftOverflow - carWidth, rowY(targetRow))];
    }

    if (s <= laneWidth) {
      return [Offset(x, y)];
    }

    final overflow = s - laneWidth;
    return [Offset(x, y), Offset(laneWidth - overflow, y)];
  }

  Offset _positionAlongPath(double d) {
    for (final segment in _segments) {
      if (d <= segment.length + 1e-9) return segment.pointAt(d);
      d -= segment.length;
    }
    return _segments.last.pointAt(_segments.last.length);
  }

  static List<_SnakeSegment> _buildSegments({
    required double laneWidth,
    required double laneHeight,
    required double carWidth,
    required double carHeight,
    required double rowGap,
    required double padding,
  }) {
    if (laneWidth <= 0 || laneHeight <= 0) return const [];

    final rowStride = carHeight + rowGap;
    final rows = math.max(
      1,
      ((laneHeight - carHeight) / rowStride).floor() + 1,
    );
    final contentHeight = rows * carHeight + (rows - 1) * rowGap;
    final topInset = (laneHeight - contentHeight) / 2;
    final ltrTravel = laneWidth + carWidth;
    final rtlTravel = laneWidth;

    final segments = <_SnakeSegment>[];

    for (var row = 0; row < rows; row++) {
      final y = topInset + row * rowStride;
      final ltr = row.isEven;

      segments.add(
        _SnakeSegment.horizontal(
          y: y,
          ltr: ltr,
          length: ltr ? ltrTravel : rtlTravel,
          laneWidth: laneWidth,
          carWidth: carWidth,
        ),
      );

      if (row < rows - 1) {
        // Зеркально правому углу: горизонталь уходит за край, спуск — у внутренней грани.
        final x = ltr ? laneWidth - carWidth : 0.0;
        segments.add(
          _SnakeSegment.verticalDown(
            x: x,
            yStart: y + carHeight,
            length: rowGap,
          ),
        );
      }
    }

    return segments;
  }
}

class _SnakeSegment {
  const _SnakeSegment._({
    required this.length,
    required this.pointAt,
  });

  factory _SnakeSegment.horizontal({
    required double y,
    required bool ltr,
    required double length,
    required double laneWidth,
    required double carWidth,
  }) {
    return _SnakeSegment._(
      length: length,
      pointAt: (t) {
        final x = ltr ? -carWidth + t : laneWidth - carWidth - t;
        return Offset(x, y);
      },
    );
  }

  factory _SnakeSegment.verticalDown({
    required double x,
    required double yStart,
    required double length,
  }) {
    return _SnakeSegment._(
      length: length,
      pointAt: (t) => Offset(x, yStart + t),
    );
  }

  final double length;
  final Offset Function(double t) pointAt;
}
