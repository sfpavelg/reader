import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:reader/data/hive/local_storage.dart';
import 'package:reader/services/dictionary_service.dart';
import 'package:reader/trainers/syllable_builder/syllable_builder_session_store.dart';
import 'package:reader/trainers/syllable_builder/syllable_builder_word_picker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DictionaryService dictionary;
  late SyllableBuilderWordPicker picker;

  setUp(() async {
    await LocalStorage.initialize(testPath: 'syllable_picker_${DateTime.now().microsecondsSinceEpoch}');
    dictionary = DictionaryService(random: Random(3));
    await dictionary.initialize();
    picker = SyllableBuilderWordPicker(dictionary: dictionary, random: Random(3));
  });

  test('pool has many multi-syllable words', () {
    expect(picker.poolSize, greaterThan(40));
  });

  test('does not repeat until pool is exhausted', () async {
    final seen = <String>{};
    final poolSize = picker.poolSize;

    for (var i = 0; i < poolSize; i++) {
      final entry = picker.pickNext();
      expect(seen.contains(entry.id), isFalse, reason: 'repeat at round $i: ${entry.text}');
      seen.add(entry.id);
      await SyllableBuilderSessionStore.recordCompleted(
        entry.id,
        recentCap: picker.recentCap,
      );
    }

    expect(seen.length, poolSize);
  });

  test('all dictionary syllables reconstruct the word text', () {
    for (final entry in picker.eligiblePool) {
      expect(entry.syllables.join(), entry.text, reason: entry.id);
    }
  });
}
