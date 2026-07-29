import '../../services/dictionary_service.dart';
import 'schulte_spellable_words.dart';

class SchulteCell {
  const SchulteCell({
    required this.gridIndex,
    this.text,
  });

  final int gridIndex;

  /// `null` — слог уже собран и убран с поля.
  final String? text;

  bool get isEmpty => text == null;
}

/// Сетка слогов: собери слова из ячеек.
class SchulteTask {
  const SchulteTask({
    required this.taskId,
    required this.entryId,
    required this.word,
    required this.syllables,
    required this.packedEntryIds,
    required this.packedWords,
    required this.cols,
    required this.rows,
    required this.cells,
    required this.spellableWords,
  });

  static const defaultCols = 6;
  static const defaultRows = 4;

  final String taskId;

  /// Первое упакованное слово (для истории сессии).
  final String entryId;
  final String word;
  final List<String> syllables;

  final List<String> packedEntryIds;
  final List<String> packedWords;

  final int cols;
  final int rows;
  final List<SchulteCell> cells;
  final List<SchulteSpellableWord> spellableWords;

  int get cellCount => cols * rows;

  /// Совместимость со старым квадратным API.
  int get gridSize => cols;

  int get syllableCount => syllables.length;

  int get filledCellCount => cells.where((c) => !c.isEmpty).length;

  SchulteCell? cellAt(int gridIndex) {
    for (final c in cells) {
      if (c.gridIndex == gridIndex) return c;
    }
    return null;
  }

  List<String> get gridSyllables => [
        for (final c in cells)
          if (c.text != null) c.text!,
      ];

  SchulteSpellableWord? matchPicked(List<String> picked) =>
      SchulteSpellableWords.matchPicked(spellableWords, picked);

  /// Сколько *запланированных* слов ещё можно собрать из оставшихся слогов.
  int remainingSpellableCount([Set<String>? collectedWords]) {
    return remainingPlannedWords(collectedWords).length;
  }

  /// Запланированные слова (из упаковки), которые ещё собираются на поле.
  List<SchulteSpellableWord> remainingPlannedWords([
    Set<String>? collectedWords,
  ]) {
    final collected = collectedWords ?? const <String>{};
    final planned = packedWords.toSet();
    return [
      for (final w in spellableWords)
        if (planned.contains(w.text) &&
            !collected.contains(w.text) &&
            SchulteSpellableWords.isMultiSyllableWord(w.syllables))
          w,
    ];
  }

  List<SchulteSpellableWord> remainingSpellableWords([
    Set<String>? collectedWords,
  ]) =>
      remainingPlannedWords(collectedWords);

  /// Длина слога → сколько таких запланированных слов ещё можно собрать.
  Map<int, int> remainingCombinations([Set<String>? collectedWords]) {
    final counts = <int, int>{};
    for (final w in remainingPlannedWords(collectedWords)) {
      final len = w.syllables.length;
      counts[len] = (counts[len] ?? 0) + 1;
    }
    return counts;
  }

  /// Например: «2 слова из 3 слогов и 1 из 2».
  String remainingCombinationsLabel([Set<String>? collectedWords]) {
    final counts = remainingCombinations(collectedWords);
    if (counts.isEmpty) return '';

    final lengths = counts.keys.toList()..sort((a, b) => b.compareTo(a));
    final parts = <String>[];
    for (var i = 0; i < lengths.length; i++) {
      final len = lengths[i];
      final n = counts[len]!;
      if (i == 0) {
        parts.add(
          '${_countPhrase(n)} из $len ${_syllableForm(len)}',
        );
      } else {
        parts.add('$n из $len');
      }
    }

    if (parts.length == 1) return parts.first;
    if (parts.length == 2) return '${parts[0]} и ${parts[1]}';
    final head = parts.sublist(0, parts.length - 1).join(', ');
    return '$head и ${parts.last}';
  }

  /// Убирает использованные ячейки и пересчитывает доступные слова.
  SchulteTask withoutUsedCells({
    required Set<int> usedGridIndices,
    required DictionaryService dictionary,
    Set<String>? collectedWords,
  }) {
    final nextCells = [
      for (final c in cells)
        usedGridIndices.contains(c.gridIndex)
            ? SchulteCell(gridIndex: c.gridIndex)
            : c,
    ];
    final remaining = [
      for (final c in nextCells)
        if (c.text != null) c.text!,
    ];
    final nextSpellable = SchulteSpellableWords.findForGrid(
      dictionary: dictionary,
      gridSyllables: remaining,
    );
    final collected = collectedWords ?? const <String>{};
    final filtered = [
      for (final w in nextSpellable)
        if (!collected.contains(w.text)) w,
    ];

    return SchulteTask(
      taskId: taskId,
      entryId: entryId,
      word: word,
      syllables: syllables,
      packedEntryIds: packedEntryIds,
      packedWords: packedWords,
      cols: cols,
      rows: rows,
      cells: nextCells,
      spellableWords: filtered,
    );
  }

  static String _countPhrase(int n) {
    final form = switch (n % 100) {
      >= 11 && <= 14 => 'слов',
      _ => switch (n % 10) {
          1 => 'слово',
          >= 2 && <= 4 => 'слова',
          _ => 'слов',
        },
    };
    return '$n $form';
  }

  static String _syllableForm(int n) {
    return switch (n % 100) {
      >= 11 && <= 14 => 'слогов',
      _ => switch (n % 10) {
          1 => 'слога',
          >= 2 && <= 4 => 'слогов',
          _ => 'слогов',
        },
    };
  }
}
