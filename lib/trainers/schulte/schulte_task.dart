import 'schulte_spellable_words.dart';

class SchulteCell {
  const SchulteCell({
    required this.gridIndex,
    required this.text,
  });

  final int gridIndex;
  final String text;
}

/// Сетка слогов: собери слово из ячеек.
class SchulteTask {
  const SchulteTask({
    required this.taskId,
    required this.entryId,
    required this.word,
    required this.syllables,
    required this.gridSize,
    required this.cells,
    required this.spellableWords,
  });

  final String taskId;
  final String entryId;
  final String word;
  final List<String> syllables;
  final int gridSize;
  final List<SchulteCell> cells;
  final List<SchulteSpellableWord> spellableWords;

  int get cellCount => gridSize * gridSize;
  int get syllableCount => syllables.length;

  SchulteCell? cellAt(int gridIndex) {
    for (final c in cells) {
      if (c.gridIndex == gridIndex) return c;
    }
    return null;
  }

  List<String> get gridSyllables => cells.map((c) => c.text).toList();

  SchulteSpellableWord? matchPicked(List<String> picked) =>
      SchulteSpellableWords.matchPicked(spellableWords, picked);
}
