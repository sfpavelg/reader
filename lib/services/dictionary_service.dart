import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import '../models/dictionary/dictionary_entry.dart';
import '../models/dictionary/dictionary_level.dart';
import '../models/dictionary/dictionary_manifest.dart';

/// Загрузка и выборка из вшитого JSON-словаря (строго офлайн).
class DictionaryService {
  DictionaryService({Random? random}) : _random = random ?? Random();

  static const _manifestPath = 'assets/dictionary/manifest.json';
  static const _levelPathPrefix = 'assets/dictionary/';

  final Random _random;

  DictionaryManifest? _manifest;
  final Map<int, DictionaryLevel> _levelsById = {};

  DictionaryManifest get manifest {
    final m = _manifest;
    if (m == null) {
      throw StateError('DictionaryService.initialize() must be called first');
    }
    return m;
  }

  Future<void> initialize() async {
    if (_manifest != null) return;

    final raw = await rootBundle.loadString(_manifestPath);
    _manifest = DictionaryManifest.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );

    for (final ref in _manifest!.levels) {
      final levelRaw = await rootBundle.loadString('$_levelPathPrefix${ref.file}');
      final level = DictionaryLevel.fromJson(
        jsonDecode(levelRaw) as Map<String, dynamic>,
      );
      _levelsById[level.level] = level;
    }
  }

  DictionaryLevel level(int id) {
    final level = _levelsById[id];
    if (level == null) {
      throw ArgumentError('Dictionary level $id is not loaded');
    }
    return level;
  }

  List<DictionaryEntry> entriesForLevel(
    int levelId, {
    int? maxDifficulty,
  }) {
    final entries = level(levelId).entries;
    if (maxDifficulty == null) return List.unmodifiable(entries);
    return entries.where((e) => e.difficulty <= maxDifficulty).toList();
  }

  DictionaryEntry? pickRandom({
    required int levelId,
    int? maxDifficulty,
    Set<String> excludeIds = const {},
  }) {
    final pool = entriesForLevel(levelId, maxDifficulty: maxDifficulty)
        .where((e) => !excludeIds.contains(e.id))
        .toList();
    if (pool.isEmpty) return null;
    return pool[_random.nextInt(pool.length)];
  }

  List<DictionaryEntry> pickDistinct({
    required int levelId,
    required int count,
    int? maxDifficulty,
    Set<String> excludeIds = const {},
  }) {
    final pool = entriesForLevel(levelId, maxDifficulty: maxDifficulty)
        .where((e) => !excludeIds.contains(e.id))
        .toList()
      ..shuffle(_random);

    if (pool.length < count) {
      throw StateError(
        'Not enough dictionary entries for level $levelId (need $count, have ${pool.length})',
      );
    }
    return pool.take(count).toList();
  }
}
