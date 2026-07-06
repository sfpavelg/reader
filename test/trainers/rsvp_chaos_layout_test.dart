import 'package:flutter_test/flutter_test.dart';
import 'package:reader/trainers/rsvp/rsvp_chaos_layout.dart';
import 'package:reader/trainers/rsvp/rsvp_snake_track.dart';

void main() {
  test('chaos cars start on different rows and distances', () {
    final track = RsvpSnakeTrack(
      laneWidth: 300,
      laneHeight: 200,
      carWidth: 72,
      carHeight: 56,
      carGap: 6,
    );
    final states = <int, RsvpChaosCarState>{};

    RsvpChaosLayout.spreadInitial(
      states: states,
      streamIndices: [0, 1, 2, 3, 4],
      track: track,
    );

    expect(states[0]!.row, isNot(states[1]!.row));
    expect(states[0]!.distance, isNot(states[1]!.distance));
  });

  test('chaos single row spreads cars by pitch', () {
    final track = RsvpSnakeTrack(
      laneWidth: 280,
      laneHeight: 72,
      carWidth: 72,
      carHeight: 56,
      carGap: 6,
    );
    final states = <int, RsvpChaosCarState>{};

    RsvpChaosLayout.spreadInitial(
      states: states,
      streamIndices: [0, 1, 2, 3],
      track: track,
      singleRowOnly: true,
    );

    expect(states[0]!.distance, closeTo(track.pitch, 0.01));
    expect(states[1]!.distance - states[0]!.distance, closeTo(track.pitch, 0.01));
    expect(states[3]!.distance, closeTo(track.pitch * 4, 0.01));
  });

  test('chaos car changes row after exiting horizontally', () {
    final track = RsvpSnakeTrack(
      laneWidth: 300,
      laneHeight: 200,
      carWidth: 72,
      carHeight: 56,
      carGap: 6,
    );
    final states = {
      0: RsvpChaosCarState(row: 0, distance: track.horizontalTravel - 1),
    };

    RsvpChaosLayout.tick(
      states: states,
      activeStreamIndices: [0],
      track: track,
      delta: 2,
    );

    expect(states[0]!.row, 1);
    expect(states[0]!.distance, closeTo(0, 0.01));
  });

  test('chaos single row keeps continuous distance', () {
    final track = RsvpSnakeTrack(
      laneWidth: 280,
      laneHeight: 72,
      carWidth: 72,
      carHeight: 56,
      carGap: 6,
    );
    final travel = track.horizontalTravel;
    final states = {
      0: RsvpChaosCarState(row: 0, distance: travel - 1),
    };

    RsvpChaosLayout.tick(
      states: states,
      activeStreamIndices: [0],
      track: track,
      delta: 2,
      singleRowOnly: true,
    );

    expect(states[0]!.row, 0);
    expect(states[0]!.distance, closeTo(track.carWidth + 1, 0.01));
  });

  test('chaos lap crossing continues moving right from left edge', () {
    final track = RsvpSnakeTrack(
      laneWidth: 280,
      laneHeight: 72,
      carWidth: 72,
      carHeight: 56,
      carGap: 6,
    );
    final travel = track.horizontalTravel;
    final states = {
      0: RsvpChaosCarState(row: 0, distance: travel - 1),
    };

    RsvpChaosLayout.tick(
      states: states,
      activeStreamIndices: [0],
      track: track,
      delta: 2,
      singleRowOnly: true,
    );

    final pos = track.chaosCarPositionsAt(
      row: 0,
      distance: states[0]!.distance,
    );
    expect(states[0]!.distance, closeTo(track.carWidth + 1, 0.01));
    expect(pos, hasLength(1));
    expect(pos[0].dx, closeTo(1, 0.01));
  });

  test('chaos seamless wrap mirrors right overflow on left', () {
    const laneWidth = 280.0;
    const carWidth = 72.0;
    const overflow = 30.0;
    final track = RsvpSnakeTrack(
      laneWidth: laneWidth,
      laneHeight: 72,
      carWidth: carWidth,
      carHeight: 56,
      carGap: 6,
    );

    final positions = track.chaosCarPositionsAt(
      row: 0,
      distance: laneWidth + overflow,
    );

    expect(positions, hasLength(2));
    expect(positions[0].dx, closeTo(laneWidth - carWidth + overflow, 0.01));
    expect(positions[1].dx, closeTo(overflow - carWidth, 0.01));
    expect(track.intersectsLane(positions[0]), isTrue);
    expect(track.intersectsLane(positions[1]), isTrue);
    expect(laneWidth - positions[0].dx, closeTo(carWidth - overflow, 0.01));
    expect(positions[1].dx + carWidth, closeTo(overflow, 0.01));
  });

  test('chaos ltr row slides in gradually from left', () {
    const laneWidth = 280.0;
    const carWidth = 72.0;
    final track = RsvpSnakeTrack(
      laneWidth: laneWidth,
      laneHeight: 72,
      carWidth: carWidth,
      carHeight: 56,
      carGap: 6,
    );

    final peeking = track.chaosCarPositionAt(row: 0, distance: 40);
    final inside = track.chaosCarPositionAt(row: 0, distance: carWidth);

    expect(peeking.dx, lessThan(0));
    expect(track.intersectsLane(peeking), isTrue);
    expect(track.visibleInLane(peeking), isFalse);
    expect(inside.dx, closeTo(0, 0.01));
    expect(track.intersectsLane(inside), isTrue);
  });

  test('chaos ltr row exits gradually past right edge', () {
    const laneWidth = 280.0;
    const carWidth = 72.0;
    final track = RsvpSnakeTrack(
      laneWidth: laneWidth,
      laneHeight: 72,
      carWidth: carWidth,
      carHeight: 56,
      carGap: 6,
    );

    final peeking = track.chaosCarPositionsAt(
      row: 0,
      distance: laneWidth + carWidth * 0.5,
    );

    expect(peeking, hasLength(2));
    expect(peeking[0].dx, greaterThan(laneWidth - carWidth));
    expect(track.intersectsLane(peeking[0]), isTrue);
    expect(track.intersectsLane(peeking[1]), isTrue);
  });

  test('two row snake shows rtl ghost on row 1 when ltr exits right', () {
    const laneWidth = 280.0;
    const overflow = 30.0;
    final track = RsvpSnakeTrack(
      laneWidth: laneWidth,
      laneHeight: 136,
      carWidth: 72,
      carHeight: 56,
      carGap: 6,
    );
    expect(track.rowCount, 2);

    final positions = track.chaosCarPositionsAt(
      row: 0,
      distance: laneWidth + overflow,
      crossRowWrap: true,
    );

    expect(positions, hasLength(2));
    expect(positions[0].dy, closeTo(track.rowY(0), 0.01));
    expect(positions[1].dy, closeTo(track.rowY(1), 0.01));
    expect(positions[1].dx, closeTo(laneWidth - overflow, 0.01));
    expect(track.intersectsLane(positions[1]), isTrue);
  });

  test('two row snake shows ltr ghost on row 0 when rtl exits left', () {
    const laneWidth = 280.0;
    const carWidth = 72.0;
    const leftOverflow = 25.0;
    final track = RsvpSnakeTrack(
      laneWidth: laneWidth,
      laneHeight: 136,
      carWidth: carWidth,
      carHeight: 56,
      carGap: 6,
    );

    final positions = track.chaosCarPositionsAt(
      row: 1,
      distance: laneWidth - carWidth + leftOverflow,
      crossRowWrap: true,
    );

    expect(positions, hasLength(2));
    expect(positions[0].dy, closeTo(track.rowY(1), 0.01));
    expect(positions[1].dy, closeTo(track.rowY(0), 0.01));
    expect(positions[1].dx, closeTo(leftOverflow - carWidth, 0.01));
    expect(track.intersectsLane(positions[0]), isTrue);
    expect(track.intersectsLane(positions[1]), isTrue);
    expect(-positions[0].dx, closeTo(leftOverflow, 0.01));
    expect(positions[1].dx + carWidth, closeTo(leftOverflow, 0.01));
  });

  test('two row snake transitions row 0 ltr to row 1 rtl', () {
    final track = RsvpSnakeTrack(
      laneWidth: 280,
      laneHeight: 136,
      carWidth: 72,
      carHeight: 56,
      carGap: 6,
    );
    final travel = track.horizontalTravel;
    final states = {
      0: RsvpChaosCarState(row: 0, distance: travel - 1),
    };

    RsvpChaosLayout.tick(
      states: states,
      activeStreamIndices: [0],
      track: track,
      delta: 2,
      twoRowSnake: true,
    );

    expect(states[0]!.row, 1);
    expect(states[0]!.distance, closeTo(travel + 1, 0.01));
    final pos = track.chaosCarPositionAt(
      row: 1,
      distance: RsvpChaosLayout.segmentSForTwoRowSnake(states[0]!.distance, track),
    );
    expect(pos.dy, closeTo(track.rowY(1), 0.01));
    expect(pos.dx, closeTo(track.laneWidth - track.carWidth - 1, 0.01));
  });

  test('two row snake transitions row 1 rtl to row 0 ltr', () {
    final track = RsvpSnakeTrack(
      laneWidth: 280,
      laneHeight: 136,
      carWidth: 72,
      carHeight: 56,
      carGap: 6,
    );
    final pitch = track.pitch;
    final lap = RsvpChaosLayout.twoRowSnakeCycleLength(track);
    final states = {
      0: RsvpChaosCarState(row: 1, distance: pitch + lap - 1),
    };

    RsvpChaosLayout.tick(
      states: states,
      activeStreamIndices: [0],
      track: track,
      delta: 2,
      twoRowSnake: true,
    );

    expect(states[0]!.row, 0);
    expect(states[0]!.distance, closeTo(pitch + lap + 1, 0.01));
    expect(
      RsvpChaosLayout.normalizeTwoRowSnakeDistance(states[0]!.distance, track),
      closeTo(pitch + RsvpChaosLayout.twoRowSnakeWrapResumeOffset(track) + 1, 0.01),
    );
    final pos = track.chaosCarPositionAt(
      row: 0,
      distance: RsvpChaosLayout.segmentSForTwoRowSnake(states[0]!.distance, track),
    );
    expect(pos.dy, closeTo(track.rowY(0), 0.01));
    expect(pos.dx, closeTo(72, 1));
  });

  test('two row snake closes cycle without position reset', () {
    final track = RsvpSnakeTrack(
      laneWidth: 280,
      laneHeight: 136,
      carWidth: 72,
      carHeight: 56,
      carGap: 6,
    );
    final pitch = track.pitch;
    final lap = RsvpChaosLayout.twoRowSnakeCycleLength(track);
    final states = {
      0: RsvpChaosCarState(row: 0, distance: pitch + lap - 1),
    };

    RsvpChaosLayout.tick(
      states: states,
      activeStreamIndices: [0],
      track: track,
      delta: 2,
      twoRowSnake: true,
    );

    expect(states[0]!.distance, closeTo(pitch + lap + 1, 0.01));
    expect(
      RsvpChaosLayout.normalizeTwoRowSnakeDistance(states[0]!.distance, track),
      closeTo(pitch + RsvpChaosLayout.twoRowSnakeWrapResumeOffset(track) + 1, 0.01),
    );
    expect(states[0]!.row, 0);
  });

  test('two row snake left wrap keeps screen x continuous', () {
    final track = RsvpSnakeTrack(
      laneWidth: 280,
      laneHeight: 136,
      carWidth: 72,
      carHeight: 56,
      carGap: 6,
    );
    final pitch = track.pitch;
    final lap = RsvpChaosLayout.twoRowSnakeCycleLength(track);
    final before = pitch + lap - 1;
    final after = pitch + lap + 2;
    final posBefore =
        RsvpChaosLayout.twoRowSnakePositions(track, before).first;
    final posAfter = RsvpChaosLayout.twoRowSnakePositions(track, after).first;

    expect(posBefore.dx, greaterThan(50));
    expect((posAfter.dx - posBefore.dx).abs(), lessThan(8));
    expect(posAfter.dy, closeTo(track.rowY(0), 0.01));
  });

  test('two row snake keeps continuous screen position over many laps', () {
    final track = RsvpSnakeTrack(
      laneWidth: 280,
      laneHeight: 136,
      carWidth: 72,
      carHeight: 56,
      carGap: 6,
    );
    final states = {
      0: RsvpChaosCarState(row: 0, distance: track.pitch),
    };
    const delta = 2.0;
  const laps = 5;
    final cycle = RsvpChaosLayout.twoRowSnakeCycleLength(track);
    final steps = ((cycle / delta) * laps).ceil();

    Offset primaryPos(RsvpChaosCarState state) {
      final row = RsvpChaosLayout.rowForTwoRowSnake(state.distance, track);
      final segmentS =
          RsvpChaosLayout.segmentSForTwoRowSnake(state.distance, track);
      return track
          .chaosCarPositionsAt(
            row: row,
            distance: segmentS,
            crossRowWrap: true,
          )
          .first;
    }

    var prev = primaryPos(states[0]!);
    for (var i = 0; i < steps; i++) {
      RsvpChaosLayout.tick(
        states: states,
        activeStreamIndices: [0],
        track: track,
        delta: delta,
        twoRowSnake: true,
      );
      final pos = primaryPos(states[0]!);
      final dxJump = pos.dx - prev.dx;
      final dyJump = pos.dy - prev.dy;
      final onRow0 = (pos.dy - track.rowY(0)).abs() < 0.01;

      if (onRow0 && prev.dx > 40 && prev.dx < 220) {
        expect(
          dxJump,
          greaterThan(-20),
          reason:
              'backward jump at x=${prev.dx.toStringAsFixed(1)} '
              'distance=${states[0]!.distance.toStringAsFixed(1)}',
        );
      }

      expect(dyJump.abs(), lessThan(track.rowStride + 1));
      prev = pos;
    }
  });

  test('four row snake keeps continuous screen position over many laps', () {
    final track = RsvpSnakeTrack(
      laneWidth: 280,
      laneHeight: 264,
      carWidth: 72,
      carHeight: 56,
      carGap: 6,
    );
    expect(track.rowCount, 4);

    final states = {
      0: RsvpChaosCarState(row: 0, distance: track.pitch),
    };
    const delta = 2.0;
    const laps = 3;
    final cycle = RsvpChaosLayout.multiRowSnakeCycleLength(track);
    final steps = ((cycle / delta) * laps).ceil();

    Offset primaryPos(RsvpChaosCarState state) =>
        RsvpChaosLayout.multiRowSnakePositions(track, state.distance).first;

    var prev = primaryPos(states[0]!);
    for (var i = 0; i < steps; i++) {
      RsvpChaosLayout.tick(
        states: states,
        activeStreamIndices: [0],
        track: track,
        delta: delta,
        multiRowSnake: true,
      );
      final pos = primaryPos(states[0]!);
      final dxJump = pos.dx - prev.dx;
      final dyJump = pos.dy - prev.dy;
      final onRow2 = (pos.dy - track.rowY(2)).abs() < 0.01;
      final wasOnRow2 = (prev.dy - track.rowY(2)).abs() < 0.01;

      if (onRow2 && wasOnRow2 && dxJump < -20) {
        fail(
          'backward jump on row 2 at x=${prev.dx.toStringAsFixed(1)} '
          'distance=${states[0]!.distance.toStringAsFixed(1)}',
        );
      }

      if (dyJump.abs() < 0.01) {
        expect(dxJump, lessThan(25));
      }
      prev = pos;
    }
  });

  test('five row snake keeps continuous screen position over many laps', () {
    final track = RsvpSnakeTrack(
      laneWidth: 280,
      laneHeight: 328,
      carWidth: 72,
      carHeight: 56,
      carGap: 6,
    );
    expect(track.rowCount, 5);

    final states = {
      0: RsvpChaosCarState(row: 0, distance: track.pitch),
    };
    const delta = 2.0;
    const laps = 2;
    final cycle = RsvpChaosLayout.multiRowSnakeCycleLength(track);
    final steps = ((cycle / delta) * laps).ceil();

    Offset primaryPos(RsvpChaosCarState state) =>
        RsvpChaosLayout.multiRowSnakePositions(track, state.distance).first;

    var prev = primaryPos(states[0]!);
    for (var i = 0; i < steps; i++) {
      RsvpChaosLayout.tick(
        states: states,
        activeStreamIndices: [0],
        track: track,
        delta: delta,
        multiRowSnake: true,
      );
      final pos = primaryPos(states[0]!);
      final dxJump = pos.dx - prev.dx;
      final dyJump = pos.dy - prev.dy;

      if (dyJump.abs() < 0.01) {
        expect(dxJump, lessThan(25));
      }
      prev = pos;
    }
  });

  test('five row last ltr to row 0 wrap is continuous', () {
    final track = RsvpSnakeTrack(
      laneWidth: 280,
      laneHeight: 328,
      carWidth: 72,
      carHeight: 56,
      carGap: 6,
    );
    final pitch = track.pitch;
    final cycle = RsvpChaosLayout.multiRowSnakeCycleLength(track);
    final row4Start = 274 + 352 + 208 + 352;
    final row4Overlap = pitch + row4Start + 200;
    final beforeDist = pitch + row4Start + 214;
    final row0Start = pitch + cycle;

    final overlap =
        RsvpChaosLayout.multiRowSnakePositions(track, row4Overlap);
    final before =
        RsvpChaosLayout.multiRowSnakePositions(track, beforeDist).first;
    final after =
        RsvpChaosLayout.multiRowSnakePositions(track, row0Start).first;

    expect(
      overlap.any((p) => (p.dy - track.rowY(0)).abs() < 0.01),
      isTrue,
      reason: 'ghost on row 0 during last LTR right exit',
    );
    expect(before.dy, closeTo(track.rowY(0), 0.01));
    expect(after.dy, closeTo(track.rowY(0), 0.01));
    expect(before.dx, closeTo(6, 1));
    expect(after.dx, closeTo(6, 1));
    expect((after.dx - before.dx).abs(), lessThan(8));
  });

  test('five row row 0 starts from left after cycle wrap', () {
    final track = RsvpSnakeTrack(
      laneWidth: 280,
      laneHeight: 328,
      carWidth: 72,
      carHeight: 56,
      carGap: 6,
    );
    final pitch = track.pitch;
    final cycle = RsvpChaosLayout.multiRowSnakeCycleLength(track);
    final afterWrap =
        RsvpChaosLayout.multiRowSnakePositions(track, pitch + cycle).first;

    expect(afterWrap.dy, closeTo(track.rowY(0), 0.01));
    expect(afterWrap.dx, closeTo(6, 1));
    expect(
      RsvpChaosLayout.rowForMultiRowSnake(pitch + cycle, track),
      0,
    );
    expect(cycle, closeTo(1401, 0.01));
  });

  test('five row row 0 to row 1 exits right gradually via ghost', () {
    final track = RsvpSnakeTrack(
      laneWidth: 280,
      laneHeight: 328,
      carWidth: 72,
      carHeight: 56,
      carGap: 6,
    );
    final pitch = track.pitch;
    const overflow = 25.0;
    final segmentS = track.laneWidth + overflow;
    final distance = pitch + (segmentS - pitch);

    final positions = RsvpChaosLayout.multiRowSnakePositions(track, distance);

    expect(
      positions.any((p) => (p.dy - track.rowY(1)).abs() < 0.01),
      isTrue,
      reason: 'ghost on row 1 during row 0 right exit',
    );
    final ghost = positions.firstWhere(
      (p) => (p.dy - track.rowY(1)).abs() < 0.01,
    );
    expect(ghost.dx, closeTo(track.laneWidth - overflow, 0.01));
    expect(track.intersectsLane(ghost), isTrue);
  });

  test('five row last ltr exits right gradually via ghost', () {
    final track = RsvpSnakeTrack(
      laneWidth: 280,
      laneHeight: 328,
      carWidth: 72,
      carHeight: 56,
      carGap: 6,
    );
    final pitch = track.pitch;
    final row4Start = 274 + 352 + 208 + 352;
    const overflow = 25.0;
    final segmentS = track.laneWidth + overflow;
    final remaining = segmentS -
        RsvpChaosLayout.rtlOverlapLength(track) -
        RsvpChaosLayout.ltrEntryStart(track);
    final distance = pitch + row4Start + remaining;

    final positions = RsvpChaosLayout.multiRowSnakePositions(track, distance);

    expect(positions, isNotEmpty);
    expect(
      positions.any((p) => (p.dy - track.rowY(0)).abs() < 0.01),
      isTrue,
    );
    final ghost = positions.firstWhere(
      (p) => (p.dy - track.rowY(0)).abs() < 0.01,
    );
    expect(ghost.dx, closeTo(overflow - track.carWidth, 0.01));
    expect(track.intersectsLane(ghost), isTrue);
  });

  test('four row rtl row 1 to ltr row 2 transition is continuous', () {
    final track = RsvpSnakeTrack(
      laneWidth: 280,
      laneHeight: 264,
      carWidth: 72,
      carHeight: 56,
      carGap: 6,
    );
    final pitch = track.pitch;
    final row1Overlap = pitch + 274 + 220;
    final row2Start = pitch + 274 + 352;

    final overlap =
        RsvpChaosLayout.multiRowSnakePositions(track, row1Overlap);
    final before =
        RsvpChaosLayout.multiRowSnakePositions(track, row1Overlap + 130).first;
    final after =
        RsvpChaosLayout.multiRowSnakePositions(track, row2Start).first;

    expect(
      overlap.any((p) => (p.dy - track.rowY(2)).abs() < 0.01),
      isTrue,
      reason: 'ghost on row 2 during RTL left exit',
    );
    expect(before.dy, closeTo(track.rowY(2), 0.01));
    expect(after.dy, closeTo(track.rowY(2), 0.01));
    expect((after.dx - before.dx).abs(), lessThan(8));
  });

  test('four row rtl row 1 exits left gradually via ghost', () {
    final track = RsvpSnakeTrack(
      laneWidth: 280,
      laneHeight: 264,
      carWidth: 72,
      carHeight: 56,
      carGap: 6,
    );
    final pitch = track.pitch;
    final leftExit = track.laneWidth - track.carWidth;
    final overlap = 25.0;
    final distance = pitch + 274 + leftExit + overlap;

    final positions = RsvpChaosLayout.multiRowSnakePositions(track, distance);

    expect(positions, hasLength(2));
    expect(positions[0].dy, closeTo(track.rowY(1), 0.01));
    expect(positions[1].dy, closeTo(track.rowY(2), 0.01));
    expect(positions[1].dx, closeTo(overlap - track.carWidth, 0.01));
    expect(track.intersectsLane(positions[0]), isTrue);
    expect(track.intersectsLane(positions[1]), isTrue);
  });

  test('four row train keeps pitch spacing on row 2', () {
    final track = RsvpSnakeTrack(
      laneWidth: 280,
      laneHeight: 264,
      carWidth: 72,
      carHeight: 56,
      carGap: 6,
    );
    const pitch = 78.0;
    const head = 860.0;

    final positions = <Offset>[
      for (var i = 0; i < 3; i++)
        RsvpChaosLayout.multiRowSnakePositions(track, head - pitch * i).first,
    ];

    for (var i = 0; i < 3; i++) {
      expect(
        RsvpChaosLayout.rowForMultiRowSnake(head - pitch * i, track),
        2,
        reason: 'car $i should be on row 2',
      );
    }

    for (var i = 1; i < positions.length; i++) {
      final gap = positions[i - 1].dx - positions[i].dx;
      expect(gap, closeTo(pitch, 2));
    }
  });

  test('placeReturned keeps pitch spacing behind train tail', () {
    final track = RsvpSnakeTrack(
      laneWidth: 280,
      laneHeight: 328,
      carWidth: 72,
      carHeight: 56,
      carGap: 6,
    );
    final states = {
      0: RsvpChaosCarState(row: 0, distance: 400),
      1: RsvpChaosCarState(row: 0, distance: 322),
    };

    RsvpChaosLayout.placeReturned(
      states: states,
      streamIndex: 2,
      track: track,
      activeStreamIndices: [0, 1, 2],
      multiRowSnake: true,
    );

    expect(states[2]!.distance, closeTo(244, 0.01));

    RsvpChaosLayout.placeReturned(
      states: states,
      streamIndex: 3,
      track: track,
      activeStreamIndices: [0, 1, 2, 3],
      multiRowSnake: true,
    );

    expect(states[3]!.distance, closeTo(166, 0.01));
    final positions = [
      for (final i in [0, 1, 2, 3])
        RsvpChaosLayout.multiRowSnakePositions(track, states[i]!.distance).first,
    ];
    for (var i = 1; i < positions.length; i++) {
      if ((positions[i].dy - positions[i - 1].dy).abs() < 0.01) {
        final gap = positions[i - 1].dx - positions[i].dx;
        expect(gap, closeTo(track.pitch, 2));
      }
    }
  });

  test('five row snake keeps continuous screen position at wide lane', () {
    final track = RsvpSnakeTrack(
      laneWidth: 400,
      laneHeight: 328,
      carWidth: 72,
      carHeight: 56,
      carGap: 6,
    );
    expect(track.rowCount, 5);

    final states = {
      0: RsvpChaosCarState(row: 0, distance: track.pitch),
    };
    const delta = 2.0;
    const laps = 2;
    final cycle = RsvpChaosLayout.multiRowSnakeCycleLength(track);
    final steps = ((cycle / delta) * laps).ceil();

    Offset primaryPos(RsvpChaosCarState state) =>
        RsvpChaosLayout.multiRowSnakePositions(track, state.distance).first;

    var prev = primaryPos(states[0]!);
    for (var i = 0; i < steps; i++) {
      RsvpChaosLayout.tick(
        states: states,
        activeStreamIndices: [0],
        track: track,
        delta: delta,
        multiRowSnake: true,
      );
      final pos = primaryPos(states[0]!);
      final dxJump = pos.dx - prev.dx;
      final dyJump = pos.dy - prev.dy;

      if (dyJump.abs() < 0.01) {
        expect(dxJump, lessThan(35));
      }
      prev = pos;
    }
  });

  test('chaos five row spread uses train pitch like snake', () {
    final track = RsvpSnakeTrack(
      laneWidth: 280,
      laneHeight: 312,
      carWidth: 72,
      carHeight: 56,
      carGap: 6,
    );
    final states = <int, RsvpChaosCarState>{};
    RsvpChaosLayout.spreadInitial(
      states: states,
      streamIndices: [0, 1, 2],
      track: track,
      multiRowChaos: true,
    );

    expect(states[0]!.row, 0);
    expect(states[1]!.row, 0);
    expect(states[0]!.distance, track.pitch);
    expect(states[1]!.distance, track.pitch * 2);
  });

  test('chaos five row follows 1-4-3-2-5 row order on wrap', () {
    final track = RsvpSnakeTrack(
      laneWidth: 280,
      laneHeight: 312,
      carWidth: 72,
      carHeight: 56,
      carGap: 6,
    );
    final states = {
      0: RsvpChaosCarState(row: 0, distance: track.pitch),
    };
    const delta = 2.0;
    final cycle = RsvpChaosLayout.multiRowChaosCycleLength(track);
    final steps = (cycle / delta).ceil();
    final rowChanges = <int>[states[0]!.row];

    for (var i = 0; i < steps; i++) {
      RsvpChaosLayout.tick(
        states: states,
        activeStreamIndices: [0],
        track: track,
        delta: delta,
        multiRowChaos: true,
      );
      final row = states[0]!.row;
      if (rowChanges.last != row) {
        rowChanges.add(row);
      }
    }

    expect(rowChanges, [0, 3, 2, 1, 4, 0]);
  });

  test('chaos five row last ltr to row 0 enters from left', () {
    final track = RsvpSnakeTrack(
      laneWidth: 280,
      laneHeight: 312,
      carWidth: 72,
      carHeight: 56,
      carGap: 6,
    );
    final pitch = track.pitch;
    const overflow = 25.0;
    final sequence = RsvpChaosLayout.chaosFiveRowSequence;
    var offset = 0.0;
    for (final row in sequence) {
      offset += RsvpChaosLayout.rowSegmentLength(row, track);
    }
    final row4Start = offset - RsvpChaosLayout.rowSegmentLength(4, track);
    final segmentS = track.laneWidth + overflow;
    final remaining = segmentS -
        RsvpChaosLayout.rtlOverlapLength(track) -
        RsvpChaosLayout.ltrEntryStart(track);
    final distance = pitch + row4Start + remaining;

    final positions =
        RsvpChaosLayout.multiRowChaosPositions(track, distance);

    expect(
      positions.any((p) => (p.dy - track.rowY(0)).abs() < 0.01),
      isTrue,
      reason: 'ghost on row 0 during row 5 right exit',
    );
    final ghost = positions.firstWhere(
      (p) => (p.dy - track.rowY(0)).abs() < 0.01,
    );
    expect(ghost.dx, closeTo(overflow - track.carWidth, 0.01));

    final cycle = RsvpChaosLayout.multiRowChaosCycleLength(track);
    final afterWrap =
        RsvpChaosLayout.multiRowChaosPositions(track, pitch + cycle).first;
    expect(afterWrap.dy, closeTo(track.rowY(0), 0.01));
    expect(afterWrap.dx, closeTo(6, 1));
  });

  test('chaos five row keeps continuous screen position over many laps', () {
    final track = RsvpSnakeTrack(
      laneWidth: 280,
      laneHeight: 312,
      carWidth: 72,
      carHeight: 56,
      carGap: 6,
    );
    expect(track.rowCount, 5);

    final states = {
      0: RsvpChaosCarState(row: 0, distance: track.pitch),
    };
    const delta = 2.0;
    const laps = 2;
    final cycle = RsvpChaosLayout.multiRowChaosCycleLength(track);
    final steps = ((cycle / delta) * laps).ceil();

    Offset primaryPos(RsvpChaosCarState state) =>
        RsvpChaosLayout.multiRowChaosPositions(track, state.distance).first;

    var prev = primaryPos(states[0]!);
    for (var i = 0; i < steps; i++) {
      RsvpChaosLayout.tick(
        states: states,
        activeStreamIndices: [0],
        track: track,
        delta: delta,
        multiRowChaos: true,
      );
      final pos = primaryPos(states[0]!);
      final dxJump = pos.dx - prev.dx;
      final dyJump = pos.dy - prev.dy;

      if (dyJump.abs() < 0.01) {
        expect(dxJump, lessThan(25));
      }
      prev = pos;
    }
  });
}
