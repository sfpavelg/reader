import 'dart:math';

import '../../models/dictionary/dictionary_entry.dart';
import '../../services/dictionary_service.dart';
import 'schulte_session_store.dart';

/// Слова из двухбуквенных слогов, без повтора, пока не пройден весь пул.
typedef _RecentEntryIdsLoader = List<String> Function();
typedef _LastEntryIdLoader = String? Function();

class SchulteWordPicker {
  SchulteWordPicker({
    required DictionaryService dictionary,
    Random? random,
    this.levelId = 2,
    this.maxSyllables = 9,
    List<String> Function()? loadRecentEntryIds,
    String? Function()? loadLastEntryId,
  })  : _dictionary = dictionary,
        _random = random ?? Random(),
        _loadRecentEntryIds =
            loadRecentEntryIds ?? SchulteSessionStore.loadRecentEntryIds,
        _loadLastEntryId = loadLastEntryId ?? SchulteSessionStore.loadLastEntryId;

  final DictionaryService _dictionary;
  final Random _random;
  final int levelId;
  final int maxSyllables;
  final _RecentEntryIdsLoader _loadRecentEntryIds;
  final _LastEntryIdLoader _loadLastEntryId;

  static bool isEligibleEntry(DictionaryEntry entry, {int maxSyllables = 9}) {
    if (!entry.hasSyllableBreakdown) return false;
    if (entry.syllables.length > maxSyllables) return false;
    return entry.syllables.every((s) => s.length == 2);
  }

  List<DictionaryEntry> get eligiblePool => _dictionary
      .entriesForLevel(levelId)
      .where((e) => isEligibleEntry(e, maxSyllables: maxSyllables))
      .toList();

  DictionaryEntry pickNext() {
    final pool = eligiblePool;
    if (pool.isEmpty) {
      throw StateError('No two-letter-syllable words for Schulte');
    }

    final recent = _loadRecentEntryIds().toSet();
    var candidates = pool.where((e) => !recent.contains(e.id)).toList();

    if (candidates.isEmpty) {
      final lastId = _loadLastEntryId();
      candidates = pool.where((e) => e.id != lastId).toList();
      if (candidates.isEmpty) candidates = pool;
    }

    candidates.shuffle(_random);
    return candidates.first;
  }

  int get poolSize => eligiblePool.length;

  int get recentCap => poolSize > 1 ? poolSize - 1 : 1;
}
