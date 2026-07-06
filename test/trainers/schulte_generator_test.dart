import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:reader/services/dictionary_service.dart';
import 'package:reader/trainers/schulte/schulte_generator.dart';
import 'package:reader/trainers/schulte/schulte_word_picker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DictionaryService dictionary;
  late SchulteGenerator generator;

  setUp(() async {
    dictionary = DictionaryService(random: Random(7));
    await dictionary.initialize();
    generator = SchulteGenerator(dictionary: dictionary, random: Random(7));
  });

  test('3x3 grid has 9 cells', () {
    final task = generator.generate();
    expect(task.gridSize, 3);
    expect(task.cells, hasLength(9));
  });

  test('target word uses only two-letter syllables', () {
    final task = generator.generate();
    expect(
      task.syllables.every((s) => s.length == 2),
      isTrue,
      reason: 'word ${task.word}',
    );
  });

  test('grid contains every syllable needed for the word', () {
    final task = generator.generate();
    final gridCounts = <String, int>{};
    for (final cell in task.cells) {
      gridCounts[cell.text] = (gridCounts[cell.text] ?? 0) + 1;
    }

    final needCounts = <String, int>{};
    for (final s in task.syllables) {
      needCounts[s] = (needCounts[s] ?? 0) + 1;
    }

    for (final entry in needCounts.entries) {
      expect(
        gridCounts[entry.key] ?? 0,
        greaterThanOrEqualTo(entry.value),
        reason: 'missing ${entry.key} for ${task.word}',
      );
    }
  });

  test('word picker pool has multi-syllable two-letter words', () {
    final picker = SchulteWordPicker(dictionary: dictionary);
    expect(picker.poolSize, greaterThan(5));
    for (final entry in picker.eligiblePool) {
      expect(SchulteWordPicker.isEligibleEntry(entry), isTrue);
    }
  });

  test('task includes target word among spellable words', () {
    final task = generator.generate();
    final texts = task.spellableWords.map((w) => w.text).toSet();
    expect(texts, contains(task.word));
    expect(task.matchPicked(List<String>.from(task.syllables))?.text, task.word);
  });

  test('spellable words are sorted alphabetically', () {
    final task = generator.generate();
    final texts = task.spellableWords.map((w) => w.text).toList();
    expect(texts, orderedEquals(List<String>.from(texts)..sort()));
  });
}
