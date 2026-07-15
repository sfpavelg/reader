/// Уровни сложности «Угадайка».
enum UgadaykaDifficulty {
  easy(1, 'Простой', cols: 3, rows: 4, cardCount: 12),
  medium(2, 'Средний', cols: 4, rows: 6, cardCount: 24),
  hard(3, 'Сложный', cols: 6, rows: 8, cardCount: 48);

  const UgadaykaDifficulty(
    this.id,
    this.label, {
    required this.cols,
    required this.rows,
    required this.cardCount,
  });

  final int id;
  final String label;
  final int cols;
  final int rows;
  final int cardCount;

  int get pairCount => cardCount ~/ 2;

  /// Крупнее на простом поле, компактнее на сложном.
  double get syllableFontScale {
    switch (this) {
      case UgadaykaDifficulty.easy:
        return 0.44;
      case UgadaykaDifficulty.medium:
        return 0.38;
      case UgadaykaDifficulty.hard:
        return 0.34;
    }
  }

  static UgadaykaDifficulty byId(int id) {
    for (final level in values) {
      if (level.id == id) return level;
    }
    return easy;
  }
}
