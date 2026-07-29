/// Уровни сложности «Собирайка».
enum SchulteDifficulty {
  easy(1, 'Простой', cols: 4, rows: 3, cellCount: 12, maxSpareSyllables: 2),
  medium(2, 'Средний', cols: 6, rows: 4, cellCount: 24, maxSpareSyllables: 3),
  hard(3, 'Сложный', cols: 8, rows: 6, cellCount: 48, maxSpareSyllables: 5);

  const SchulteDifficulty(
    this.id,
    this.label, {
    required this.cols,
    required this.rows,
    required this.cellCount,
    required this.maxSpareSyllables,
  });

  final int id;
  final String label;
  final int cols;
  final int rows;
  final int cellCount;
  final int maxSpareSyllables;

  String get menuLabel => '$label — $cellCount слогов';

  /// Крупнее на простом поле, компактнее на сложном.
  double get syllableFontScale => switch (this) {
        SchulteDifficulty.easy => 0.34,
        SchulteDifficulty.medium => 0.28,
        SchulteDifficulty.hard => 0.24,
      };

  double get cellMinScale => switch (this) {
        SchulteDifficulty.easy => 0.7,
        SchulteDifficulty.medium => 0.55,
        SchulteDifficulty.hard => 0.4,
      };

  double get cellMaxSize => switch (this) {
        SchulteDifficulty.easy => 110,
        SchulteDifficulty.medium => 96,
        SchulteDifficulty.hard => 72,
      };

  static SchulteDifficulty byId(int id) {
    for (final level in values) {
      if (level.id == id) return level;
    }
    return easy;
  }
}
