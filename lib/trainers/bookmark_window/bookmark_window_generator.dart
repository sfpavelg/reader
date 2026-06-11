import 'dart:math';

import '../../services/dictionary_service.dart';
import 'bookmark_window_passage.dart';

class BookmarkWindowGenerator {
  BookmarkWindowGenerator({
    required DictionaryService dictionary,
    Random? random,
  })  : _dictionary = dictionary,
        _random = random ?? Random();

  final DictionaryService _dictionary;
  final Random _random;

  static const int wordChainCount = 5;

  BookmarkWindowPassage generate({
    required int levelId,
    int? maxDifficulty,
    Set<String> excludeEntryIds = const {},
  }) {
    if (levelId == 3) {
      return _fromSentence(levelId, maxDifficulty, excludeEntryIds);
    }
    return _fromWordChain(levelId, maxDifficulty, excludeEntryIds);
  }

  BookmarkWindowPassage _fromSentence(
    int levelId,
    int? maxDifficulty,
    Set<String> excludeEntryIds,
  ) {
    final pool = _dictionary
        .entriesForLevel(levelId, maxDifficulty: maxDifficulty)
        .where((e) => !excludeEntryIds.contains(e.id))
        .toList()
      ..shuffle(_random);

    if (pool.isEmpty) {
      throw StateError('No bookmark-window sentences for level $levelId');
    }

    final entry = pool.first;
    final fragments = entry.text
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    return BookmarkWindowPassage(
      passageId: 'bookmark_${DateTime.now().microsecondsSinceEpoch}',
      levelId: levelId,
      fullText: entry.text,
      fragments: fragments,
      sourceEntryIds: [entry.id],
    );
  }

  BookmarkWindowPassage _fromWordChain(
    int levelId,
    int? maxDifficulty,
    Set<String> excludeEntryIds,
  ) {
    final entries = _dictionary.pickDistinct(
      levelId: levelId,
      count: wordChainCount,
      maxDifficulty: maxDifficulty,
      excludeIds: excludeEntryIds,
    );

    final fragments = entries.map((e) => e.text).toList();

    return BookmarkWindowPassage(
      passageId: 'bookmark_${DateTime.now().microsecondsSinceEpoch}',
      levelId: levelId,
      fullText: fragments.join(' '),
      fragments: fragments,
      sourceEntryIds: entries.map((e) => e.id).toList(),
    );
  }

  static int defaultMsPerFragment(int levelId) {
    switch (levelId) {
      case 2:
        return 1400;
      case 3:
        return 1200;
      default:
        return 1500;
    }
  }

  static Duration intervalForMs(int msPerFragment) {
    final safe = msPerFragment.clamp(600, 4000);
    return Duration(milliseconds: safe);
  }
}
