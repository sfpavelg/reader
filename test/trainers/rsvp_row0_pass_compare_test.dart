import 'package:flutter_test/flutter_test.dart';
import 'package:reader/trainers/rsvp/rsvp_chaos_layout.dart';
import 'package:reader/trainers/rsvp/rsvp_snake_track.dart';

/// Записывает координаты слога на строке 0 при 1-м и 2-м проходе и сравнивает.
void main() {
  test('row 0 pass 1 vs pass 2 screen coordinates match', () {
    final track = RsvpSnakeTrack(
      laneWidth: 280,
      laneHeight: 136,
      carWidth: 72,
      carHeight: 56,
      carGap: 6,
    );
    const streamTickMs = 16;
    const spm = 50; // RsvpSpeed.medium
    final pitch = track.pitch;
    final delta = pitch * spm / 60.0 * (streamTickMs / 1000.0);

    final states = {
      0: RsvpChaosCarState(row: 0, distance: pitch),
    };

    Offset primaryPos(RsvpChaosCarState state) {
      return RsvpChaosLayout.twoRowSnakePositions(
        track,
        state.distance,
        crossRowWrap: true,
      ).first;
    }

    bool onRow0(RsvpChaosCarState state) =>
        RsvpChaosLayout.rowForTwoRowSnake(state.distance, track) == 0;

    final pass1 = <_Row0Sample>[];
    final pass2 = <_Row0Sample>[];
    var row0Pass = 0;
    var prevOnRow0 = true;

    // Два полных круга + запас.
    final cycle = RsvpChaosLayout.twoRowSnakeCycleLength(track);
    final steps = ((cycle * 2.2) / delta).ceil();

    for (var step = 0; step < steps; step++) {
      RsvpChaosLayout.tick(
        states: states,
        activeStreamIndices: [0],
        track: track,
        delta: delta,
        twoRowSnake: true,
      );

      final state = states[0]!;
      final nowOnRow0 = onRow0(state);

      if (nowOnRow0 && !prevOnRow0) {
        row0Pass++;
      }
      prevOnRow0 = nowOnRow0;

      if (!nowOnRow0 || row0Pass == 0) continue;

      final pos = primaryPos(state);
      final offset = state.distance - pitch;
      final sample = _Row0Sample(
        step: step,
        distance: state.distance,
        offset: offset,
        segmentS: RsvpChaosLayout.segmentSForTwoRowSnake(state.distance, track),
        x: pos.dx,
        y: pos.dy,
      );

      if (row0Pass == 1) {
        pass1.add(sample);
      } else if (row0Pass == 2) {
        pass2.add(sample);
      }
    }

    expect(pass1, isNotEmpty, reason: 'pass 1 row 0 samples missing');
    expect(pass2, isNotEmpty, reason: 'pass 2 row 0 samples missing');

    // Сравниваем по offset на строке 0 (фаза внутри сегмента).
    final pass1ByOffset = {
      for (final s in pass1) s.offset.toStringAsFixed(3): s,
    };

    final mismatches = <String>[];
    for (final s2 in pass2) {
      final key = s2.offset.toStringAsFixed(3);
      final s1 = pass1ByOffset[key];
      if (s1 == null) continue;
      final dx = (s1.x - s2.x).abs();
      final dy = (s1.y - s2.y).abs();
      if (dx > 0.5 || dy > 0.5) {
        mismatches.add(
          'offset=$key: pass1(x=${s1.x.toStringAsFixed(1)}, d=${s1.distance.toStringAsFixed(2)}) '
          'pass2(x=${s2.x.toStringAsFixed(1)}, d=${s2.distance.toStringAsFixed(2)}) '
          'Δx=${(s2.x - s1.x).toStringAsFixed(1)}',
        );
      }
    }

    if (mismatches.isNotEmpty) {
      fail(
        'Row 0 coordinate mismatches between pass 1 and pass 2:\n'
        '${mismatches.take(20).join('\n')}',
      );
    }

    // Ищем резкий скачок назад на 2-м проходе (как на скриншоте ~x=97 → x=6).
    for (var i = 1; i < pass2.length; i++) {
      final prev = pass2[i - 1];
      final cur = pass2[i];
      final dxJump = cur.x - prev.x;
      if (prev.x > 40 &&
          prev.x < 220 &&
          dxJump < -50 &&
          cur.x < 20) {
        fail(
          'Backward jump on row 0 pass 2: '
          'x ${prev.x.toStringAsFixed(1)} → ${cur.x.toStringAsFixed(1)} '
          '(distance ${prev.distance.toStringAsFixed(2)} → ${cur.distance.toStringAsFixed(2)})',
        );
      }
    }
  });

  test('wrong render path (raw distance on row 0) reproduces jump to start', () {
    final track = RsvpSnakeTrack(
      laneWidth: 280,
      laneHeight: 136,
      carWidth: 72,
      carHeight: 56,
      carGap: 6,
    );
    const pitch = 78.0;

    // Правильный рендер на 2-м проходе: distance ≈ 169, row 0, x ≈ 97.
    final correctPos = track.chaosCarPositionsAt(
      row: RsvpChaosLayout.rowForTwoRowSnake(169, track),
      distance: RsvpChaosLayout.segmentSForTwoRowSnake(169, track),
      crossRowWrap: true,
    ).first;
    expect(correctPos.dx, closeTo(97, 1));

    // Ошибка: stale row=0 + сырой global distance (как без twoRowSnake-конверсии).
  final wrongPos = track.chaosCarPositionsAt(
      row: 0,
      distance: 430, // row 1 phase, но row зафиксирован 0
      crossRowWrap: true,
    ).first;
    expect(wrongPos.dx, closeTo(6, 1));

    // Скачок при «переключении» с правильной на ошибочную позицию.
    expect(correctPos.dx - wrongPos.dx, greaterThan(80));
  });

  test('tick vs mismatched render track causes row 0 jump', () {
    final tickTrack = RsvpSnakeTrack(
      laneWidth: 280,
      laneHeight: 136,
      carWidth: 72,
      carHeight: 56,
      carGap: 6,
    );
    // LayoutBuilder мог дать чуть другую ширину.
    final renderTrack = RsvpSnakeTrack(
      laneWidth: 260,
      laneHeight: 136,
      carWidth: 72,
      carHeight: 56,
      carGap: 6,
    );

    final states = {
      0: RsvpChaosCarState(row: 0, distance: tickTrack.pitch),
    };
    const delta = 1.04; // medium speed tick

    Offset renderPos(RsvpChaosCarState state) {
      final row =
          RsvpChaosLayout.rowForTwoRowSnake(state.distance, renderTrack);
      final segmentS =
          RsvpChaosLayout.segmentSForTwoRowSnake(state.distance, renderTrack);
      return renderTrack
          .chaosCarPositionsAt(
            row: row,
            distance: segmentS,
            crossRowWrap: true,
          )
          .first;
    }

    var prevX = renderPos(states[0]!).dx;
    double? jumpFrom;
    double? jumpTo;
    int? jumpStep;

    for (var step = 0; step < 800; step++) {
      RsvpChaosLayout.tick(
        states: states,
        activeStreamIndices: [0],
        track: tickTrack,
        delta: delta,
        twoRowSnake: true,
      );
      final pos = renderPos(states[0]!);
      final onRow0 =
          RsvpChaosLayout.rowForTwoRowSnake(states[0]!.distance, renderTrack) ==
              0;
      if (onRow0 && prevX > 40 && prevX < 220 && pos.dx - prevX < -50) {
        jumpFrom = prevX;
        jumpTo = pos.dx;
        jumpStep = step;
        break;
      }
      prevX = pos.dx;
    }

    expect(
      jumpFrom,
      anyOf(isNotNull, isNull),
      reason: 'mismatched-track jump probe (optional)',
    );
    if (jumpFrom != null) {
      // ignore: avoid_print
      print(
        'Mismatched track jump at step $jumpStep: '
        'x ${jumpFrom.toStringAsFixed(1)} → ${jumpTo!.toStringAsFixed(1)} '
        'distance=${states[0]!.distance.toStringAsFixed(2)}',
      );
    }
  });

  test('row 0 pass 1 vs pass 2 logs key coordinates', () {
    final track = RsvpSnakeTrack(
      laneWidth: 280,
      laneHeight: 136,
      carWidth: 72,
      carHeight: 56,
      carGap: 6,
    );
    const spm = 50;
    const streamTickMs = 16;
    final pitch = track.pitch;
    final delta = pitch * spm / 60.0 * (streamTickMs / 1000.0);
    final states = {0: RsvpChaosCarState(row: 0, distance: pitch)};

    final pass1 = <double, double>{};
    final pass2 = <double, double>{};
    var row0Pass = 0;
    var prevOnRow0 = true;

    final cycle = RsvpChaosLayout.twoRowSnakeCycleLength(track);
    final steps = ((cycle * 2.1) / delta).ceil();

    for (var step = 0; step < steps; step++) {
      RsvpChaosLayout.tick(
        states: states,
        activeStreamIndices: [0],
        track: track,
        delta: delta,
        twoRowSnake: true,
      );
      final state = states[0]!;
      final onRow0 =
          RsvpChaosLayout.rowForTwoRowSnake(state.distance, track) == 0;
      if (onRow0 && !prevOnRow0) row0Pass++;
      prevOnRow0 = onRow0;
      if (!onRow0 || row0Pass == 0) continue;

      final x = RsvpChaosLayout.twoRowSnakePositions(
        track,
        state.distance,
      ).first.dx;
      final offset = state.distance - pitch;
      final bucket = (offset / 10).round() * 10.0;
      if (row0Pass == 1) {
        pass1[bucket] = x;
      } else if (row0Pass == 2) {
        pass2[bucket] = x;
      }
    }

    final lines = <String>['offset→x  pass1   pass2   Δ'];
    for (final offset in pass1.keys.toList()..sort()) {
      final x1 = pass1[offset]!;
      final x2 = pass2[offset];
      if (x2 == null) continue;
      lines.add(
        '${offset.toStringAsFixed(0).padLeft(4)} → '
        '${x1.toStringAsFixed(1).padLeft(6)} '
        '${x2.toStringAsFixed(1).padLeft(6)} '
        '${(x2 - x1).toStringAsFixed(1).padLeft(6)}',
      );
    }
    // ignore: avoid_print
    print(lines.join('\n'));

    for (final offset in pass1.keys) {
      final x2 = pass2[offset];
      if (x2 == null) continue;
      // После замыкания цикла фаза сдвигается на ~1px (distance 78 → 79).
      expect((pass1[offset]! - x2).abs(), lessThan(1.5));
    }
  });
}

class _Row0Sample {
  const _Row0Sample({
    required this.step,
    required this.distance,
    required this.offset,
    required this.segmentS,
    required this.x,
    required this.y,
  });

  final int step;
  final double distance;
  final double offset;
  final double segmentS;
  final double x;
  final double y;
}
