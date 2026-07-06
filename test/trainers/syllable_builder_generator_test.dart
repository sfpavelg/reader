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
    expect(task.blocks, hasLength(task.syllables.length));
    expect(task.word, task.syllables.join());
  });

  test('each block has unique sequence indices', () {
    final task = generator.generate();
    final indices = task.blocks.map((b) => b.sequenceIndex).toList()..sort();
    expect(indices, List.generate(task.syllableCount, (i) => i));
  });

  test('blocks use separate horizontal lanes', () {
    final task = generator.generate();
    final xs = task.blocks.map((b) => b.xFactor).toList()..sort();
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

  test('word picker pool is large enough for variety', () {
    expect(generator.wordPicker.poolSize, greaterThan(15));
  });
}
