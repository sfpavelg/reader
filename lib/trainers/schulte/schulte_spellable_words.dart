import '../../models/dictionary/dictionary_entry.dart';
import '../../services/dictionary_service.dart';
import 'schulte_word_index.dart';

/// Слово, которое можно собрать из слогов текущей сетки.
class SchulteSpellableWord {
  const SchulteSpellableWord({
    required this.entryId,
    required this.text,
    required this.syllables,
  });

  final String entryId;
  final String text;
  final List<String> syllables;
}

/// Поиск всех слов словаря, набираемых из слогов сетки (каждая ячейка — не больше одного раза).
abstract final class SchulteSpellableWords {
  static bool usesGridSyllablesOnly(List<String> syllables) =>
      syllables.isNotEmpty && syllables.every((s) => s.length == 2);

  /// Можно ли набрать [wordSyllables] по порядку из ячеек [gridSyllables].
  static bool canSpell(List<String> gridSyllables, List<String> wordSyllables) {
    if (wordSyllables.isEmpty) return false;
    final used = List<bool>.filled(gridSyllables.length, false);

    bool dfs(int syllableIndex) {
      if (syllableIndex >= wordSyllables.length) return true;
      final need = wordSyllables[syllableIndex];
      for (var i = 0; i < gridSyllables.length; i++) {
        if (used[i] || gridSyllables[i] != need) continue;
        used[i] = true;
        if (dfs(syllableIndex + 1)) return true;
        used[i] = false;
      }
      return false;
    }

    return dfs(0);
  }

  static List<SchulteSpellableWord> findForGrid({
    required DictionaryService dictionary,
    required List<String> gridSyllables,
  }) {
    final results = <SchulteSpellableWord>[];
    final seen = <String>{};

    void tryAdd(SchulteSpellableWord word) {
      if (!canSpell(gridSyllables, word.syllables)) return;
      if (!seen.add(word.text)) return;
      results.add(word);
    }

    // Каждое слово из полного индекса, которое набирается на этой сетке.
    for (final word in SchulteWordIndex.build(dictionary)) {
      tryAdd(word);
    }

    // Любой слог на сетке — отдельное «слово».
    for (final syllable in gridSyllables.toSet()) {
      tryAdd(
        SchulteSpellableWord(
          entryId: 'grid_$syllable',
          text: syllable,
          syllables: [syllable],
        ),
      );
    }

    results.sort((a, b) => a.text.compareTo(b.text));
    return results;
  }

  static SchulteSpellableWord? matchPicked(
    List<SchulteSpellableWord> spellableWords,
    List<String> picked,
  ) {
    if (picked.isEmpty) return null;
    for (final word in spellableWords) {
      if (picked.length != word.syllables.length) continue;
      var ok = true;
      for (var i = 0; i < picked.length; i++) {
        if (picked[i] != word.syllables[i]) {
          ok = false;
          break;
        }
      }
      if (ok) return word;
    }
    return null;
  }
}
