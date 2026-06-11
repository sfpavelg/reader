import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:reader/services/dictionary_service.dart';
import 'package:reader/trainers/bookmark_window/bookmark_window_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DictionaryService dictionary;
  late BookmarkWindowGenerator generator;

  setUp(() async {
    dictionary = DictionaryService(random: Random(5));
    await dictionary.initialize();
    generator = BookmarkWindowGenerator(
      dictionary: dictionary,
      random: Random(5),
    );
  });

  test('level 3 splits sentence into fragments', () {
    final passage = generator.generate(levelId: 3);
    expect(passage.fragments, isNotEmpty);
    expect(passage.fullText, passage.fragments.join(' '));
  });

  test('level 2 builds word chain', () {
    final passage = generator.generate(levelId: 2);
    expect(
      passage.fragments,
      hasLength(BookmarkWindowGenerator.wordChainCount),
    );
  });

  test('faster speed means shorter interval', () {
    final slow = BookmarkWindowGenerator.intervalForMs(2000);
    final fast = BookmarkWindowGenerator.intervalForMs(900);
    expect(fast.inMilliseconds, lessThan(slow.inMilliseconds));
  });
}
