import 'dart:math';

import '../../models/dictionary/dictionary_entry.dart';
import '../../services/dictionary_service.dart';
import 'tachistoscope_session_state.dart';
import 'tachistoscope_task.dart';

/// Генерация заданий тахистоскопа из общего словаря.
class TachistoscopeGenerator {
  TachistoscopeGenerator({
    required DictionaryService dictionary,
    Random? random,
  })  : _dictionary = dictionary,
        _random = random ?? Random();

  final DictionaryService _dictionary;
  final Random _random;

  static const int optionCount = 3;

  TachistoscopeTask generate({
    required int levelId,
    required TachistoscopeSessionState session,
    int? maxDifficulty,
    Set<String> recentTargetIds = const {},
  }) {
    final target = _pickTarget(
      levelId: levelId,
      maxDifficulty: maxDifficulty,
      recentTargetIds: recentTargetIds,
    );

    final distractors = _pickDistractors(
      levelId: levelId,
      target: target,
      maxDifficulty: maxDifficulty,
      count: optionCount - 1,
    );

    final options = _buildOptions(target: target, distractors: distractors);
    final shuffled = List<TachistoscopeOption>.from(options)..shuffle(_random);
    final correctIndex = shuffled.indexWhere((o) => o.entryId == target.id);

    return TachistoscopeTask(
      taskId: '${target.id}_${DateTime.now().microsecondsSinceEpoch}',
      levelId: levelId,
      target: target,
      options: shuffled,
      correctIndex: correctIndex,
      flashDuration: session.flashDuration,
    );
  }

  DictionaryEntry _pickTarget({
    required int levelId,
    int? maxDifficulty,
    required Set<String> recentTargetIds,
  }) {
    final withoutRecent = _dictionary.pickRandom(
      levelId: levelId,
      maxDifficulty: maxDifficulty,
      excludeIds: recentTargetIds,
    );
    if (withoutRecent != null) return withoutRecent;

    final fallback = _dictionary.pickRandom(
      levelId: levelId,
      maxDifficulty: maxDifficulty,
    );
    if (fallback == null) {
      throw StateError('Dictionary level $levelId has no entries');
    }
    return fallback;
  }

  List<DictionaryEntry> _pickDistractors({
    required int levelId,
    required DictionaryEntry target,
    int? maxDifficulty,
    required int count,
  }) {
    final pool = _dictionary
        .entriesForLevel(levelId, maxDifficulty: maxDifficulty)
        .where((e) => e.id != target.id)
        .toList();

    pool.sort((a, b) {
      final da = (a.difficulty - target.difficulty).abs();
      final db = (b.difficulty - target.difficulty).abs();
      if (da != db) return da.compareTo(db);
      final la = (a.text.length - target.text.length).abs();
      final lb = (b.text.length - target.text.length).abs();
      return la.compareTo(lb);
    });

    final similar = pool.take(max(pool.length ~/ 2, count * 2)).toList()
      ..shuffle(_random);

    if (similar.length < count) {
      throw StateError(
        'Not enough distractors for tachistoscope at level $levelId',
      );
    }

    return similar.take(count).toList();
  }

  List<TachistoscopeOption> _buildOptions({
    required DictionaryEntry target,
    required List<DictionaryEntry> distractors,
  }) {
    TachistoscopeOption toOption(DictionaryEntry entry) {
      if (entry.imageAsset != null && entry.imageAsset!.isNotEmpty) {
        return TachistoscopeOption(
          entryId: entry.id,
          label: entry.text,
          kind: TachistoscopeOptionKind.image,
          imageAsset: entry.imageAsset,
        );
      }
      return TachistoscopeOption(
        entryId: entry.id,
        label: entry.text,
        kind: TachistoscopeOptionKind.text,
      );
    }

    return [toOption(target), ...distractors.map(toOption)];
  }
}
