import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:reader/services/dictionary_service.dart';
import 'package:reader/trainers/rsvp/rsvp_generator.dart';
import 'package:reader/trainers/rsvp/rsvp_speed.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DictionaryService dictionary;
  late RsvpGenerator generator;

  setUp(() async {
    dictionary = DictionaryService(random: Random(3));
    await dictionary.initialize();
    generator = RsvpGenerator(
      dictionary: dictionary,
      random: Random(3),
      streamLength: 12,
    );
  });

  test('generate produces task with target syllables in stream', () {
    final task = generator.generate();
    expect(task.word, isNotEmpty);
    expect(task.syllables, isNotEmpty);
    expect(task.streamSyllables, hasLength(12));
    for (final syllable in task.syllables) {
      expect(task.streamSyllables, contains(syllable));
    }
  });

  test('stream includes duplicate hint syllables', () async {
    final dict = DictionaryService(random: Random(3));
    await dict.initialize();
    final mama = dict.entriesForLevel(2).firstWhere(
          (e) => e.text == 'МАМА',
        );
    final task = RsvpGenerator(
      dictionary: dict,
      random: Random(3),
    ).fromEntry(mama);
    expect(task.streamSyllables.where((s) => s == 'МА').length, 2);
    expect(task.matchPicked(task.syllables)?.text, 'МАМА');
  });

  test('spellable words include target word', () {
    final task = generator.generate();
    final match = task.matchPicked(task.syllables);
    expect(match, isNotNull);
    expect(match!.text, task.word);
  });

  test('faster speed has shorter interval', () {
    final slow = RsvpSpeed.intervalForSpeed(RsvpSpeed.slow);
    final fast = RsvpSpeed.intervalForSpeed(RsvpSpeed.fast);
    expect(fast.inMilliseconds, lessThan(slow.inMilliseconds));
  });
}
