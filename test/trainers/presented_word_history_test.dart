import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:reader/data/hive/local_storage.dart';
import 'package:reader/services/dictionary_service.dart';
import 'package:reader/trainers/rsvp/rsvp_generator.dart';
import 'package:reader/trainers/rsvp/rsvp_session_store.dart';
import 'package:reader/trainers/schulte/schulte_generator.dart';
import 'package:reader/trainers/schulte/schulte_session_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DictionaryService dictionary;

  setUp(() async {
    await LocalStorage.initialize(
      testPath: 'presented_words_${DateTime.now().microsecondsSinceEpoch}',
    );
    dictionary = DictionaryService(random: Random(3));
    await dictionary.initialize();
  });

  test('schulte does not repeat presented word on immediate refresh', () async {
    final generator = SchulteGenerator(dictionary: dictionary, random: Random(3));

    final first = generator.generate();
    await SchulteSessionStore.recordPresented(
      first.entryId,
      recentCap: generator.wordPicker.recentCap,
    );

    final second = generator.generate();
    expect(second.entryId, isNot(first.entryId));
  });

  test('rsvp does not repeat presented word on immediate refresh', () async {
    final generator = RsvpGenerator(dictionary: dictionary, random: Random(3));

    final first = generator.generate();
    await RsvpSessionStore.recordPresented(
      first.entryId,
      recentCap: generator.wordPicker.recentCap,
    );

    final second = generator.generate();
    expect(second.entryId, isNot(first.entryId));
  });
}
