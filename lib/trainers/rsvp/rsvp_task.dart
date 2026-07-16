import '../schulte/schulte_spellable_words.dart';

/// Задание «Бегущая строка»: поймать слоги из потока и собрать слово.
class RsvpTask {
  const RsvpTask({
    required this.taskId,
    required this.entryId,
    required this.word,
    required this.syllables,
    required this.streamSyllables,
    required this.spellableWords,
  });

  final String taskId;
  final String entryId;
  final String word;
  final List<String> syllables;
  final List<String> streamSyllables;
  final List<SchulteSpellableWord> spellableWords;

  int get streamLength => streamSyllables.length;

  SchulteSpellableWord? matchPicked(List<String> picked) =>
      SchulteSpellableWords.matchPicked(spellableWords, picked);

  /// Сколько ещё слов можно собрать из потока (без слова-подсказки).
  int remainingSpellableCount(Set<String> collectedWords) {
    return spellableWords
        .where((w) => SchulteSpellableWords.isMultiSyllableWord(w.syllables))
        .where((w) => w.text != word)
        .where((w) => !collectedWords.contains(w.text))
        .length;
  }
}
