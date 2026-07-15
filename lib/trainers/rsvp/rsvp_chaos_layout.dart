import 'dart:math' as math;
import 'dart:ui';

import 'rsvp_snake_track.dart';

/// Горизонтальное положение слога в режиме «Суматоха».
class RsvpChaosCarState {
  RsvpChaosCarState({required this.row, required this.distance});

  int row;
  double distance;
}

/// Раскладка и шаг движения для режима «Суматоха».
abstract final class RsvpChaosLayout {
  static double rtlLeftExitStart(RsvpSnakeTrack track) =>
      track.laneWidth - track.carWidth;

  /// Первый шаг LTR-строки после выхода RTL сверху слева.
  static double ltrEntryStart(RsvpSnakeTrack track) => 1.0;

  static double row0SegmentLength(RsvpSnakeTrack track) =>
      track.horizontalTravel - track.pitch;

  /// LTR-строка после RTL: s от [ltrEntryStart] до правого перехода.
  static double ltrRowAfterRtlLength(RsvpSnakeTrack track) =>
      track.pitch + row0SegmentLength(track) - ltrEntryStart(track);

  /// RTL выезжает влево с ghost на LTR-строку ниже (s = leftExit+1 .. travel-1).
  static double rtlOverlapLength(RsvpSnakeTrack track) =>
      track.horizontalTravel - rtlLeftExitStart(track) - 1;

  /// Overflow на строке 0 при входе слева после правого overlap последней LTR.
  static double row0GhostEntryOverflow(RsvpSnakeTrack track) =>
      track.pitch + ltrEntryStart(track) - 1;

  /// Длина последней LTR-строки до точки входа на строку 0.
  static double ltrLastRowSegmentLength(RsvpSnakeTrack track) {
    final segmentSEnd = track.laneWidth + row0GhostEntryOverflow(track);
    final segmentSStart = rtlOverlapLength(track) + ltrEntryStart(track);
    return segmentSEnd - segmentSStart + 1;
  }

  /// Длина участка пути на одной строке.
  static double rowSegmentLength(int row, RsvpSnakeTrack track) {
    final travel = track.horizontalTravel;

    if (row.isEven) {
      if (row == 0) return row0SegmentLength(track);
      if (row == track.rowCount - 1) {
        return ltrLastRowSegmentLength(track);
      }
      return ltrRowAfterRtlLength(track) - rtlOverlapLength(track);
    }

    // RTL (полный travel — ghost на строку ниже во время left-exit overlap).
    return travel;
  }

  static double multiRowSnakeCycleLength(RsvpSnakeTrack track) {
    var total = 0.0;
    for (var row = 0; row < track.rowCount; row++) {
      total += rowSegmentLength(row, track);
    }
    return total;
  }

  /// Стыковка цикла: конец последней строки → ghost на строке 0.
  static double multiRowSnakeWrapResumeOffset(RsvpSnakeTrack track) {
    final last = track.rowCount - 1;
    if (last.isEven) {
      // LTR последняя: ghost на строке 0 входит слева → начало строки 0.
      return 0;
    }
    final rowEndS = track.horizontalTravel - 1;
    final leftOverflow = rowEndS - rtlLeftExitStart(track);
    return leftOverflow - track.pitch;
  }

  static double normalizeMultiRowSnakeDistance(
    double distance,
    RsvpSnakeTrack track,
  ) {
    final pitch = track.pitch;
    final cycleLen = multiRowSnakeCycleLength(track);
    final resume = multiRowSnakeWrapResumeOffset(track);
    var offset = distance - pitch;
    while (offset < 0) {
      offset += cycleLen;
    }
    while (offset >= cycleLen) {
      offset = resume + (offset - cycleLen);
    }
    return pitch + offset;
  }

  static (int row, double segmentS) decodeMultiRowSnakeOffset(
    double offset,
    RsvpSnakeTrack track,
  ) {
    var remaining = offset;
    for (var row = 0; row < track.rowCount; row++) {
      final len = rowSegmentLength(row, track);
      if (remaining < len) {
        if (row == 0) {
          return (0, track.pitch + remaining);
        }
        if (row.isEven) {
          return (
            row,
            rtlOverlapLength(track) + ltrEntryStart(track) + remaining,
          );
        }
        return (row, remaining);
      }
      remaining -= len;
    }

    final last = track.rowCount - 1;
    return (last, rowSegmentLength(last, track) - 1);
  }

  static int rowForMultiRowSnake(double pathDistance, RsvpSnakeTrack track) {
    final phase = normalizeMultiRowSnakeDistance(pathDistance, track);
    return decodeMultiRowSnakeOffset(phase - track.pitch, track).$1;
  }

  static double segmentSForMultiRowSnake(
    double pathDistance,
    RsvpSnakeTrack track,
  ) {
    final phase = normalizeMultiRowSnakeDistance(pathDistance, track);
    return decodeMultiRowSnakeOffset(phase - track.pitch, track).$2;
  }

  static void syncMultiRowSnakeState(
    RsvpChaosCarState state,
    RsvpSnakeTrack track,
  ) {
    state.row = rowForMultiRowSnake(state.distance, track);
  }

  static double multiRowChaosCycleLength(RsvpSnakeTrack track) {
    var total = 0.0;
    for (final row in chaosRowSequenceFor(track.rowCount)) {
      total += rowSegmentLength(row, track);
    }
    return total;
  }

  static double multiRowChaosWrapResumeOffset(RsvpSnakeTrack track) {
    final last = chaosRowSequenceFor(track.rowCount).last;
    if (last.isEven) {
      return 0;
    }
    final rowEndS = track.horizontalTravel - 1;
    final leftOverflow = rowEndS - rtlLeftExitStart(track);
    return leftOverflow - track.pitch;
  }

  static double normalizeMultiRowChaosDistance(
    double distance,
    RsvpSnakeTrack track,
  ) {
    final pitch = track.pitch;
    final cycleLen = multiRowChaosCycleLength(track);
    final resume = multiRowChaosWrapResumeOffset(track);
    var offset = distance - pitch;
    while (offset < 0) {
      offset += cycleLen;
    }
    while (offset >= cycleLen) {
      offset = resume + (offset - cycleLen);
    }
    return pitch + offset;
  }

  static (int row, double segmentS) decodeMultiRowChaosOffset(
    double offset,
    RsvpSnakeTrack track,
  ) {
    var remaining = offset;
    for (final row in chaosRowSequenceFor(track.rowCount)) {
      final len = rowSegmentLength(row, track);
      if (remaining < len) {
        if (row == 0) {
          return (0, track.pitch + remaining);
        }
        if (row.isEven) {
          return (
            row,
            rtlOverlapLength(track) + ltrEntryStart(track) + remaining,
          );
        }
        return (row, remaining);
      }
      remaining -= len;
    }

    final last = chaosRowSequenceFor(track.rowCount).last;
    return (last, rowSegmentLength(last, track) - 1);
  }

  static int rowForMultiRowChaos(double pathDistance, RsvpSnakeTrack track) {
    final phase = normalizeMultiRowChaosDistance(pathDistance, track);
    return decodeMultiRowChaosOffset(phase - track.pitch, track).$1;
  }

  static double segmentSForMultiRowChaos(
    double pathDistance,
    RsvpSnakeTrack track,
  ) {
    final phase = normalizeMultiRowChaosDistance(pathDistance, track);
    return decodeMultiRowChaosOffset(phase - track.pitch, track).$2;
  }

  static void syncMultiRowChaosState(
    RsvpChaosCarState state,
    RsvpSnakeTrack track,
  ) {
    state.row = rowForMultiRowChaos(state.distance, track);
  }

  /// Экранные позиции слога в многострочной «суматохе» (порядок строк 1→4→3→2→5).
  static List<Offset> multiRowChaosPositions(
    RsvpSnakeTrack track,
    double pathDistance, {
    bool crossRowWrap = true,
  }) {
    final row = rowForMultiRowChaos(pathDistance, track);
    final segmentS = segmentSForMultiRowChaos(pathDistance, track);
    final positions = track.chaosCarPositionsAt(
      row: row,
      distance: segmentS,
      crossRowWrap: crossRowWrap,
      wrapRow: nextChaosRow(row, track.rowCount),
    );
    if (positions.length <= 1) return positions;

    final primary = positions.first;
    if (_visibleWidth(track, primary) > 0) {
      return positions;
    }

    var best = positions.first;
    var bestVisible = _visibleWidth(track, best);
    for (final pos in positions.skip(1)) {
      final visible = _visibleWidth(track, pos);
      if (visible > bestVisible) {
        bestVisible = visible;
        best = pos;
      }
    }
    return [best];
  }

  /// Экранные позиции слога в многострочной «змейке».
  static List<Offset> multiRowSnakePositions(
    RsvpSnakeTrack track,
    double pathDistance, {
    bool crossRowWrap = true,
  }) {
    final row = rowForMultiRowSnake(pathDistance, track);
    final segmentS = segmentSForMultiRowSnake(pathDistance, track);
    final positions = track.chaosCarPositionsAt(
      row: row,
      distance: segmentS,
      crossRowWrap: crossRowWrap,
    );
    if (positions.length <= 1) return positions;

    final primary = positions.first;
    if (_visibleWidth(track, primary) > 0) {
      return positions;
    }

    var best = positions.first;
    var bestVisible = _visibleWidth(track, best);
    for (final pos in positions.skip(1)) {
      final visible = _visibleWidth(track, pos);
      if (visible > bestVisible) {
        bestVisible = visible;
        best = pos;
      }
    }
    return [best];
  }

  static double _visibleWidth(RsvpSnakeTrack track, Offset topLeft) {
    final left = topLeft.dx.clamp(0.0, track.laneWidth);
    final right = (topLeft.dx + track.carWidth).clamp(0.0, track.laneWidth);
    return right - left;
  }

  /// Порядок смены строк в «Суматохе»: 1→4→3→2→5 (1-based), для 5 рядов.
  static const chaosFiveRowSequence = [0, 3, 2, 1, 4];

  static List<int> chaosRowSequenceFor(int rowCount) {
    if (rowCount == chaosFiveRowSequence.length) {
      return chaosFiveRowSequence;
    }
    return List.generate(rowCount, (i) => i);
  }

  static int nextChaosRow(int currentRow, int rowCount) {
    final sequence = chaosRowSequenceFor(rowCount);
    final idx = sequence.indexOf(currentRow);
    if (idx < 0) return sequence.first;
    return sequence[(idx + 1) % sequence.length];
  }

  /// Индексы потока для слогов подсказки (с учётом повторов).
  static List<int> priorityStreamIndices({
    required List<String> streamSyllables,
    required List<String> targetSyllables,
    required Iterable<int> activeStreamIndices,
  }) {
    final remaining = activeStreamIndices.toList();
    final result = <int>[];
    for (final syllable in targetSyllables) {
      final pick = remaining.indexWhere(
        (streamIndex) => streamSyllables[streamIndex] == syllable,
      );
      if (pick < 0) continue;
      result.add(remaining.removeAt(pick));
    }
    return result;
  }

  /// Расстояние между слогами в потоке (не «паровоз»).
  static double chaosStreamInterval(
    RsvpSnakeTrack track, {
    int carCount = 5,
  }) =>
      math.max(
        track.pitch * 3.5,
        track.horizontalTravel /
            math.max(1, math.min(carCount, track.rowCount)) *
            0.95,
      );

  static bool _chaosSlotClear({
    required Map<int, RsvpChaosCarState> states,
    required Iterable<int> streamIndices,
    required int skipIndex,
    required int row,
    required double distance,
    required RsvpSnakeTrack track,
  }) {
    for (final index in streamIndices) {
      if (index == skipIndex) continue;
      final other = states[index];
      if (other == null || other.row != row) continue;
      if ((other.distance - distance).abs() < track.pitch) return false;
    }
    return true;
  }

  static double _peekChaosDistanceOnRow({
    required int row,
    required Map<int, double> rowDistance,
    required RsvpSnakeTrack track,
    required double interval,
  }) {
    final travel = track.horizontalTravel;
    var distance = rowDistance[row] ?? interval;
    if (distance >= travel - track.pitch) {
      distance = interval;
    }
    return distance;
  }

  static void _commitChaosDistanceOnRow({
    required int row,
    required Map<int, double> rowDistance,
    required double distance,
    required double interval,
  }) {
    rowDistance[row] = distance + interval;
  }

  static List<Offset> chaosCarPositions(
    RsvpSnakeTrack track,
    RsvpChaosCarState state,
  ) =>
      track.chaosCarPositionsAt(
        row: state.row,
        distance: state.distance,
        crossRowWrap: true,
        wrapRow: nextChaosRow(state.row, track.rowCount),
      );

  static void _spreadChaosInitial({
    required Map<int, RsvpChaosCarState> states,
    required List<int> indices,
    required RsvpSnakeTrack track,
    Iterable<int>? priorityStreamIndices,
  }) {
    final sequence = chaosRowSequenceFor(track.rowCount);
    final interval = chaosStreamInterval(track, carCount: indices.length);
    final rowDistance = <int, double>{};
    final priority = {
      if (priorityStreamIndices != null) ...priorityStreamIndices,
    };
    final ordered = [
      for (final index in indices)
        if (priority.contains(index)) index,
      for (final index in indices)
        if (!priority.contains(index)) index,
    ];

    for (var i = 0; i < ordered.length; i++) {
      final streamIndex = ordered[i];
      var placed = false;
      for (var attempt = 0; attempt < sequence.length && !placed; attempt++) {
        final row = sequence[(i + attempt) % sequence.length];
        final distance = _peekChaosDistanceOnRow(
          row: row,
          rowDistance: rowDistance,
          track: track,
          interval: interval,
        );
        if (!_chaosSlotClear(
          states: states,
          streamIndices: ordered,
          skipIndex: streamIndex,
          row: row,
          distance: distance,
          track: track,
        )) {
          continue;
        }
        states[streamIndex] = RsvpChaosCarState(row: row, distance: distance);
        _commitChaosDistanceOnRow(
          row: row,
          rowDistance: rowDistance,
          distance: distance,
          interval: interval,
        );
        placed = true;
      }
      if (!placed) {
        final row = sequence[i % sequence.length];
        final distance = _peekChaosDistanceOnRow(
          row: row,
          rowDistance: rowDistance,
          track: track,
          interval: interval,
        );
        states[streamIndex] = RsvpChaosCarState(row: row, distance: distance);
        _commitChaosDistanceOnRow(
          row: row,
          rowDistance: rowDistance,
          distance: distance,
          interval: interval,
        );
      }
    }
  }

  static void _tickChaos({
    required Map<int, RsvpChaosCarState> states,
    required Iterable<int> activeStreamIndices,
    required RsvpSnakeTrack track,
    required double delta,
  }) {
    final travel = track.horizontalTravel;
    for (final streamIndex in activeStreamIndices) {
      final state = states[streamIndex];
      if (state == null) continue;

      state.distance += delta;
      while (state.distance >= travel) {
        state.distance -= travel;
        state.row = nextChaosRow(state.row, track.rowCount);
      }
    }
  }

  static void _placeReturnedChaos({
    required Map<int, RsvpChaosCarState> states,
    required int streamIndex,
    required Iterable<int> activeStreamIndices,
    required RsvpSnakeTrack track,
  }) {
    final travel = track.horizontalTravel;
    final interval = chaosStreamInterval(
      track,
      carCount: activeStreamIndices.length + 1,
    );
    final sequence = chaosRowSequenceFor(track.rowCount);

    for (var attempt = 0; attempt < sequence.length; attempt++) {
      final row = sequence[attempt];
      var distance = interval;
      var maxOnRow = 0.0;
      for (final index in activeStreamIndices) {
        if (index == streamIndex) continue;
        final other = states[index];
        if (other == null || other.row != row) continue;
        if (other.distance > maxOnRow) maxOnRow = other.distance;
      }
      if (maxOnRow > 0) {
        distance = maxOnRow + interval;
        while (distance >= travel - track.pitch) {
          distance -= interval;
        }
      }
      if (_chaosSlotClear(
        states: states,
        streamIndices: activeStreamIndices,
        skipIndex: streamIndex,
        row: row,
        distance: distance,
        track: track,
      )) {
        states[streamIndex] = RsvpChaosCarState(row: row, distance: distance);
        return;
      }
    }

    final row = sequence.first;
    states[streamIndex] = RsvpChaosCarState(row: row, distance: interval);
  }

  // Совместимость с двухстрочными тестами.
  static double twoRowSnakeCycleLength(RsvpSnakeTrack track) =>
      multiRowSnakeCycleLength(track);

  static double twoRowSnakeWrapResumeOffset(RsvpSnakeTrack track) =>
      multiRowSnakeWrapResumeOffset(track);

  static double normalizeTwoRowSnakeDistance(
    double distance,
    RsvpSnakeTrack track,
  ) =>
      normalizeMultiRowSnakeDistance(distance, track);

  static int rowForTwoRowSnake(double pathDistance, RsvpSnakeTrack track) =>
      rowForMultiRowSnake(pathDistance, track);

  static double segmentSForTwoRowSnake(
    double pathDistance,
    RsvpSnakeTrack track,
  ) =>
      segmentSForMultiRowSnake(pathDistance, track);

  static void syncTwoRowSnakeState(
    RsvpChaosCarState state,
    RsvpSnakeTrack track,
  ) =>
      syncMultiRowSnakeState(state, track);

  static List<Offset> twoRowSnakePositions(
    RsvpSnakeTrack track,
    double pathDistance, {
    bool crossRowWrap = true,
  }) {
    final row = rowForTwoRowSnake(pathDistance, track);
    final segmentS = segmentSForTwoRowSnake(pathDistance, track);
    final positions = track.chaosCarPositionsAt(
      row: row,
      distance: segmentS,
      crossRowWrap: crossRowWrap,
    );
    if (positions.length <= 1) return positions;

    final primary = positions.first;
    if (_visibleWidth(track, primary) > 0) {
      return positions;
    }

    var best = positions.first;
    var bestVisible = _visibleWidth(track, best);
    for (final pos in positions.skip(1)) {
      final visible = _visibleWidth(track, pos);
      if (visible > bestVisible) {
        bestVisible = visible;
        best = pos;
      }
    }
    return [best];
  }

  /// Разнести слоги по строкам и по горизонтали — без «паровоза».
  static void spreadInitial({
    required Map<int, RsvpChaosCarState> states,
    required Iterable<int> streamIndices,
    required RsvpSnakeTrack track,
    bool singleRowOnly = false,
    bool multiRowSnake = false,
    bool multiRowChaos = false,
    bool twoRowSnake = false,
    Iterable<int>? priorityStreamIndices,
  }) {
    final snake = multiRowSnake || twoRowSnake;
    final indices = streamIndices.toList();
    final count = indices.length;
    if (count == 0) return;

    if (multiRowChaos) {
      for (var i = 0; i < count; i++) {
        states[indices[i]] = RsvpChaosCarState(
          row: 0,
          distance: track.pitch + track.pitch * i,
        );
      }
      return;
    }

    if (snake) {
      for (var i = 0; i < count; i++) {
        states[indices[i]] = RsvpChaosCarState(
          row: 0,
          distance: track.pitch + track.pitch * i,
        );
      }
      return;
    }

    final rowStep = count <= track.rowCount ? 1 : 2;
    final distanceStep = singleRowOnly
        ? track.pitch
        : track.horizontalTravel / (count + 1);

    for (var i = 0; i < count; i++) {
      states[indices[i]] = RsvpChaosCarState(
        row: singleRowOnly ? 0 : (i * rowStep) % track.rowCount,
        distance: distanceStep * (i + 1),
      );
    }
  }

  static void tick({
    required Map<int, RsvpChaosCarState> states,
    required Iterable<int> activeStreamIndices,
    required RsvpSnakeTrack track,
    required double delta,
    bool singleRowOnly = false,
    bool multiRowSnake = false,
    bool multiRowChaos = false,
    bool twoRowSnake = false,
  }) {
    if (multiRowChaos) {
      for (final streamIndex in activeStreamIndices) {
        final state = states[streamIndex];
        if (state == null) continue;
        state.distance += delta;
        syncMultiRowChaosState(state, track);
      }
      return;
    }

    final snake = multiRowSnake || twoRowSnake;
    final travel = track.horizontalTravel;
    for (final streamIndex in activeStreamIndices) {
      final state = states[streamIndex];
      if (state == null) continue;

      state.distance += delta;
      if (snake) {
        syncMultiRowSnakeState(state, track);
        continue;
      }

      if (singleRowOnly) {
        while (state.distance >= travel) {
          state.distance -= travel;
          state.distance += track.carWidth;
        }
        continue;
      }

      if (state.distance >= travel) {
        state.distance = 0;
        state.row = (state.row + 1) % track.rowCount;
      }
    }
  }

  static void rebalanceMultiRowSnakeTrain({
    required Map<int, RsvpChaosCarState> states,
    required List<int> streamIndices,
    required RsvpSnakeTrack track,
  }) {
    if (streamIndices.isEmpty) return;

    final headDistance = () {
      final first = streamIndices.first;
      final firstState = states[first];
      if (firstState != null) return firstState.distance;
      if (streamIndices.length > 1) {
        return states[streamIndices[1]]?.distance ?? track.pitch;
      }
      return track.pitch;
    }();

    for (var i = 0; i < streamIndices.length; i++) {
      final index = streamIndices[i];
      final state = states[index] ??
          RsvpChaosCarState(row: 0, distance: headDistance + track.pitch * i);
      state.distance = headDistance + track.pitch * i;
      states[index] = state;
      syncMultiRowSnakeState(state, track);
    }
  }

  static void placeReturned({
    required Map<int, RsvpChaosCarState> states,
    required int streamIndex,
    required RsvpSnakeTrack track,
    required Iterable<int> activeStreamIndices,
    bool singleRowOnly = false,
    bool multiRowSnake = false,
    bool multiRowChaos = false,
    bool twoRowSnake = false,
  }) {
    if (multiRowChaos) {
      final distance = _distanceBehindTrainTail(
        states: states,
        streamIndex: streamIndex,
        activeStreamIndices: activeStreamIndices,
        track: track,
      );
      final state = RsvpChaosCarState(row: 0, distance: distance);
      states[streamIndex] = state;
      syncMultiRowChaosState(state, track);
      return;
    }

    final snake = multiRowSnake || twoRowSnake;
    if (snake) {
      rebalanceMultiRowSnakeTrain(
        states: states,
        streamIndices: activeStreamIndices is List<int>
            ? activeStreamIndices
            : activeStreamIndices.toList(),
        track: track,
      );
      return;
    }

    states[streamIndex] = RsvpChaosCarState(
      row: 0,
      distance: singleRowOnly ? track.pitch : 0,
    );
  }

  static double _distanceBehindTrainTail({
    required Map<int, RsvpChaosCarState> states,
    required int streamIndex,
    required Iterable<int> activeStreamIndices,
    required RsvpSnakeTrack track,
  }) {
    var minDistance = double.infinity;
    for (final index in activeStreamIndices) {
      if (index == streamIndex) continue;
      final distance = states[index]?.distance;
      if (distance != null && distance < minDistance) {
        minDistance = distance;
      }
    }
    if (minDistance == double.infinity) return track.pitch;
    return minDistance - track.pitch;
  }
}
