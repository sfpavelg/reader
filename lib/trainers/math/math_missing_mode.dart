/// Режим тренажёра «Найди число».
enum MathMissingMode {
  /// Пропущенное слагаемое: 2 + ? = 7.
  addition,

  /// Пропущенное вычитаемое: 7 − ? = 4.
  subtraction,
}

extension MathMissingModeX on MathMissingMode {
  String get label => switch (this) {
        MathMissingMode.addition => 'Сложение',
        MathMissingMode.subtraction => 'Вычитание',
      };
}
