import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:reader/models/dictionary/dictionary_entry.dart';
import 'package:reader/services/dictionary_service.dart';
import 'package:reader/trainers/syllable_builder/syllable_builder_level.dart';
import 'package:reader/trainers/syllable_builder/syllable_builder_word_picker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DictionaryService dictionary;

  setUp(() async {
    dictionary = DictionaryService(random: Random(1));
    await dictionary.initialize();
  });

  test('level 1 allows at most two two-letter syllables', () {
    final picker = SyllableBuilderWordPicker(
      dictionary: dictionary,
      trainerLevelId: SyllableBuilderLevel.level1,
    );
    expect(picker.poolSize, greaterThan(10));
    for (final entry in picker.eligiblePool) {
      expect(entry.syllables.length, lessThanOrEqualTo(2));
      expect(entry.syllables.every((s) => s.length <= 2), isTrue);
    }
  });

  test('level 2 requires two or more two-letter syllables', () {
    final picker = SyllableBuilderWordPicker(
      dictionary: dictionary,
      trainerLevelId: SyllableBuilderLevel.level2,
    );
    expect(picker.poolSize, greaterThan(15));
    for (final entry in picker.eligiblePool) {
      expect(entry.syllables.length, greaterThanOrEqualTo(2));
      expect(entry.syllables.every((s) => s.length <= 2), isTrue);
      expect(
        SyllableBuilderLevel.isSimpleTwoSyllableWord(entry.syllables),
        isFalse,
        reason: entry.text,
      );
    }
  });

  test('level 3 includes words with long syllables', () {
    final level2Pool = SyllableBuilderWordPicker(
      dictionary: dictionary,
      trainerLevelId: SyllableBuilderLevel.level2,
    ).eligiblePool;
    final level3Pool = SyllableBuilderWordPicker(
      dictionary: dictionary,
      trainerLevelId: SyllableBuilderLevel.level3,
    ).eligiblePool;

    expect(level3Pool.length, greaterThan(level2Pool.length));

    bool hasLongSyllable(DictionaryEntry e) =>
        e.syllables.any((s) => s.length > 2);

    expect(level3Pool.any(hasLongSyllable), isTrue);
    expect(level2Pool.any(hasLongSyllable), isFalse);
    for (final entry in level3Pool) {
      expect(
        SyllableBuilderLevel.isSimpleTwoSyllableWord(entry.syllables),
        isFalse,
        reason: entry.text,
      );
    }
  });
}
