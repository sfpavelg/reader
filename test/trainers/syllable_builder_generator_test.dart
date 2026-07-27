import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:reader/services/dictionary_service.dart';
import 'package:reader/trainers/syllable_builder/syllable_builder_generator.dart';
import 'package:reader/trainers/syllable_builder/syllable_builder_level.dart';
import 'package:reader/trainers/syllable_builder/syllable_builder_layout.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DictionaryService dictionary;
  late SyllableBuilderGenerator generator;

  setUp(() async {
    dictionary = DictionaryService(random: Random(11));
    await dictionary.initialize();
    generator = SyllableBuilderGenerator(
      dictionary: dictionary,
      random: Random(11),
      trainerLevelId: SyllableBuilderLevel.level2,
    );
  });

  test('generates task with ordered syllables matching word', () {
    final task = generator.generate();
    expect(task.syllables.length, greaterThanOrEqualTo(2));
    expect(task.targetBlocks, hasLength(task.syllables.length));
    expect(task.word, task.syllables.join());
  });

  test('includes distractor blocks beyond target syllables', () {
    final task = generator.generate();
    expect(task.blocks.length, greaterThan(task.syllables.length));
    expect(task.blocks.where((b) => b.isDistractor), isNotEmpty);
  });

  test('each target block has unique sequence indices', () {
    final task = generator.generate();
    final indices = task.targetBlocks.map((b) => b.targetSequenceIndex).toList()
      ..sort();
    expect(indices, List.generate(task.syllableCount, (i) => i));
  });

  test('target blocks use separate horizontal lanes', () {
    final task = generator.generate();
    final xs = task.targetBlocks.map((b) => b.xFactor).toList()..sort();
    for (var i = 1; i < xs.length; i++) {
      expect(xs[i] - xs[i - 1], greaterThan(0.18));
    }
  });

  test('lanes helper spaces three syllables across the width', () {
    final xs = List.generate(
      3,
      (i) => SyllableBuilderLayout.laneXFactor(i, 3),
    );
    expect(xs[0], lessThan(0.2));
    expect(xs[2], greaterThan(0.8));
  });

  test('harder levels add more distractor syllables', () {
    expect(
      SyllableBuilderLevel.distractorCount(2, SyllableBuilderLevel.level1),
      lessThan(
        SyllableBuilderLevel.distractorCount(2, SyllableBuilderLevel.level2),
      ),
    );
    expect(
      SyllableBuilderLevel.distractorCount(2, SyllableBuilderLevel.level2),
      lessThan(
        SyllableBuilderLevel.distractorCount(2, SyllableBuilderLevel.level3),
      ),
    );
  });

  test('simple level uses only two-letter distractors', () {
    final task = SyllableBuilderGenerator(
      dictionary: dictionary,
      random: Random(11),
      trainerLevelId: SyllableBuilderLevel.level1,
    ).generate();

    for (final block in task.blocks) {
      expect(block.text.length, 2);
    }
  });

  test('medium level uses only simple syllables on screen', () {
    final task = SyllableBuilderGenerator(
      dictionary: dictionary,
      random: Random(11),
      trainerLevelId: SyllableBuilderLevel.level2,
    ).generate();

    for (final block in task.blocks) {
      expect(
        block.text.length,
        lessThanOrEqualTo(2),
        reason: 'unexpected complex syllable: ${block.text}',
      );
    }
  });

  test('level labels are readable', () {
    expect(SyllableBuilderLevel.label(SyllableBuilderLevel.level1), 'Простой');
    expect(SyllableBuilderLevel.label(SyllableBuilderLevel.level2), 'Средний');
    expect(SyllableBuilderLevel.label(SyllableBuilderLevel.level3), 'Сложный');
  });

  test('spawn waves are unique and shuffled across all blocks', () {
    final task = SyllableBuilderGenerator(
      dictionary: dictionary,
      random: Random(11),
      trainerLevelId: SyllableBuilderLevel.level1,
    ).generate();

    final waves = task.blocks.map((b) => b.spawnWave).toList()..sort();
    expect(waves, List.generate(task.blocks.length, (i) => i));
  });

  test('target spawn order is not locked to word order', () {
    // Fixed seed where targets are not monotonically ordered by sequence index.
    var foundShuffledTargets = false;
    for (var seed = 0; seed < 80; seed++) {
      final task = SyllableBuilderGenerator(
        dictionary: dictionary,
        random: Random(seed),
        trainerLevelId: SyllableBuilderLevel.level1,
      ).generate();
      final targets = task.targetBlocks.toList()
        ..sort((a, b) => a.spawnWave.compareTo(b.spawnWave));
      final sequenceByAppear =
          targets.map((b) => b.targetSequenceIndex!).toList();
      if (sequenceByAppear.length >= 2 &&
          sequenceByAppear.first != 0) {
        foundShuffledTargets = true;
        break;
      }
    }
    expect(foundShuffledTargets, isTrue);
  });

  test('needed syllables can appear before some distractors', () {
    var found = false;
    for (var seed = 0; seed < 80; seed++) {
      final task = SyllableBuilderGenerator(
        dictionary: dictionary,
        random: Random(seed),
        trainerLevelId: SyllableBuilderLevel.level1,
      ).generate();
      final minTarget = task.targetBlocks
          .map((b) => b.spawnWave)
          .reduce(min);
      final maxDistractor = task.blocks
          .where((b) => b.isDistractor)
          .map((b) => b.spawnWave)
          .reduce(max);
      if (minTarget < maxDistractor) {
        found = true;
        break;
      }
    }
    expect(found, isTrue);
  });

  test('word picker pool is large enough for variety', () {
    expect(generator.wordPicker.poolSize, greaterThan(15));
  });
}
