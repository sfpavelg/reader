import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:reader/services/dictionary_service.dart';
import 'package:reader/trainers/rsvp/rsvp_fixation.dart';
import 'package:reader/trainers/rsvp/rsvp_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DictionaryService dictionary;
  late RsvpGenerator generator;

  setUp(() async {
    dictionary = DictionaryService(random: Random(3));
    await dictionary.initialize();
    generator = RsvpGenerator(dictionary: dictionary, random: Random(3));
  });

  test('level 1 produces syllable series', () {
    final passage = generator.generate(levelId: 1);
    expect(passage.words, hasLength(RsvpGenerator.syllableCount));
    expect(passage.words.every((w) => w.isNotEmpty), isTrue);
  });

  test('level 3 splits sentence into words', () {
    final passage = generator.generate(levelId: 3);
    expect(passage.words, isNotEmpty);
    expect(passage.words.length, lessThanOrEqualTo(RsvpGenerator.sentenceWordCap));
  });

  test('interval decreases when wpm increases', () {
    final slow = RsvpGenerator.intervalForWpm(40);
    final fast = RsvpGenerator.intervalForWpm(80);
    expect(fast.inMilliseconds, lessThan(slow.inMilliseconds));
  });

  test('fixation index is middle of word', () {
    expect(rsvpFixationIndex('КОТ'), 1);
    expect(rsvpFixationIndex('МА'), 0);
    expect(rsvpFixationIndex('МАМА'), 1);
  });
}
