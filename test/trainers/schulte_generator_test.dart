import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:reader/services/dictionary_service.dart';
import 'package:reader/trainers/schulte/schulte_difficulty.dart';
import 'package:reader/trainers/schulte/schulte_generator.dart';
import 'package:reader/trainers/schulte/schulte_word_picker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DictionaryService dictionary;

  setUp(() async {
    dictionary = DictionaryService(random: Random(7));
    await dictionary.initialize();
  });

  test('easy grid has 12 cells', () {
    final generator = SchulteGenerator(
      dictionary: dictionary,
      random: Random(7),
      difficulty: SchulteDifficulty.easy,
    );
    final task = generator.generate();
    expect(task.cols, 4);
    expect(task.rows, 3);
    expect(task.cells, hasLength(12));
  });

  test('medium grid has 24 cells', () {
    final generator = SchulteGenerator(
      dictionary: dictionary,
      random: Random(7),
      difficulty: SchulteDifficulty.medium,
    );
    final task = generator.generate();
    expect(task.cols, 6);
    expect(task.rows, 4);
    expect(task.cells, hasLength(24));
    expect(task.filledCellCount, 24);
  });

  test('hard grid has 48 cells', () {
    final generator = SchulteGenerator(
      dictionary: dictionary,
      random: Random(7),
      difficulty: SchulteDifficulty.hard,
    );
    final task = generator.generate();
    expect(task.cols, 8);
    expect(task.rows, 6);
    expect(task.cells, hasLength(48));
  });

  test('packed words use only two-letter syllables', () {
    final generator = SchulteGenerator(
      dictionary: dictionary,
      random: Random(7),
    );
    final task = generator.generate();
    expect(task.packedWords, isNotEmpty);
    for (final cell in task.cells) {
      expect(cell.text, isNotNull);
      expect(cell.text!.length, 2);
    }
  });

  test('grid contains every syllable from packed words', () {
    final generator = SchulteGenerator(
      dictionary: dictionary,
      random: Random(7),
    );
    final task = generator.generate();
    final gridCounts = <String, int>{};
    for (final cell in task.cells) {
      final t = cell.text!;
      gridCounts[t] = (gridCounts[t] ?? 0) + 1;
    }

    final needCounts = <String, int>{};
    for (final id in task.packedEntryIds) {
      final entry = dictionary.entriesForLevel(2).firstWhere((e) => e.id == id);
      for (final s in entry.syllables) {
        needCounts[s] = (needCounts[s] ?? 0) + 1;
      }
    }

    for (final entry in needCounts.entries) {
      expect(
        gridCounts[entry.key] ?? 0,
        greaterThanOrEqualTo(entry.value),
        reason: 'missing ${entry.key}',
      );
    }
  });

  test('most cells come from packed words (few spares)', () {
    final generator = SchulteGenerator(
      dictionary: dictionary,
      random: Random(7),
      difficulty: SchulteDifficulty.medium,
    );
    final task = generator.generate();
    var packedSyllables = 0;
    for (final id in task.packedEntryIds) {
      final entry = dictionary.entriesForLevel(2).firstWhere((e) => e.id == id);
      packedSyllables += entry.syllables.length;
    }
    expect(packedSyllables, greaterThanOrEqualTo(21));
    expect(task.cellCount - packedSyllables, lessThanOrEqualTo(3));
  });

  test('word picker pool has multi-syllable two-letter words', () {
    final picker = SchulteWordPicker(dictionary: dictionary, maxSyllables: 5);
    expect(picker.poolSize, greaterThan(5));
    for (final entry in picker.eligiblePool) {
      expect(
        SchulteWordPicker.isEligibleEntry(entry, maxSyllables: 5),
        isTrue,
      );
    }
  });

  test('every packed word is spellable on the grid', () {
    for (final level in SchulteDifficulty.values) {
      final generator = SchulteGenerator(
        dictionary: dictionary,
        random: Random(7),
        difficulty: level,
      );
      final task = generator.generate();
      final texts = task.spellableWords.map((w) => w.text).toSet();
      for (final word in task.packedWords) {
        expect(texts, contains(word), reason: level.label);
      }
    }
  });

  test('spellable words are sorted alphabetically', () {
    final generator = SchulteGenerator(
      dictionary: dictionary,
      random: Random(7),
    );
    final task = generator.generate();
    final texts = task.spellableWords.map((w) => w.text).toList();
    expect(texts, orderedEquals(List<String>.from(texts)..sort()));
  });

  test('combinations label lists syllable lengths', () {
    final generator = SchulteGenerator(
      dictionary: dictionary,
      random: Random(7),
    );
    final task = generator.generate();
    final label = task.remainingCombinationsLabel();
    expect(label, isNotEmpty);
    expect(task.remainingSpellableCount(), greaterThan(0));
  });

  test('menu labels match mock', () {
    expect(SchulteDifficulty.easy.menuLabel, 'Простой — 12 слогов');
    expect(SchulteDifficulty.medium.menuLabel, 'Средний — 24 слогов');
    expect(SchulteDifficulty.hard.menuLabel, 'Сложный — 48 слогов');
  });
}
