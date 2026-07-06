import '../../models/dictionary/dictionary_entry.dart';
import '../../services/dictionary_service.dart';
import 'schulte_spellable_words.dart';

/// Полный индекс слов для сетки: словарь + доп. список.
abstract final class SchulteWordIndex {
  static List<SchulteSpellableWord> build(DictionaryService dictionary) {
    final byText = <String, SchulteSpellableWord>{};

    void put({
      required String entryId,
      required String text,
      required List<String> syllables,
    }) {
      if (!SchulteSpellableWords.usesGridSyllablesOnly(syllables)) return;
      byText[text] = SchulteSpellableWord(
        entryId: entryId,
        text: text,
        syllables: List<String>.from(syllables),
      );
    }

    for (final entry in dictionary.entriesForLevel(2)) {
      if (entry.syllables.length < 2) continue;
      put(entryId: entry.id, text: entry.text, syllables: entry.syllables);
    }

    for (final entry in dictionary.entriesForLevel(1)) {
      if (entry.text.length != 2) continue;
      put(entryId: entry.id, text: entry.text, syllables: [entry.text]);
    }

    final sorted = byText.values.toList()
      ..sort((a, b) => a.text.compareTo(b.text));
    return sorted;
  }
}
