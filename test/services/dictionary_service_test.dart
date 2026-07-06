import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:reader/services/dictionary_service.dart';
import 'package:reader/trainers/schulte/schulte_spellable_words.dart';
import 'package:reader/trainers/schulte/schulte_word_picker.dart';
import 'package:reader/trainers/syllable_builder/syllable_builder_level.dart';
import 'package:reader/trainers/syllable_builder/syllable_builder_word_picker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DictionaryService dictionary;

  setUp(() async {
    dictionary = DictionaryService(random: Random(1));
    await dictionary.initialize();
  });

  test('level 2 includes supplemental grid words', () {
    final texts = dictionary.entriesForLevel(2).map((e) => e.text).toSet();

    expect(texts, contains('МОРЕ'));
    expect(texts, contains('ПАНАМА'));
    expect(texts, contains('БАЗА'));
    expect(texts, contains('ДАНЯ'));
    expect(texts, contains('ЛАДА'));
    expect(texts, contains('ВОВА'));
    expect(texts, isNot(contains('НАША')));
  });

  test('schulte picker pool includes supplemental two-syllable words', () {
    final picker = SchulteWordPicker(dictionary: dictionary);
    final texts = picker.eligiblePool.map((e) => e.text).toSet();

    expect(texts, contains('МОРЕ'));
    expect(texts, contains('БОЛОТО'));
  });

  test('schulte picker pool includes gore', () {
    final picker = SchulteWordPicker(dictionary: dictionary);
    final texts = picker.eligiblePool.map((e) => e.text).toSet();

    expect(texts, contains('ГОРЕ'));
    expect(texts, contains('ДОРОГА'));
    expect(texts, contains('РОЗА'));
    expect(texts, contains('КАША'));
  });

  test('schulte accepts dasha on grid with da and sha', () {
    const grid = ['ДА', 'ША', 'ПА', 'НО', 'РО', 'ЛА', 'МО', 'НЕ', 'МА'];
    final words = SchulteSpellableWords.findForGrid(
      dictionary: dictionary,
      gridSyllables: grid,
    );

    expect(
      SchulteSpellableWords.matchPicked(words, ['ДА', 'ША'])?.text,
      'ДАША',
    );
  });

  test('syllable builder pool includes supplemental words', () {
    final picker = SyllableBuilderWordPicker(
      dictionary: dictionary,
      trainerLevelId: SyllableBuilderLevel.level2,
    );
    final texts = picker.eligiblePool.map((e) => e.text).toSet();

    expect(texts, contains('МОЛОКО'));
    expect(texts, contains('ВОРОНА'));
  });

  test('tachistoscope can pick supplemental words at level 2', () {
    final entry = dictionary.pickRandom(levelId: 2);
    expect(entry, isNotNull);

    final pool = dictionary.entriesForLevel(2);
    expect(pool.any((e) => e.text == 'МОРЕ'), isTrue);
  });
}
