import 'package:flutter_test/flutter_test.dart';
import 'package:reader/trainers/rsvp/rsvp_snake_track.dart';

void main() {
  test('snake alternates direction by row', () {
    const laneWidth = 320.0;
    const laneHeight = 220.0;
    const carWidth = 72.0;
    const carHeight = 56.0;

    final track = RsvpSnakeTrack(
      laneWidth: laneWidth,
      laneHeight: laneHeight,
      carWidth: carWidth,
      carHeight: carHeight,
      carGap: 6,
    );

    expect(track.rowCount, greaterThan(1));

    final travel = track.horizontalTravel;
    final row0Start = track.snakeCarPosition(0);
    final row0Mid = track.snakeCarPosition(travel * 0.5);
    expect(row0Mid.dx, greaterThan(row0Start.dx));

    final row1Start = track.snakeCarPosition(travel + 8);
    final row1Mid = track.snakeCarPosition(
      travel + 8 + laneWidth * 0.25,
    );
    expect(row1Mid.dx, lessThan(row1Start.dx));
  });

  test('each car wraps on its own when past cycle end', () {
    final track = RsvpSnakeTrack(
      laneWidth: 300,
      laneHeight: 200,
      carWidth: 72,
      carHeight: 56,
      carGap: 6,
    );

    final cycle = track.cycleLength;
    expect(cycle, greaterThan(0));

    final start = track.snakeCarPosition(0);
    final wrapped = track.snakeCarPosition(cycle);
    expect(wrapped.dx, closeTo(start.dx, 0.01));
    expect(wrapped.dy, closeTo(start.dy, 0.01));

    final headPast = track.snakeCarPosition(cycle + 40);
    final tailOnPath = track.snakeCarPosition(40);
    expect(headPast.dx, closeTo(tailOnPath.dx, 0.01));
    expect(headPast.dy, closeTo(tailOnPath.dy, 0.01));
  });

  test('ltr row exits smoothly past right edge', () {
    const laneWidth = 300.0;
    const carWidth = 72.0;
    final track = RsvpSnakeTrack(
      laneWidth: laneWidth,
      laneHeight: 200,
      carWidth: carWidth,
      carHeight: 56,
      carGap: 6,
    );

    final nearExit = track.snakeCarPosition(laneWidth + carWidth * 0.5);
    expect(nearExit.dx, greaterThan(laneWidth - carWidth));
    expect(track.intersectsLane(nearExit), isTrue);

    final fullyOut = track.snakeCarPosition(laneWidth + carWidth);
    expect(fullyOut.dx, closeTo(laneWidth, 0.01));
    expect(track.intersectsLane(fullyOut), isFalse);
  });

  test('rtl row turns down at inner left edge like right side', () {
    const laneWidth = 300.0;
    const carWidth = 72.0;
    const rowGap = 8.0;
    final track = RsvpSnakeTrack(
      laneWidth: laneWidth,
      laneHeight: 220,
      carWidth: carWidth,
      carHeight: 56,
      carGap: 6,
      rowGap: rowGap,
    );

    final ltrTravel = track.horizontalTravel;
    final rtlEnd = track.snakeCarPosition(ltrTravel + rowGap + laneWidth);
    final dropMid = track.snakeCarPosition(
      ltrTravel + rowGap + laneWidth + rowGap * 0.5,
    );

    expect(rtlEnd.dx, closeTo(-carWidth, 0.01));
    expect(track.intersectsLane(rtlEnd), isFalse);
    expect(dropMid.dx, closeTo(0, 0.01));
    expect(track.visibleInLane(dropMid), isTrue);
    expect(dropMid.dy, greaterThan(rtlEnd.dy));
  });

  test('vertical connector moves down to next row on right side', () {
    const laneWidth = 300.0;
    const carHeight = 56.0;
    const rowGap = 8.0;
    final track = RsvpSnakeTrack(
      laneWidth: laneWidth,
      laneHeight: 200,
      carWidth: 72,
      carHeight: carHeight,
      carGap: 6,
      rowGap: rowGap,
    );

    final travel = track.horizontalTravel;
    final beforeDrop = track.snakeCarPosition(travel - 1);
    final afterDrop = track.snakeCarPosition(travel + rowGap * 0.5);
    expect(afterDrop.dy, greaterThan(beforeDrop.dy));
  });

  test('chaos keeps cars on fixed rows without vertical drift', () {
    final track = RsvpSnakeTrack(
      laneWidth: 300,
      laneHeight: 200,
      carWidth: 72,
      carHeight: 56,
      carGap: 6,
    );

    final y0 = track.chaosCarPositionAt(row: 0, distance: 40).dy;
    final y1 = track.chaosCarPositionAt(row: 1, distance: 40).dy;
    expect(y0, isNot(y1));

    final moved = track.chaosCarPositionAt(row: 0, distance: 140).dy;
    expect(moved, closeTo(y0, 0.01));
  });

  test('train cars follow head with fixed pitch', () {
    final track = RsvpSnakeTrack(
      laneWidth: 300,
      laneHeight: 200,
      carWidth: 72,
      carHeight: 56,
      carGap: 6,
    );
    const head = 120.0;
    final pitch = track.pitch;

    final headPos = track.snakeCarPosition(head);
    final nextPos = track.snakeCarPosition(head - pitch);

    expect((headPos - nextPos).distance, closeTo(pitch, 1.5));
  });

  test('snake never draws syllables with left edge past field', () {
    const laneWidth = 360.0;
    final track = RsvpSnakeTrack(
      laneWidth: laneWidth,
      laneHeight: 280,
      carWidth: 72,
      carHeight: 56,
      carGap: 6,
    );
    const trainCars = 11;
    final pitch = track.pitch;

    for (var step = 0; step <= 500; step++) {
      final head = step * 4.0;
      for (var i = 0; i < trainCars; i++) {
        final distance = head - i * pitch;
        if (distance < 0) continue;
        final pos = track.snakeCarPosition(distance);
        if (track.visibleInLane(pos)) {
          expect(pos.dx, greaterThanOrEqualTo(0));
        }
      }
    }
  });
}
