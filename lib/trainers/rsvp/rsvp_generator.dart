import 'dart:math';

import '../../services/dictionary_service.dart';
import 'rsvp_passage.dart';

class RsvpGenerator {
  RsvpGenerator({
    required DictionaryService dictionary,
    Random? random,
  })  : _dictionary = dictionary,
        _random = random ?? Random();

  final DictionaryService _dictionary;
  final Random _random;

  static const int syllableCount = 8;
  static const int wordCount = 6;
  static const int sentenceWordCap = 10;

  RsvpPassage generate({
    required int levelId,
    int? maxDifficulty,
    Set<String> excludeEntryIds = const {},
  }) {
    switch (levelId) {
      case 1:
        return _fromDistinctEntries(
          levelId: levelId,
          count: syllableCount,
          maxDifficulty: maxDifficulty,
          excludeEntryIds: excludeEntryIds,
        );
      case 2:
        return _fromDistinctEntries(
          levelId: levelId,
          count: wordCount,
          maxDifficulty: maxDifficulty,
          excludeEntryIds: excludeEntryIds,
        );
      case 3:
        return _fromSentenceEntry(
          levelId: levelId,
          maxDifficulty: maxDifficulty,
          excludeEntryIds: excludeEntryIds,
        );
      default:
        throw ArgumentError('Unknown RSVP level: $levelId');
    }
  }

  RsvpPassage _fromDistinctEntries({
    required int levelId,
    required int count,
    int? maxDifficulty,
    required Set<String> excludeEntryIds,
  }) {
    final entries = _dictionary.pickDistinct(
      levelId: levelId,
      count: count,
      maxDifficulty: maxDifficulty,
      excludeIds: excludeEntryIds,
    );

    return RsvpPassage(
      passageId: 'rsvp_${DateTime.now().microsecondsSinceEpoch}',
      levelId: levelId,
      words: entries.map((e) => e.text).toList(),
      sourceEntryIds: entries.map((e) => e.id).toList(),
    );
  }

  RsvpPassage _fromSentenceEntry({
    required int levelId,
    int? maxDifficulty,
    required Set<String> excludeEntryIds,
  }) {
    final pool = _dictionary
        .entriesForLevel(levelId, maxDifficulty: maxDifficulty)
        .where((e) => !excludeEntryIds.contains(e.id))
        .toList()
      ..shuffle(_random);

    if (pool.isEmpty) {
      throw StateError('No RSVP sentence entries for level $levelId');
    }

    final entry = pool.first;
    final words = entry.text
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .take(sentenceWordCap)
        .toList();

    return RsvpPassage(
      passageId: 'rsvp_${DateTime.now().microsecondsSinceEpoch}',
      levelId: levelId,
      words: words,
      sourceEntryIds: [entry.id],
    );
  }

  static int defaultWpmForLevel(int levelId) {
    switch (levelId) {
      case 1:
        return 45;
      case 2:
        return 65;
      case 3:
        return 55;
      default:
        return 60;
    }
  }

  static Duration intervalForWpm(int wpm) {
    final safe = wpm.clamp(20, 240);
    final ms = (60000 / safe).round();
    return Duration(milliseconds: ms);
  }
}
