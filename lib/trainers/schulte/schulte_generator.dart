import 'dart:math';

import '../../models/dictionary/dictionary_entry.dart';
import '../../services/dictionary_service.dart';
import 'schulte_task.dart';

class SchulteGenerator {
  SchulteGenerator({
    required DictionaryService dictionary,
    Random? random,
  })  : _dictionary = dictionary,
        _random = random ?? Random();

  final DictionaryService _dictionary;
  final Random _random;

  SchulteTask generate({
    required int levelId,
    int gridSize = 3,
    SchulteOrderMode orderMode = SchulteOrderMode.alphabetical,
    int? maxDifficulty,
  }) {
    assert(gridSize == 3 || gridSize == 4);
    final count = gridSize * gridSize;

    final entries = _dictionary.pickDistinct(
      levelId: levelId,
      count: count,
      maxDifficulty: maxDifficulty,
    );

    final ordered = List<DictionaryEntry>.from(entries)
      ..sort((a, b) => _compareEntries(a, b, orderMode));

    final positions = List.generate(count, (i) => i)..shuffle(_random);

    final cells = <SchulteCell>[];
    for (var rank = 0; rank < count; rank++) {
      final entry = ordered[rank];
      cells.add(
        SchulteCell(
          gridIndex: positions[rank],
          entryId: entry.id,
          text: entry.text,
          orderRank: rank,
        ),
      );
    }

    cells.sort((a, b) => a.gridIndex.compareTo(b.gridIndex));

    return SchulteTask(
      taskId: 'schulte_${DateTime.now().microsecondsSinceEpoch}',
      levelId: levelId,
      gridSize: gridSize,
      orderMode: orderMode,
      cells: cells,
    );
  }

  int _compareEntries(
    DictionaryEntry a,
    DictionaryEntry b,
    SchulteOrderMode mode,
  ) {
    switch (mode) {
      case SchulteOrderMode.alphabetical:
        final textCmp = a.text.compareTo(b.text);
        if (textCmp != 0) return textCmp;
        return a.difficulty.compareTo(b.difficulty);
      case SchulteOrderMode.difficulty:
        final diff = a.difficulty.compareTo(b.difficulty);
        if (diff != 0) return diff;
        return a.text.compareTo(b.text);
    }
  }
}
