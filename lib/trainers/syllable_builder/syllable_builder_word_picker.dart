import 'dart:math';

import '../../models/dictionary/dictionary_entry.dart';
import '../../services/dictionary_service.dart';
import 'syllable_builder_session_store.dart';

/// Выбор следующего слова: без повтора, пока не пройден весь пул.
class SyllableBuilderWordPicker {
  SyllableBuilderWordPicker({
    required DictionaryService dictionary,
    Random? random,
    this.levelId = 2,
  })  : _dictionary = dictionary,
        _random = random ?? Random();

  final DictionaryService _dictionary;
  final Random _random;
  final int levelId;

  List<DictionaryEntry> get eligiblePool => _dictionary
      .entriesForLevel(levelId)
      .where((e) => e.hasSyllableBreakdown)
      .toList();

  DictionaryEntry pickNext() {
    final pool = eligiblePool;
    if (pool.isEmpty) {
      throw StateError('No multi-syllable words for syllable builder');
    }

    final recent = SyllableBuilderSessionStore.loadRecentEntryIds().toSet();
    var candidates = pool.where((e) => !recent.contains(e.id)).toList();

    if (candidates.isEmpty) {
      // Весь пул пройден — начинаем круг заново, но не то же слово подряд.
      final lastId = SyllableBuilderSessionStore.loadLastEntryId();
      candidates = pool.where((e) => e.id != lastId).toList();
      if (candidates.isEmpty) candidates = pool;
    }

    candidates.shuffle(_random);
    return candidates.first;
  }

  int get poolSize => eligiblePool.length;

  /// Пока в «недавних» все слова кроме одного — повторов не будет.
  int get recentCap => poolSize > 1 ? poolSize - 1 : 1;
}
