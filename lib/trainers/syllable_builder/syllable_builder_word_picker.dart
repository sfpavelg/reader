import 'dart:math';

import '../../models/dictionary/dictionary_entry.dart';
import '../../services/dictionary_service.dart';
import 'syllable_builder_level.dart';
import 'syllable_builder_session_store.dart';

/// Выбор следующего слова: без повтора, пока не пройден весь пул уровня.
class SyllableBuilderWordPicker {
  SyllableBuilderWordPicker({
    required DictionaryService dictionary,
    Random? random,
    int trainerLevelId = SyllableBuilderLevel.level1,
  })  : _dictionary = dictionary,
        _random = random ?? Random(),
        _trainerLevelId = trainerLevelId;

  static const _dictionaryLevelId = 2;

  final DictionaryService _dictionary;
  final Random _random;
  int _trainerLevelId;

  int get trainerLevelId => _trainerLevelId;

  set trainerLevelId(int value) {
    _trainerLevelId = value;
  }

  List<DictionaryEntry> get eligiblePool => _dictionary
      .entriesForLevel(_dictionaryLevelId)
      .where((e) => SyllableBuilderLevel.isEligibleEntry(e, _trainerLevelId))
      .toList();

  DictionaryEntry pickNext() {
    final pool = eligiblePool;
    if (pool.isEmpty) {
      throw StateError(
        'No words for syllable builder level $_trainerLevelId',
      );
    }

    final recent =
        SyllableBuilderSessionStore.loadRecentEntryIds(_trainerLevelId).toSet();
    var candidates = pool.where((e) => !recent.contains(e.id)).toList();

    if (candidates.isEmpty) {
      final lastId =
          SyllableBuilderSessionStore.loadLastEntryId(_trainerLevelId);
      candidates = pool.where((e) => e.id != lastId).toList();
      if (candidates.isEmpty) candidates = pool;
    }

    candidates.shuffle(_random);
    return candidates.first;
  }

  int get poolSize => eligiblePool.length;

  int get recentCap => poolSize > 1 ? poolSize - 1 : 1;
}
