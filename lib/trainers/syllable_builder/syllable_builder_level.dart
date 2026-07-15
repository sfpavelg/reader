import 'dart:math';

import '../../models/dictionary/dictionary_entry.dart';

/// Уровни сложности тренажёра «Ловец».
abstract final class SyllableBuilderLevel {
  static const level1 = 1;
  static const level2 = 2;
  static const level3 = 3;

  static const all = [level1, level2, level3];

  static String label(int levelId) {
    switch (levelId) {
      case level2:
        return 'Средний';
      case level3:
        return 'Сложный';
      default:
        return 'Простой';
    }
  }

  static bool isSimpleTwoSyllableWord(List<String> syllables) =>
      syllables.length == 2 && syllables.every((s) => s.length == 2);

  static int distractorCount(int targetSyllableCount, int trainerLevelId) {
    switch (trainerLevelId) {
      case level3:
        return targetSyllableCount + 6;
      case level2:
        return targetSyllableCount + 4;
      default:
        return max(2, targetSyllableCount);
    }
  }

  /// Простой и средний — только простые слоги (до 2 букв); сложный — любые.
  static bool isDistractorSyllableAllowed(String syllable, int trainerLevelId) {
    if (syllable.isEmpty) return false;
    switch (trainerLevelId) {
      case level1:
        return syllable.length == 2;
      case level2:
        return syllable.length <= 2;
      default:
        return true;
    }
  }

  static bool isEligibleEntry(DictionaryEntry entry, int trainerLevelId) {
    if (!entry.hasSyllableBreakdown) return false;
    final syllables = entry.syllables;
    switch (trainerLevelId) {
      case level1:
        if (syllables.length > 2) return false;
        return syllables.every((s) => s.length == 2);
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
