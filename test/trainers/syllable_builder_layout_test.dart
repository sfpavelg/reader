import 'package:flutter_test/flutter_test.dart';
import 'package:reader/trainers/syllable_builder/syllable_builder_layout.dart';
import 'package:reader/trainers/syllable_builder/syllable_builder_task.dart';

void main() {
  test('separateSparseBlocks pushes overlapping blocks apart', () {
    final blocks = [
      FallingSyllableBlock(
        blockId: 'a',
        text: 'КО',
        targetSequenceIndex: 0,
        spawnWave: 5,
        xFactor: 0.5,
        startY: -80,
        driftSpeed: 1,
        xPhase: 0,
      ),
      FallingSyllableBlock(
        blockId: 'b',
        text: 'ЗА',
        targetSequenceIndex: null,
        spawnWave: 0,
        xFactor: 0.52,
        startY: -70,
        driftSpeed: 1,
        xPhase: 0,
      ),
    ];
    blocks[0].y = 120;
    blocks[1].y = 130;

    SyllableBuilderLayout.separateSparseBlocks(blocks, 320);

    expect(
      blocks[1].y - blocks[0].y,
      greaterThanOrEqualTo(SyllableBuilderLayout.minVerticalGap - 0.01),
    );
  });

  test('separateSparseBlocks skips when many blocks are active', () {
    final blocks = List.generate(
      8,
      (i) => FallingSyllableBlock(
        blockId: '$i',
        text: 'S$i',
        targetSequenceIndex: i < 2 ? i : null,
        spawnWave: i,
        xFactor: 0.5,
        startY: -80,
        driftSpeed: 1,
      )..y = 100 + i.toDouble(),
    );

    SyllableBuilderLayout.separateSparseBlocks(blocks, 320);

    expect(blocks[1].y, closeTo(101, 0.01));
  });
}
