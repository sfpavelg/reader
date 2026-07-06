import '../../models/dictionary/dictionary_entry.dart';

/// Уровни сложности тренажёра «Слоги».
abstract final class SyllableBuilderLevel {
  static const level1 = 1;
  static const level2 = 2;
  static const level3 = 3;

  static const all = [level1, level2, level3];

  static String label(int levelId) {
    switch (levelId) {
      case level2:
        return 'Уровень 2';
      case level3:
        return 'Уровень 3';
      default:
        return 'Уровень 1';
    }
  }

  static bool isSimpleTwoSyllableWord(List<String> syllables) =>
      syllables.length == 2 && syllables.every((s) => s.length == 2);

  static bool isEligibleEntry(DictionaryEntry entry, int trainerLevelId) {
    if (!entry.hasSyllableBreakdown) return false;
    final syllables = entry.syllables;
    switch (trainerLevelId) {
      case level1:
        if (syllables.length > 2) return false;
        return syllables.every((s) => s.length <= 2);
      case level2:
        if (syllables.length < 2) return false;
        if (!syllables.every((s) => s.length <= 2)) return false;
        return !isSimpleTwoSyllableWord(syllables);
      case level3:
        return !isSimpleTwoSyllableWord(syllables);
      default:
        return false;
    }
  }
}
